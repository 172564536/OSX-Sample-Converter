//
//  AudioFileConversionController2.m
//  mpc-audio
//
//  Created by Carl  on 06/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import "AudioFileConversionController2.h"
#import "AudioFileReaderWriter.h"

@interface AudioFileConversionController2 ()

@end

@implementation AudioFileConversionController2

-(NSArray*)convertAudioFileFromInputUrl:(NSURL *)bob toOutputUrl:(NSURL *)bob2
{    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES );
    NSString *desktopPath = [paths objectAtIndex:0];
    
    NSURL *origFileUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/atest.aif",desktopPath] isDirectory:NO];
    NSURL *outputFileUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/atest_converted.aif",desktopPath] isDirectory:NO];
    
    AudioFileReaderWriter *readerWriter = [[AudioFileReaderWriter alloc]init];
    [readerWriter convertAudioFileFromInputUrl:origFileUrl toOutputUrl:outputFileUrl withCallBack:^(BOOL success) {
        
    }];
    
    return nil;
}

@end
