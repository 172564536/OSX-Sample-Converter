//
//  FileOperations.m
//  mpc-audio
//
//  Created by Carl  on 06/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import "FileOperations.h"

@implementation FileOperations

+(BOOL)createFolderAtUrl:(NSURL *)fileUrl
{
    NSError *error;
    BOOL success = YES;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    success = [fileManager createDirectoryAtURL:fileUrl withIntermediateDirectories:YES attributes:nil error:&error];
    
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

+(BOOL)fileExistsAtUrl:(NSURL *)fileUrl
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL fileExists = [fileManager fileExistsAtPath:fileUrl.path isDirectory:NO];
    return fileExists;
}

+(BOOL)copyItemFromURL:(NSURL *)sourceUrl toUrl:(NSURL *)destinationUrl
{
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager copyItemAtURL:sourceUrl toURL:destinationUrl error:&error];
    if (!error) {
        return YES;
    } else {
        return NO;
    }
}

@end
