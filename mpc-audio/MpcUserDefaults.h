//
//  MpcUserDefaults.h
//  mpc-audio
//
//  Created by Carl  on 07/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MpcUserDefaults : NSObject

// Keys
extern NSString * const DEFS_KEY_MAX_CHARACTER_COUNT;
extern NSString * const DEFS_KEY_APPEND_NUMBER_TO_FILE_NAME;
extern NSString * const DEFS_KEY_REPLACE_EXISTING_PREFIX;
//

+(id)valueForKey:(NSString*)key;
+(void)setValue:(id)value forKey:(NSString*)key;

@end
