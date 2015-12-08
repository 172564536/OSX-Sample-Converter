//
//  AudioFileReaderWriter.h
//  mpc-audio
//
//  Created by Carl  on 06/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AudioFileReaderWriterDelegate <NSObject>

@required
-(void)audioFileReaderWriterDidFail;
-(void)audioFileReaderWriterDidCompleteWithSuccess;
@end


@interface AudioFileReaderWriter : NSObject

-(void)convertAudioFileFromInputUrl:(NSURL *)inputUrl
                        toOutputUrl:(NSURL *)outputUrl;

@property (nonatomic, weak) id <AudioFileReaderWriterDelegate>delegate;

@end
