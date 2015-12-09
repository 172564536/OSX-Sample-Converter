//
//  AudioFileConversionController.m
//  mpc-audio
//
//  Created by Carl  on 06/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import "AudioFileConversionController.h"
#import "AudioFileReaderWriter.h"
#import "MpcFileNameGenerator.h"
#import "FileOperations.h"
#import "ExportConfig.h"

@interface AudioFileConversionController () <AudioFileReaderWriterDelegate>

@property (nonatomic, strong) AudioFileReaderWriter *readerWriter;
@property (nonatomic, strong) NSMutableArray *audioFileUrls;
@property (nonatomic, strong) ExportConfig *exportConfig;

@property (nonatomic, strong) NSURL *currentExportUrl;
@property (nonatomic, strong) NSURL *destintionFolderUrl;

@property NSInteger fileConversionCounter;
@property NSInteger readWriteFailures;
@property NSInteger sameLocationFailures;

@end

@implementation AudioFileConversionController

#pragma mark -
#pragma mark - Initialisation

-(instancetype)init
{
    [NSException raise:@"** Invalid State **" format:@"Call 'initWithAudioFileUrls' instead"];
    return nil;
}

-(instancetype)initWithAudioFileUrls:(NSArray *)audioFileUrls DestinationFolder:(NSURL *)destinationFolder andExportOptionsConfig:(ExportConfig *)exportConfig
{
    self = [super init];
    
    if (self) {
        [self initializeReaderWriter];
        self.destintionFolderUrl = destinationFolder;
        self.audioFileUrls = [[NSMutableArray alloc]initWithArray:audioFileUrls copyItems:YES];
        self.exportConfig = exportConfig;
    }
    return self;
}

-(void)initializeReaderWriter
{
    self.readerWriter = nil;
    self.readerWriter.delegate = nil;
    self.readerWriter = [[AudioFileReaderWriter alloc]init];
    self.readerWriter.delegate = self;
}

#pragma mark -
#pragma mark - Conversion

-(void)start
{
    self.fileConversionCounter = 0;
    [self checkForRemainingItemsToProcess];
}

-(void)checkForRemainingItemsToProcess
{
    if (self.audioFileUrls.count > 0) {
        [self.delegate audioFileConversionControllerDidReportProgress];
        
        self.currentExportUrl = [self.audioFileUrls objectAtIndex:0];
        [self.audioFileUrls removeObjectAtIndex:0];
        [self processItemForUrl:self.currentExportUrl];
    } else {
        [self.delegate audioFileConversionControllerDidFinishWithReport:[self generateReport]];
    }
}

-(void)processItemForUrl:(NSURL*)inputFileUrl
{
    NSString *inpultFileName = [inputFileUrl lastPathComponent];
    NSString *newFileName    = [MpcFileNameGenerator createNewFileNameFromExistingFileName:inpultFileName withExportConfig:self.exportConfig fileNumber:self.fileConversionCounter];
    NSURL *outputFileUrl     = [NSURL URLWithString:newFileName relativeToURL:self.destintionFolderUrl];
    
    if ([inputFileUrl.path isEqualToString:outputFileUrl.path]) {
        self.sameLocationFailures ++;
        [self checkForRemainingItemsToProcess];
    } else if ([FileOperations fileExistsAtUrl:outputFileUrl]) {
        [self checkForRemainingItemsToProcess];
    } else {
        [self.readerWriter convertAudioFileFromInputUrl:inputFileUrl toOutputUrl:outputFileUrl];
    }
}

-(NSString*)generateReport
{
    NSMutableString *report = [[NSMutableString alloc]init];
    [report appendString:[NSString stringWithFormat:@"Files converted: %ld\n", (long)self.fileConversionCounter]];
    if (self.readWriteFailures > 0) {
        [report appendString:@"---------------------\n"];
        [report appendString:[NSString stringWithFormat:@"Files failed to process: %ld\n(see help for more info)\n", (long)self.readWriteFailures]];
    }
    if (self.sameLocationFailures > 0) {
        [report appendString:@"---------------------\n"];
        [report appendString:[NSString stringWithFormat:@"Files failed due to input/out files having same name and location: %ld\n(see help for more info)\n", (long)self.sameLocationFailures]];
    }
    return [report copy];
}

#pragma mark -
#pragma mark - AudioFileReaderWriterDelegate

-(void)audioFileReaderWriterDidCompleteWithSuccess
{
    self.fileConversionCounter ++;
    [self checkForRemainingItemsToProcess];
}

-(void)audioFileReaderWriterDidFail
{
    self.readWriteFailures ++;
    [self initializeReaderWriter];
    [FileOperations deleteFileIfExists:self.currentExportUrl];
    [self checkForRemainingItemsToProcess];
}

@end
