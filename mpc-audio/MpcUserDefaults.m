//
//  MpcUserDefaults.m
//  mpc-audio
//
//  Created by Carl  on 07/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import "MpcUserDefaults.h"

NSString * const DEFS_KEY_MAX_CHARACTER_COUNT        = @"mpc.defs.maxCharCount";
NSString * const DEFS_KEY_APPEND_NUMBER_TO_FILE_NAME = @"mpc.defs.appendNumberToFileName";
NSString * const DEFS_KEY_REPLACE_EXISTING_PREFIX    = @"mpc.defs.replaceExistingPrefix";

@implementation MpcUserDefaults

+(NSDictionary *)getImmutableDefsFile
{
    return [[self getUserDefs]copy];
}

+(NSMutableDictionary*)getUserDefs
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:[self getPath]]) {
        NSMutableDictionary *savedDict = [[NSMutableDictionary alloc] initWithContentsOfFile:[self getPath]];
        return savedDict;
    } else {
        NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
        return newDict;
    }
}

+(NSString*)getPath
{
    NSString *destPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    destPath = [destPath stringByAppendingPathComponent:@"mpcUserSettings.plist"];
    return destPath;
}

+(id)valueForKey:(NSString*)key;
{
    NSMutableDictionary *defs = [self getUserDefs];
    id value = [defs valueForKey:key];
    return value;
}

+(void)setValue:(id)value forKey:(NSString*)key;
{
    NSMutableDictionary *defs = [self getUserDefs];
    [defs setValue:value forKey:key];
    [defs writeToFile:[self getPath] atomically:YES];
}

+(void)setUpDefaultValues
{
    NSMutableDictionary *defs = [self getUserDefs];
    [defs setValue:@16 forKey:DEFS_KEY_MAX_CHARACTER_COUNT];
    [defs setValue:@YES forKey:DEFS_KEY_APPEND_NUMBER_TO_FILE_NAME];
    [defs setValue:@NO forKey:DEFS_KEY_REPLACE_EXISTING_PREFIX];
    [defs writeToFile:[self getPath] atomically:YES];
}

@end
