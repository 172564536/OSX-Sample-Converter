//
//  FileOperations.m
//  mpc-audio
//
//  Created by Carl  on 06/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import "FileOperations.h"

@implementation FileOperations

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

+(NSString*)createNewFileNameFromExistingFileName:(NSString*)fileName
                                 withRandomString:(NSString *)randomString
                               restrictedToLength:(NSInteger)permitedLength
                                       fileNumber:(NSInteger)fileNumnber;
{
    NSString *fileExtension = [fileName pathExtension];
    NSString *slicedFileName = [fileName substringToIndex:4];
    NSString *fileNumberString = [NSString stringWithFormat:@"%ld", (long)fileNumnber];
    NSString *newFileNanme = [NSString stringWithFormat:@"%@_%@_%@.%@", slicedFileName, randomString, fileNumberString, fileExtension];
    
    return newFileNanme;
}

@end
