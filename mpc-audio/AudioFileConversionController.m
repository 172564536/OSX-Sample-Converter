//
//  AudioFileConversionController.m
//  mpc-audio
//
//  Created by Carl  on 06/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import "AudioFileConversionController.h"
#import "AudioFileReaderWriter.h"
#import "FileOperations.h"
#import "AudioFileModel.h"
#import "MpcFileNameGenerator.h"
#import "ExportConfig.h"

NSString * const FILE_CLASH_BUTTON_TITLE_ABORT               = @"Abort";
NSString * const FILE_CLASH_BUTTON_TITLE_SKIP                = @"Skip";
NSString * const FILE_CLASH_BUTTON_TITLE_SKIP_APPLY_TO_ALL   = @"Skip (apply all)";
NSString * const FILE_CLASH_BUTTON_TITLE_DELETE              = @"Delete";
NSString * const FILE_CLASH_BUTTON_TITLE_DELETE_APPLY_TO_ALL = @"Delete (apply all)";

@interface AudioFileConversionController () <AudioFileReaderWriterDelegate>

@property (nonatomic, strong) AudioFileReaderWriter *readerWriter;
@property (nonatomic, strong) NSMutableArray *audioFileModels;
@property (nonatomic, strong) ExportConfig *exportConfig;

@property (nonatomic, strong) AudioFileModel *currentModel;

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
    [NSException raise:@"** Invalid State **" format:@"Call 'initWithAudioFileModels' instead"];
    return nil;
}

- (instancetype)initWithAudioFileModels:(NSArray *)models
                 andExportOptionsConfig:(ExportConfig *)exportConfig

{
    self = [super init];
    
    if (self) {
        [self initializeReaderWriter];
        self.audioFileModels = [[NSMutableArray alloc]initWithArray:models];
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
    if (self.audioFileModels.count > 0) {
        [self.delegate audioFileConversionControllerDidReportProgress];
        
        self.currentModel = [self.audioFileModels objectAtIndex:0];
        [self.audioFileModels removeObjectAtIndex:0];
        [self processModel:self.currentModel];
    } else {
        [self.delegate audioFileConversionControllerDidFinishWithReport:[self generateReport]];
    }
}

-(void)processModel:(AudioFileModel*)model
{
    NSURL *inputFileUrl = model.sourceUrl;
    NSString *inputFileName = [inputFileUrl lastPathComponent];
    
    NSString *newFileName = [MpcFileNameGenerator createNewFileNameFromExistingFileName:inputFileName withExportConfig:self.exportConfig fileNumber:self.fileConversionCounter];

    NSMutableArray *outputPaths = [[NSMutableArray alloc] initWithArray:[model.destinationUrl pathComponents]];
    [outputPaths removeLastObject];
    NSURL *folderPath = [NSURL fileURLWithPathComponents:outputPaths];

    BOOL isDir;
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL exists = [fileManager fileExistsAtPath:folderPath.absoluteString isDirectory:&isDir];
    if (!exists || (exists && !isDir)) {
      [fileManager createDirectoryAtURL:folderPath withIntermediateDirectories:YES attributes:nil error:&error];
      if (error) {
          [self.delegate audioFileConversionControllerDidError:error.description];
          return;
      }
    }

    [outputPaths addObject:newFileName];
    NSURL *outputFileUrl = [NSURL fileURLWithPathComponents:outputPaths];
    
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
    [FileOperations deleteFileIfExists:self.currentModel.destinationUrl];
    [self checkForRemainingItemsToProcess];
}

@end
