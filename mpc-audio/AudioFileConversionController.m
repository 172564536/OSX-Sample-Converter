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

@interface AudioFileConversionController ()

@end

@implementation AudioFileConversionController

-(void)convertAudioFilesFromUrls:(NSArray *)audioFileUrls
             toDestinationFolder:(NSURL *)destinationFolder
                      completion:(void(^)(void))complete;
{    
    AudioFileReaderWriter *readerWriter = [[AudioFileReaderWriter alloc]init];
    
    [self processArray:audioFileUrls withReaderWriter:readerWriter toDestinationFolder:destinationFolder completion:^{
        complete();
    }];
}

-(void)processArray:(NSArray *)audioFileUrls
   withReaderWriter:(AudioFileReaderWriter *)readerWriter
toDestinationFolder:(NSURL *)destinationFolder
         completion:(void(^)(void))complete;
{
    NSInteger count = audioFileUrls.count;
    if (count == 0) return complete();
    
    NSURL *inputFileUrl      = [audioFileUrls objectAtIndex:0];
    NSString *inpultFileName = [inputFileUrl lastPathComponent];
    NSString *newFileName    = [FileOperations createNewFileNameFromExistingFileName:inpultFileName withRandomString:@"ZYZ" restrictedToLength:8 fileNumber:count];
    NSURL *outputFileUrl     = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", destinationFolder.absoluteString, newFileName]];
    
    [FileOperations deleteFileIfExists:outputFileUrl];
    
    [readerWriter convertAudioFileFromInputUrl:inputFileUrl toOutputUrl:outputFileUrl withCallBack:^(BOOL success) {
        NSArray *remainingUrls = [audioFileUrls subarrayWithRange:NSMakeRange(1, count-1)];
        [self processArray:remainingUrls withReaderWriter:readerWriter toDestinationFolder:destinationFolder completion:complete];
    }];
}

@end
