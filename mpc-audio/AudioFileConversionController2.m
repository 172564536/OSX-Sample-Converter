//
//  AudioFileConversionController2.m
//  mpc-audio
//
//  Created by Carl  on 06/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import "AudioFileConversionController2.h"
@import AVFoundation;

@interface AudioFileConversionController2 () {
    AVAsset *asset;
}

//@property (nonatomic, strong) AVAsset *asset;

@end

@implementation AudioFileConversionController2

-(NSArray*)convertAudioFileFromInputUrl:(NSURL *)bob toOutputUrl:(NSURL *)bob2
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES );
    NSString *desktopPath = [paths objectAtIndex:0];
    
    NSURL *origFileUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/atest.wav",desktopPath] isDirectory:NO];
    NSURL *outputFileUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/atest_converted.wav",desktopPath] isDirectory:NO];
    
    
    AVAsset *origAsset = [AVAsset assetWithURL:origFileUrl];
    asset = origAsset;

    // reader
    NSError *readerError = nil;
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset
                                                           error:&readerError];
    
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    AVAssetReaderTrackOutput *readerOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track
                                                                              outputSettings:nil];
    [reader addOutput:readerOutput];
    
    // writer
    NSError *writerError = nil;
    AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:outputFileUrl
                                                      fileType:AVFileTypeAppleM4A
                                                         error:&writerError];
    
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    
    // use different values to affect the downsampling/compression
//    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    [NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
//                                    [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
//                                    [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
//                                    [NSNumber numberWithInt:128000], AVEncoderBitRateKey,
//                                    [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)], AVChannelLayoutKey,
//                                    nil];
//    
    
    
    
    // test
    
    AudioChannelLayout stereoChannelLayout = {
        .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
        .mChannelBitmap = 0,
        .mNumberChannelDescriptions = 0
    };
    NSData *channelLayoutAsData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
    
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                              [NSNumber numberWithInteger:16], AVLinearPCMBitDepthKey,
                                              [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
                                              [NSNumber numberWithBool:YES], AVLinearPCMIsBigEndianKey,
                                              [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                              [NSNumber numberWithInteger:44100], AVSampleRateKey,
                                              channelLayoutAsData, AVChannelLayoutKey,
                                              [NSNumber numberWithUnsignedInteger:2], AVNumberOfChannelsKey,
                                              nil];
    
    //
    
    
    
    
    AVAssetWriterInput *writerInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio
                                                                     outputSettings:outputSettings];
    [writerInput setExpectsMediaDataInRealTime:NO];
    [writer addInput:writerInput];
    
    [writer startWriting];
    [writer startSessionAtSourceTime:kCMTimeZero];
    
    [reader startReading];
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
    [writerInput requestMediaDataWhenReadyOnQueue:mediaInputQueue usingBlock:^{
        
        NSLog(@"Asset Writer ready : %d", writerInput.readyForMoreMediaData);
        while (writerInput.readyForMoreMediaData) {
            CMSampleBufferRef nextBuffer;
            if ([reader status] == AVAssetReaderStatusReading && (nextBuffer = [readerOutput copyNextSampleBuffer])) {
                if (nextBuffer) {
                    NSLog(@"Adding buffer");
                    [writerInput appendSampleBuffer:nextBuffer];
                }
            } else {
                [writerInput markAsFinished];
                
                switch ([reader status]) {
                    case AVAssetReaderStatusCancelled:
                        break;
                    case AVAssetReaderStatusUnknown:
                        break;
                    case AVAssetReaderStatusReading:
                        break;
                    case AVAssetReaderStatusFailed:
                        [writer cancelWriting];
                        break;
                    case AVAssetReaderStatusCompleted:
                        NSLog(@"Writer completed");
                        [writer endSessionAtSourceTime:asset.duration];
                        [writer finishWritingWithCompletionHandler:^{
                            NSData *data = [NSData dataWithContentsOfFile:outputFileUrl.absoluteString];
                            NSLog(@"Data: %@", data);
                        }];                       
                        break;
                }
                break;
            }
        }
    }];
    
    return nil;
}

@end
