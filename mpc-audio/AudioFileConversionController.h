//
//  AudioFileConversionController.h
//  mpc-audio
//
//  Created by Carl  on 06/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const FILE_CLASH_BUTTON_TITLE_ABORT;
extern NSString * const FILE_CLASH_BUTTON_TITLE_SKIP;
extern NSString * const FILE_CLASH_BUTTON_TITLE_SKIP_APPLY_TO_ALL;
extern NSString * const FILE_CLASH_BUTTON_TITLE_DELETE;
extern NSString * const FILE_CLASH_BUTTON_TITLE_DELETE_APPLY_TO_ALL;

typedef NS_ENUM(NSUInteger, FileClashDecision) {
    FILE_CLASH_ABORT,
    FILE_CLASH_SKIP,
    FILE_CLASH_SKIP_APPLY_TO_ALL,
    FILE_CLASH_DELETE,
    FILE_CLASH_DELETE_APPLY_TO_ALL,
};

@protocol AudioFileConversionControllerDelegate <NSObject>

@required
-(void)audioFileConversionControllerDidReportProgress;
-(void)audioFileConversionControllerDidFinishWithReport:(NSString *)report;
-(FileClashDecision)audioFileConversionControllerDidEncounterFileClashForFile:(NSString*)fileName;
@end

@class ExportConfig;

@interface AudioFileConversionController : NSObject

-(instancetype)initWithAudioFileUrls:(NSArray *)audioFileUrls DestinationFolder:(NSURL *)destinationFolder andExportOptionsConfig:(ExportConfig *)exportConfig;
-(void)start;

@property (nonatomic, weak) id <AudioFileConversionControllerDelegate>delegate;

@end
