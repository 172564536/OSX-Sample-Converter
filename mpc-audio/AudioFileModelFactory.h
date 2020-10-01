//
//  AudioFileModelFactory.h
//  MpBlaze
//
//  Created by Carl Taylor on 28/09/2020.
//  Copyright © 2020 Carl Taylor. All rights reserved.
//


#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AudioFileModelFactoryErrorDecision) {
    ERROR_ABORT,
    ERROR_CONTINUE,
    ERROR_CONTINUE_FOR_ALL
};

@protocol AudioFileModelFactoryDelegate <NSObject>

@required
-(AudioFileModelFactoryErrorDecision)audioFileModelFactoryDidError:(NSString *)errorDescription;
@end


@class ExportConfig;

@interface AudioFileModelFactory : NSObject

@property (nonatomic, weak) id <AudioFileModelFactoryDelegate>delegate;

-(NSNumber *)countNumberOfAudioFilesPresent:(NSArray *)urls;

-(NSArray*)convertSourceUrls:(NSArray *)sourceUrls
          parentSourceFolder:(NSURL *)parentSourceFolder
     parentDestinationFolder:(NSURL*)parentDestinationFolder
                exportConfig:(ExportConfig *)exportConfig;

@end
