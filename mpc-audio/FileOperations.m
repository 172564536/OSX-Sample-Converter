//
//  FileOperations.m
//  mpc-audio
//
//  Created by Carl  on 06/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import "FileOperations.h"

@implementation FileOperations

+(BOOL)createFolderIfDoesNotExistForUrl:(NSURL *)folderUrl;
{
    NSError *error;
    BOOL success = YES;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    success = [fileManager createDirectoryAtURL:folderUrl withIntermediateDirectories:NO attributes:nil error:&error];
    
    if (!error && success) {
        return YES;
    } else {
        return NO;
    }
}

+(BOOL)deleteFileIfExists:(NSURL *)fileUrl
{
    NSError *error;
    BOOL success = YES;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    success = [fileManager removeItemAtURL:fileUrl error:&error];
    
    if (!error && success) {
        return YES;
    } else {
        return NO;
    }
}

@end
