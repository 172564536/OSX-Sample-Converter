//
//  MpcUserDefaults.m
//  mpc-audio
//
//  Created by Carl  on 07/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import "MpcUserDefaults.h"
#import "FileOperations.h"

NSString * const DEFS_KEY_MAX_CHARACTER_COUNT        = @"mpc.defs.maxCharCount";
NSString * const DEFS_KEY_APPEND_NUMBER_TO_FILE_NAME = @"mpc.defs.appendNumberToFileName";
NSString * const DEFS_KEY_REPLACE_EXISTING_PREFIX    = @"mpc.defs.replaceExistingPrefix";
NSString * const DEFS_KEY_CONVERT_SAMPLES            = @"mpc.defs.convertSamples";

NSString * const FOLDER_NAME = @"Mpc-Audio-Convert";
NSString * const PLIST_NAME  = @"mpcUserSettings.plist";

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

+(NSString *)getPath
{
    NSString *destPath = [self getFolderPath];
    destPath = [destPath stringByAppendingPathComponent:PLIST_NAME];
    return destPath;
}

+(NSString *)getFolderPath
{
    NSString *folderPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    folderPath = [folderPath stringByAppendingPathComponent:FOLDER_NAME];
    return folderPath;
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

+(void)setUpDefaultValuesIfPlistMissing
{
    NSMutableDictionary *defs = [self getUserDefs];
    
    if ([[defs allKeys]count] == 0) {
        
        NSString *folderPath = [self getFolderPath];
        NSURL *folderUrl = [[NSURL alloc]initFileURLWithPath:folderPath];
        [FileOperations createFolderAtUrl:folderUrl];
        
        [defs setValue:@16 forKey:DEFS_KEY_MAX_CHARACTER_COUNT];
        [defs setValue:@YES forKey:DEFS_KEY_APPEND_NUMBER_TO_FILE_NAME];
        [defs setValue:@NO forKey:DEFS_KEY_REPLACE_EXISTING_PREFIX];
        [defs setValue:@YES forKey:DEFS_KEY_CONVERT_SAMPLES];
        [defs writeToFile:[self getPath] atomically:YES];
    } else {
        // this is a bit of a hack to add a default value for existing users so I dont have to get them to delete the app
        if (![defs valueForKey:DEFS_KEY_CONVERT_SAMPLES]) {
            [defs setValue:@YES forKey:DEFS_KEY_CONVERT_SAMPLES];
            [defs writeToFile:[self getPath] atomically:YES];
        }
    }
}

@end
