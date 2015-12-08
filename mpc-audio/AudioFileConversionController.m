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

@interface AudioFileConversionController () <AudioFileReaderWriterDelegate>

@property (nonatomic, strong) AudioFileReaderWriter *readerWriter;
@property (nonatomic, strong) NSMutableArray *audioFileUrls;
@property (nonatomic, strong) ExportConfig *exportConfig;

@property (nonatomic, strong) NSURL *currentExportUrl;
@property (nonatomic, strong) NSURL *destintionFolderUrl;

@property NSInteger counter;

@end

@implementation AudioFileConversionController

#pragma mark -
#pragma mark - SetUp

-(void)initializeReaderWriter
{
    self.readerWriter = nil;
    self.readerWriter.delegate = nil;
    self.readerWriter = [[AudioFileReaderWriter alloc]init];
    self.readerWriter.delegate = self;
}

#pragma mark -
#pragma mark - Conversion

-(void)convertAudioFilesFromUrls:(NSArray *)audioFileUrls
             toDestinationFolder:(NSURL *)destinationFolder
         withExportOptionsConfig:(ExportConfig *)exportConfig

{
    [self initializeReaderWriter];
    self.destintionFolderUrl = destinationFolder;
    self.audioFileUrls = [[NSMutableArray alloc]initWithArray:audioFileUrls];
    self.exportConfig = exportConfig;

    [self checkForRemainingItemsToProcess];
}

-(void)checkForRemainingItemsToProcess
{
    if (self.audioFileUrls.count > 0) {
        self.counter ++;
        [self.delegate audioFileConversionControllerDidReportProgress];
        
        self.currentExportUrl = [self.audioFileUrls objectAtIndex:0];
        [self.audioFileUrls removeObjectAtIndex:0];
        [self processItemForUrl:self.currentExportUrl];
    } else {
        [self.delegate audioFileConversionControllerDidFinish];
    }
}

-(void)processItemForUrl:(NSURL*)inputFileUrl
{
    NSString *inpultFileName = [inputFileUrl lastPathComponent];
    NSString *newFileName    = [MpcFileNameGenerator createNewFileNameFromExistingFileName:inpultFileName withExportConfig:self.exportConfig fileNumber:self.counter];
    NSURL *outputFileUrl     = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.destintionFolderUrl.absoluteString, newFileName]];
    
    [FileOperations deleteFileIfExists:outputFileUrl];
    
    [self.readerWriter convertAudioFileFromInputUrl:inputFileUrl toOutputUrl:outputFileUrl];
}

#pragma mark -
#pragma mark - AudioFileReaderWriterDelegate

-(void)audioFileReaderWriterDidCompleteWithSuccess
{
    [self checkForRemainingItemsToProcess];
}

-(void)audioFileReaderWriterDidFail
{
    [self initializeReaderWriter];
    [FileOperations deleteFileIfExists:self.currentExportUrl];
    [self checkForRemainingItemsToProcess];
}

@end
