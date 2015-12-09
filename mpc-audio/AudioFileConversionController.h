//
//  AudioFileConversionController.h
//  mpc-audio
//
//  Created by Carl  on 06/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol AudioFileConversionControllerDelegate <NSObject>

@required
-(void)audioFileConversionControllerDidReportProgress;
-(void)audioFileConversionControllerDidFinishWithReport:(NSString *)report;
@end

@class ExportConfig;

@interface AudioFileConversionController : NSObject

-(instancetype)initWithAudioFileUrls:(NSArray *)audioFileUrls DestinationFolder:(NSURL *)destinationFolder andExportOptionsConfig:(ExportConfig *)exportConfig;
-(void)start;

@property (nonatomic, weak) id <AudioFileConversionControllerDelegate>delegate;

@end
