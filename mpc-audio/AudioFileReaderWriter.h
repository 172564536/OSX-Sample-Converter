//
//  AudioFileReaderWriter.h
//  mpc-audio
//
//  Created by Carl  on 06/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioFileReaderWriter : NSObject

-(void)convertAudioFileFromInputUrl:(NSURL *)inputUrl toOutputUrl:(NSURL *)outputUrl withCallBack:(void(^)(BOOL success))callBack;

@end
