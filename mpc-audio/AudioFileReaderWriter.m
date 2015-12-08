//
//  AudioFileReaderWriter.m
//  mpc-audio
//
//  Created by Carl  on 06/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import "AudioFileReaderWriter.h"
@import AVFoundation;

@implementation AudioFileReaderWriter

-(void)convertAudioFileFromInputUrl:(NSURL *)inputUrl
                        toOutputUrl:(NSURL *)outputUrl
{
    AVAsset *origAsset = [AVAsset assetWithURL:inputUrl];
    
    // set up reader
    NSError *readerError = nil;
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:origAsset
                                                           error:&readerError];
    if (readerError) {
        [self callDelgateOnMainThreadWithOutcome:NO];
    }
    
    AVAssetTrack *track = [[origAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    AVAssetReaderTrackOutput *readerOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track
                                                                              outputSettings:nil];
    [reader addOutput:readerOutput];
    
    // set up writer
    NSError *writerError = nil;
    AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:outputUrl
                                                      fileType:AVFileTypeWAVE
                                                         error:&writerError];
    if (writerError) {
        [self callDelgateOnMainThreadWithOutcome:NO];
    }
    
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    
    AudioChannelLayout stereoChannelLayout = {
        .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
        .mChannelBitmap = 0,
        .mNumberChannelDescriptions = 0
    };
    NSData *channelLayoutAsData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
    
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                    [NSNumber numberWithInteger:16], AVLinearPCMBitDepthKey,
                                    AVSampleRateConverterAlgorithm_Mastering, AVSampleRateConverterAlgorithmKey,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                    [NSNumber numberWithInteger:44100], AVSampleRateKey,
                                    channelLayoutAsData, AVChannelLayoutKey,
                                    [NSNumber numberWithUnsignedInteger:2], AVNumberOfChannelsKey,
                                    nil];
    
    AVAssetWriterInput *writerInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio
                                                                     outputSettings:outputSettings];
    [writerInput setExpectsMediaDataInRealTime:NO];
    [writer addInput:writerInput];
    
    // start conversion process
    [writer startWriting];
    [writer startSessionAtSourceTime:kCMTimeZero];
    [reader startReading];
    
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
    [writerInput requestMediaDataWhenReadyOnQueue:mediaInputQueue usingBlock:^{
        
        NSLog(@"Asset Writer ready : %d", writerInput.readyForMoreMediaData);
        
        @try {
            // Loop through samples until done
            while (writerInput.readyForMoreMediaData) {
                CMSampleBufferRef nextBuffer;
                if ([reader status] == AVAssetReaderStatusReading && (nextBuffer = [readerOutput copyNextSampleBuffer])) {
                    if (nextBuffer) {
                        NSLog(@"Adding buffer");
                        [writerInput appendSampleBuffer:nextBuffer];
                    }
                } else {
                    [writerInput markAsFinished];
                    
                    //ToDo:
                    // 1. will this reader status need checking periodically (with other enum values) rather then just at end?
                    
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wswitch"
                    switch ([reader status]) {
                        case AVAssetReaderStatusFailed:
                            [writer cancelWriting];
                            [self callDelgateOnMainThreadWithOutcome:NO];
                        case AVAssetReaderStatusCompleted:
                            NSLog(@"Writer completed");
                            [writer endSessionAtSourceTime:origAsset.duration];
                            [writer finishWritingWithCompletionHandler:^{
                                [self callDelgateOnMainThreadWithOutcome:YES];
                            }];
                            break;
                    }
#pragma GCC diagnostic pop
                    break;
                }
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Error Converting File. Maybe a compressed format made its way in? %@", exception.description);
            [self callDelgateOnMainThreadWithOutcome:NO];
        }
    }];
}

-(void)callDelgateOnMainThreadWithOutcome:(BOOL)success
{
    if (success) {
        [self.delegate audioFileReaderWriterDidCompleteWithSuccess];
    } else {
        [self.delegate audioFileReaderWriterDidFail];
    }
}

@end
