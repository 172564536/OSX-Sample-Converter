//
//  AudioFileConversionController.m
//  mpc-audio
//
//  Created by Carl  on 05/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import "AudioFileConversionController.h"
@import AVFoundation;

@protocol AAPLSampleBufferChannelDelegate;

@interface AAPLSampleBufferChannel : NSObject
{
@private
    AVAssetReaderOutput		*assetReaderOutput;
    AVAssetWriterInput		*assetWriterInput;
    
    dispatch_block_t		completionHandler;
    dispatch_queue_t		serializationQueue;
    BOOL					finished;  // only accessed on serialization queue
}
- (id)initWithAssetReaderOutput:(AVAssetReaderOutput *)assetReaderOutput assetWriterInput:(AVAssetWriterInput *)assetWriterInput;
@property (nonatomic, readonly) NSString *mediaType;
- (void)startWithDelegate:(id <AAPLSampleBufferChannelDelegate>)delegate completionHandler:(dispatch_block_t)completionHandler;  // delegate is retained until completion handler is called.  Completion handler is guaranteed to be called exactly once, whether reading/writing finishes, fails, or is cancelled.  Delegate may be nil.
- (void)cancel;
@end


@protocol AAPLSampleBufferChannelDelegate <NSObject>
@required
- (void)sampleBufferChannel:(AAPLSampleBufferChannel *)sampleBufferChannel didReadSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end


@interface AudioFileConversionController () <AAPLSampleBufferChannelDelegate> {
    
    AVAsset						*asset;
    
    CMTimeRange					timeRange;
    NSInteger					filterTag;
    dispatch_queue_t serializationQueue;
    
    // Only accessed on the main thread
    NSURL *outputURL;
    BOOL writingSamples;
    
    
    AVAssetReader *assetReader;
    AVAssetWriter *assetWriter;
    AAPLSampleBufferChannel	*audioSampleBufferChannel;
    
    BOOL					cancelled;
}

@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic) CMTimeRange timeRange;
@property (nonatomic, copy) NSURL *outputURL;

@property (nonatomic, getter=isWritingSamples) BOOL writingSamples;

@end

@implementation AudioFileConversionController

-(NSArray*)convertAudioFileFromInputUrl:(NSURL *)inputUrl toOutputUrl:(NSURL *)outputUrl
{
    AVAsset *origAsset = [AVAsset assetWithURL:inputUrl];
    self.asset = origAsset;
    
    self.outputURL = outputUrl;
    [self startProgressSheetWithURL:self.outputURL];
    
    
    return nil;
}



+ (NSArray *)readableTypes
{
    return [AVURLAsset audiovisualTypes];
}

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName
{
    return YES;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        NSString *serializationQueueDescription = [NSString stringWithFormat:@"%@ serialization queue", self];
        serializationQueue = dispatch_queue_create([serializationQueueDescription UTF8String], NULL);
    }
    
    return self;
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
{
    NSDictionary *assetOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVAsset *localAsset = [AVURLAsset URLAssetWithURL:url options:assetOptions];
    [self setAsset:localAsset];
    return (localAsset != nil);
}

- (void)start
{
    cancelled = NO;
}

- (void)startProgressSheetWithURL:(NSURL *)localOutputURL
{
//    [self setOutputURL:localOutputURL];
    [self setWritingSamples:YES];
    
    AVAsset *localAsset = [self asset];
    [localAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObjects:@"tracks", @"duration", nil] completionHandler:^{
        // Dispatch the setup work to the serialization queue, to ensure this work is serialized with potential cancellation
        dispatch_async(serializationQueue, ^{
            // Since we are doing these things asynchronously, the user may have already cancelled on the main thread.  In that case, simply return from this block
            if (cancelled)
                return;
            
            BOOL success = YES;
            NSError *localError = nil;
            
            success = ([localAsset statusOfValueForKey:@"tracks" error:&localError] == AVKeyValueStatusLoaded);
            if (success)
                success = ([localAsset statusOfValueForKey:@"duration" error:&localError] == AVKeyValueStatusLoaded);
            
            if (success)
            {
                [self setTimeRange:CMTimeRangeMake(kCMTimeZero, [localAsset duration])];
                
                // AVAssetWriter does not overwrite files for us, so remove the destination file if it already exists
                NSFileManager *fm = [NSFileManager defaultManager];
                NSString *localOutputPath = [localOutputURL path];
                if ([fm fileExistsAtPath:localOutputPath])
                    success = [fm removeItemAtPath:localOutputPath error:&localError];
            }
            
            // Set up the AVAssetReader and AVAssetWriter, then begin writing samples or flag an error
            if (success)
                success = [self setUpReaderAndWriterReturningError:&localError];
            if (success)
                success = [self startReadingAndWritingReturningError:&localError];
            if (!success)
                [self readingAndWritingDidFinishSuccessfully:success withError:localError];
        });
    }];
}


- (BOOL)setUpReaderAndWriterReturningError:(NSError **)outError
{
    BOOL success = YES;
    NSError *localError = nil;
    AVAsset *localAsset = [self asset];
    NSURL *localOutputURL = [self outputURL];
    
    // Create asset reader and asset writer
    assetReader = [[AVAssetReader alloc] initWithAsset:_asset error:&localError];
    success = (assetReader != nil);
    if (success)
    {
        assetWriter = [[AVAssetWriter alloc] initWithURL:localOutputURL fileType:AVFileTypeQuickTimeMovie error:&localError];
        success = (assetWriter != nil);
    }
    
    // Create asset reader outputs and asset writer inputs for the first audio track and first video track of the asset
    if (success)
    {
        AVAssetTrack *audioTrack = nil;
        
        // Grab first audio track and first video track, if the asset has them
        NSArray *audioTracks = [localAsset tracksWithMediaType:AVMediaTypeAudio];
        if ([audioTracks count] > 0) {
            audioTrack = [audioTracks objectAtIndex:0];
        }
        
        if (audioTrack)
        {
            // Decompress to Linear PCM with the asset reader
            NSDictionary *decompressionAudioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                        [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                                        nil];
            AVAssetReaderOutput *output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:decompressionAudioSettings];
            [assetReader addOutput:output];
            
            AudioChannelLayout stereoChannelLayout = {
                .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
                .mChannelBitmap = 0,
                .mNumberChannelDescriptions = 0
            };
            NSData *channelLayoutAsData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
            
            // Compress to 128kbps AAC with the asset writer
//            NSDictionary *compressionAudioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                                      [NSNumber numberWithUnsignedInt:kAudioFormatMPEG4AAC], AVFormatIDKey,
//                                                      [NSNumber numberWithInteger:128000], AVEncoderBitRateKey,
//                                                      [NSNumber numberWithInteger:44100], AVSampleRateKey,
//                                                      channelLayoutAsData, AVChannelLayoutKey,
//                                                      [NSNumber numberWithUnsignedInteger:2], AVNumberOfChannelsKey,
//                                                      nil];
            
            
            // Convert to 16bit 44.1
            NSDictionary *compressionAudioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                      [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                                      [NSNumber numberWithInteger:16], AVLinearPCMBitDepthKey,
                                                      [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
                                                      [NSNumber numberWithBool:YES], AVLinearPCMIsBigEndianKey,
                                                      [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                                      [NSNumber numberWithInteger:44100], AVSampleRateKey,
                                                      channelLayoutAsData, AVChannelLayoutKey,
                                                      [NSNumber numberWithUnsignedInteger:2], AVNumberOfChannelsKey,
                                                      nil];
            
            AVAssetWriterInput *input = [AVAssetWriterInput assetWriterInputWithMediaType:[audioTrack mediaType] outputSettings:compressionAudioSettings];
            [assetWriter addInput:input];
            
            // Create and save an instance of AAPLSampleBufferChannel, which will coordinate the work of reading and writing sample buffers
            audioSampleBufferChannel = [[AAPLSampleBufferChannel alloc] initWithAssetReaderOutput:output assetWriterInput:input];
        }
    }
    
    
    if (outError) {
        *outError = localError;
    }
    
    return success;
}


- (BOOL)startReadingAndWritingReturningError:(NSError **)outError
{
    BOOL success = YES;
    NSError *localError = nil;
    
    // Instruct the asset reader and asset writer to get ready to do work
    success = [assetReader startReading];
    if (!success)
        localError = [assetReader error];
    if (success)
    {
        success = [assetWriter startWriting];
        if (!success)
            localError = [assetWriter error];
    }
    
    if (success)
    {
        dispatch_group_t dispatchGroup = dispatch_group_create();
        
        // Start a sample-writing session
        [assetWriter startSessionAtSourceTime:[self timeRange].start];
        
        // Start reading and writing samples
        if (audioSampleBufferChannel)
        {
            // Only set audio delegate for audio-only assets, else let the video channel drive progress
            id <AAPLSampleBufferChannelDelegate> delegate = nil;
         
                delegate = self;
          
            dispatch_group_enter(dispatchGroup);
            [audioSampleBufferChannel startWithDelegate:delegate completionHandler:^{
                dispatch_group_leave(dispatchGroup);
            }];
        }
        
        // Set up a callback for when the sample writing is finished
        dispatch_group_notify(dispatchGroup, serializationQueue, ^{
            BOOL finalSuccess = YES;
            NSError *finalError = nil;
            
            if (cancelled)
            {
                [assetReader cancelReading];
                [assetWriter cancelWriting];
            }
            else
            {
                if ([assetReader status] == AVAssetReaderStatusFailed)
                {
                    finalSuccess = NO;
                    finalError = [assetReader error];
                }
                
                if (finalSuccess)
                {
                    finalSuccess = [assetWriter finishWriting];
                    if (!finalSuccess)
                        finalError = [assetWriter error];
                }
            }
            
            [self readingAndWritingDidFinishSuccessfully:finalSuccess withError:finalError];
        });
    }
    
    if (outError)
        *outError = localError;
    
    return success;
}

- (void)cancel:(id)sender
{
    // Dispatch cancellation tasks to the serialization queue to avoid races with setup and teardown
    dispatch_async(serializationQueue, ^{
        [audioSampleBufferChannel cancel];
        cancelled = YES;
    });
}

- (void)readingAndWritingDidFinishSuccessfully:(BOOL)success withError:(NSError *)error
{
    if (!success) {
        [assetReader cancelReading];
        [assetWriter cancelWriting];
    }
    
    assetReader = nil;
    assetWriter = nil;
    audioSampleBufferChannel = nil;
    cancelled = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setWritingSamples:NO];
    });
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    // Do nothing
}

static double progressOfSampleBufferInTimeRange(CMSampleBufferRef sampleBuffer, CMTimeRange timeRange)
{
    CMTime progressTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    progressTime = CMTimeSubtract(progressTime, timeRange.start);
    CMTime sampleDuration = CMSampleBufferGetDuration(sampleBuffer);
    if (CMTIME_IS_NUMERIC(sampleDuration))
        progressTime= CMTimeAdd(progressTime, sampleDuration);
    return CMTimeGetSeconds(progressTime) / CMTimeGetSeconds(timeRange.duration);
}

static void removeARGBColorComponentOfPixelBuffer(CVPixelBufferRef pixelBuffer, size_t componentIndex)
{
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    size_t bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
    size_t bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    static const size_t bytesPerPixel = 4;  // constant for ARGB pixel format
    unsigned char *base = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    for (size_t row = 0; row < bufferHeight; ++row)
    {
        for (size_t column = 0; column < bufferWidth; ++column)
        {
            unsigned char *pixel = base + (row * bytesPerRow) + (column * bytesPerPixel);
            pixel[componentIndex] = 0;
        }
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

+ (size_t)componentIndexFromFilterTag:(NSInteger)filterTag
{
    return (size_t)filterTag;  // we set up the tags in the popup button to correspond directly with the index they modify
}

- (void)sampleBufferChannel:(AAPLSampleBufferChannel *)sampleBufferChannel didReadSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CVPixelBufferRef pixelBuffer = NULL;
    
    // Calculate progress (scale of 0.0 to 1.0)
    double progress = progressOfSampleBufferInTimeRange(sampleBuffer, [self timeRange]);
    
    // Grab the pixel buffer from the sample buffer, if possible
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (imageBuffer && (CFGetTypeID(imageBuffer) == CVPixelBufferGetTypeID()))
    {
        pixelBuffer = (CVPixelBufferRef)imageBuffer;
        if (filterTag >= 0)  // -1 means "no filtering, please"
            removeARGBColorComponentOfPixelBuffer(pixelBuffer, [[self class] componentIndexFromFilterTag:filterTag]);
    }
 
}

@end


@interface AAPLSampleBufferChannel ()
- (void)callCompletionHandlerIfNecessary;  // always called on the serialization queue
@end

@implementation AAPLSampleBufferChannel

- (id)initWithAssetReaderOutput:(AVAssetReaderOutput *)localAssetReaderOutput assetWriterInput:(AVAssetWriterInput *)localAssetWriterInput
{
    self = [super init];
    
    if (self)  {
        
        assetReaderOutput = localAssetReaderOutput;
        assetWriterInput = localAssetWriterInput;
        
        finished = NO;
        NSString *serializationQueueDescription = [NSString stringWithFormat:@"%@ serialization queue", self];
        serializationQueue = dispatch_queue_create([serializationQueueDescription UTF8String], NULL);
    }
    
    return self;
}

- (NSString *)mediaType
{
    return [assetReaderOutput mediaType];
}

- (void)startWithDelegate:(id <AAPLSampleBufferChannelDelegate>)delegate completionHandler:(dispatch_block_t)localCompletionHandler
{
    completionHandler = [localCompletionHandler copy];  // released in -callCompletionHandlerIfNecessary
    
    [assetWriterInput requestMediaDataWhenReadyOnQueue:serializationQueue usingBlock:^{
        
        if (finished) return;
        
        BOOL completedOrFailed = NO;
        
        // Read samples in a loop as long as the asset writer input is ready
        while ([assetWriterInput isReadyForMoreMediaData] && !completedOrFailed)
        {
            CMSampleBufferRef sampleBuffer = [assetReaderOutput copyNextSampleBuffer];
            if (sampleBuffer != NULL)
            {
//                if ([delegate respondsToSelector:@selector(sampleBufferChannel:didReadSampleBuffer:)]) {
//                    [delegate sampleBufferChannel:self didReadSampleBuffer:sampleBuffer];
//                }
//                
                BOOL success = [assetWriterInput appendSampleBuffer:sampleBuffer];
                CFRelease(sampleBuffer);
                sampleBuffer = NULL;
                
                completedOrFailed = !success;
            }
            else
            {
                completedOrFailed = YES;
            }
        }
        
        if (completedOrFailed)
            [self callCompletionHandlerIfNecessary];
    }];
}

- (void)cancel
{
    dispatch_async(serializationQueue, ^{
        [self callCompletionHandlerIfNecessary];
    });
}

- (void)callCompletionHandlerIfNecessary
{
    // Set state to mark that we no longer need to call the completion handler, grab the completion handler, and clear out the ivar
    BOOL oldFinished = finished;
    finished = YES;
    
    if (oldFinished == NO)
    {
        [assetWriterInput markAsFinished];  // let the asset writer know that we will not be appending any more samples to this input
        
        dispatch_block_t localCompletionHandler = completionHandler;
        
        completionHandler = nil;
        
        if (localCompletionHandler)
        {
            localCompletionHandler();
        }
    }
}

@end
