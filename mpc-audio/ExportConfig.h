//
//  ExportOptionsConfig.h
//  mpc-audio
//
//  Created by Carl  on 07/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ExportConfig : NSObject

@property (copy, readwrite) NSString *exportPrefix;

@property (readonly) NSNumber *appendNumberToFileName;
@property (readonly) NSNumber *replaceOriginalFilePrefix;
@property (readonly) NSNumber *permitedNumberOfCharactersInFileName;

-(void)buildFromDefaults:(NSDictionary *)defaults;

@end
