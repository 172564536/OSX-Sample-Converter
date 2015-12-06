//
//  AudioFileConversionController.m
//  mpc-audio
//
//  Created by Carl  on 06/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import "AudioFileConversionController.h"
#import "AudioFileReaderWriter.h"

@interface AudioFileConversionController ()

@end

@implementation AudioFileConversionController

-(NSArray*)convertAudioFileFromInputUrl:(NSURL *)bob
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
