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

NSString * const FILE_CLASH_BUTTON_TITLE_ABORT               = @"Abort";
NSString * const FILE_CLASH_BUTTON_TITLE_SKIP                = @"Skip";
NSString * const FILE_CLASH_BUTTON_TITLE_SKIP_APPLY_TO_ALL   = @"Skip (apply all)";
NSString * const FILE_CLASH_BUTTON_TITLE_DELETE              = @"Delete";
NSString * const FILE_CLASH_BUTTON_TITLE_DELETE_APPLY_TO_ALL = @"Delete (apply all)";

@interface AudioFileConversionController () <AudioFileReaderWriterDelegate>

@property (nonatomic, strong) AudioFileReaderWriter *readerWriter;
@property (nonatomic, strong) NSMutableArray *audioFileUrls;
@property (nonatomic, strong) ExportConfig *exportConfig;

@property (nonatomic, strong) NSURL *currentExportUrl;
@property (nonatomic, strong) NSURL *destintionFolderUrl;

@property NSInteger fileConversionCounter;
@property NSInteger readWriteFailures;
@property NSInteger sameLocationFailures;

@property BOOL applySkipToAll;
@property BOOL applyDeleteToAll;

@end

@implementation AudioFileConversionController

#pragma mark -
#pragma mark - Initialisation

-(instancetype)init
{
    [NSException raise:@"** Invalid State **" format:@"Call 'initWithAudioFileUrls' instead"];
    return nil;
}

-(instancetype)initWithAudioFileUrls:(NSArray *)audioFileUrls
                   DestinationFolder:(NSURL *)destinationFolder
              andExportOptionsConfig:(ExportConfig *)exportConfig
{
    self = [super init];
    
    if (self) {
        [self initializeReaderWriter];
        self.destintionFolderUrl = destinationFolder;
        self.audioFileUrls = [[NSMutableArray alloc]initWithArray:audioFileUrls copyItems:YES];
        self.exportConfig = exportConfig;
        self.applyDeleteToAll = NO;
        self.applySkipToAll = NO;
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
        // File has same location - cant read and write from same file at once
        self.sameLocationFailures ++;
        [self checkForRemainingItemsToProcess];
        
    } else if ([FileOperations fileExistsAtUrl:outputFileUrl]) {
        // File Exists we need to deal with it
        if (!self.applySkipToAll && !self.applyDeleteToAll) {
            FileClashDecision decision = [self.delegate audioFileConversionControllerDidEncounterFileClashForFile:outputFileUrl.path];
            [self resolveFileClashDecision:decision relatingToFilesAtInputUrl:inputFileUrl andOutputUrl:outputFileUrl];
        } else {
            if (self.applyDeleteToAll) {
                [FileOperations deleteFileIfExists:outputFileUrl];
                [self convertFileFromInputUrl:inputFileUrl toOutputUrl:outputFileUrl];
            } else if (self.applySkipToAll){
                [self checkForRemainingItemsToProcess];
            } else {
                [NSException raise:@"** unhandled situation **" format:@"processItemForUrl in AudioFileConversionController"];
            }
        }
    } else {
        // No issues - proceed captain
        [self convertFileFromInputUrl:inputFileUrl toOutputUrl:outputFileUrl];
    }
}

-(void)convertFileFromInputUrl:(NSURL *)inputFileUrl toOutputUrl:(NSURL *)outputFileUrl
{
    BOOL convertAudioFile = self.exportConfig.convertSamples.boolValue;
    
    if (convertAudioFile) {
        [self.readerWriter convertAudioFileFromInputUrl:inputFileUrl toOutputUrl:outputFileUrl];
    } else {
        BOOL success = [FileOperations copyItemFromURL:inputFileUrl toUrl:outputFileUrl];
        if (success) {
            self.fileConversionCounter ++;
        } else {
            self.readWriteFailures ++;
        }
        
        [self checkForRemainingItemsToProcess];
    }
}

-(void)resolveFileClashDecision:(FileClashDecision)decision relatingToFilesAtInputUrl:(NSURL *)inputFileUrl andOutputUrl:(NSURL *)outputFileUrl
{
    switch (decision) {
        case FILE_CLASH_ABORT:
            [self.delegate audioFileConversionControllerDidFinishWithReport:[self generateReport]];
            break;
        case FILE_CLASH_SKIP:
            [self checkForRemainingItemsToProcess];
            break;
        case FILE_CLASH_SKIP_APPLY_TO_ALL:
            self.applySkipToAll = YES;
            [self checkForRemainingItemsToProcess];
            break;
        case FILE_CLASH_DELETE:
            [FileOperations deleteFileIfExists:outputFileUrl];
            [self convertFileFromInputUrl:inputFileUrl toOutputUrl:outputFileUrl];
            break;
        case FILE_CLASH_DELETE_APPLY_TO_ALL:
            self.applyDeleteToAll = YES;
            [self convertFileFromInputUrl:inputFileUrl toOutputUrl:outputFileUrl];
            break;
        default:
            break;
    }
}

-(NSString*)generateReport
{
    NSMutableString *report = [[NSMutableString alloc]init];
    [report appendString:[NSString stringWithFormat:@"Files converted: %ld\n", (long)self.fileConversionCounter]];
    if (self.readWriteFailures > 0) {
        [report appendString:@"---------------------\n"];
        [report appendString:[NSString stringWithFormat:@"Files failed to process: %ld", (long)self.readWriteFailures]];
    }
    if (self.sameLocationFailures > 0) {
        [report appendString:@"---------------------\n"];
        [report appendString:[NSString stringWithFormat:@"Files failed due to input/output files having same name and location: %ld - can not read and write to same file at same time", (long)self.sameLocationFailures]];
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
