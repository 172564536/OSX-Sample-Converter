//
//  AudioFileConversionController.h
//  mpc-audio
//
//  Created by Carl  on 05/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioFileConversionController : NSObject

-(NSArray*)convertAudioFileFromInputUrl:(NSURL *)inputUrl toOutputUrl:(NSURL *)outputUrl;

@end
