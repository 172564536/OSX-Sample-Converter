//
//  AudioFileConversionController.h
//  mpc-audio
//
//  Created by Carl  on 06/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioFileConversionController : NSObject

-(NSArray*)convertAudioFileFromInputUrl:(NSURL *)inputUrl;

@end
