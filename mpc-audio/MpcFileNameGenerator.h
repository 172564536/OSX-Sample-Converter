//
//  MpcFileNameGenerator.h
//  mpc-audio
//
//  Created by Carl  on 08/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ExportConfig;

@interface MpcFileNameGenerator : NSObject

+(NSString*)createNewFileNameFromExistingFileName:(NSString*)fileName
                                 withExportConfig:(ExportConfig *)exportConfig
                                       fileNumber:(NSInteger)fileNumber;

@end
