//
//  ExportOptionsConfig.h
//  mpc-audio
//
//  Created by Carl  on 07/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ExportConfig : NSObject

@property (copy, readwrite, nonatomic) NSString *exportPrefix;

@property (readonly, nonatomic) NSNumber *appendNumberToFileName;
@property (readonly, nonatomic) NSNumber *replaceOriginalFilePrefix;
@property (readonly, nonatomic) NSNumber *permitedNumberOfCharactersInFileName;
@property (readonly, nonatomic) NSNumber *convertSamples;

-(void)buildFromDefaults:(NSDictionary *)defaults;

@end
