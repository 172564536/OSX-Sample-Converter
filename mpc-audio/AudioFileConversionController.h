//
//  AudioFileConversionController.h
//  mpc-audio
//
//  Created by Carl  on 06/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioFileConversionController : NSObject

-(void)convertAudioFilesFromUrls:(NSArray *)audioFileUrls
             toDestinationFolder:(NSURL *)destinationFolder
                      completion:(void(^)(void))complete;

@end
