//
//  FileOperations.m
//  mpc-audio
//
//  Created by Carl  on 06/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import "FileOperations.h"
#import "ExportConfig.h"

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

+(NSString*)createNewFileNameFromExistingFileName:(NSString*)fileName
                                 withExportConfig:(ExportConfig *)exportConfig
                                       fileNumber:(NSInteger)fileNumber;
{
    NSMutableString *mutableFileName = [[NSMutableString alloc]init];
    NSString *exportPrefix = [self cleanString:exportConfig.exportPrefix];
    NSString *fileNumberAsString = [NSString stringWithFormat:@"%ld", (long)fileNumber];
    
    // Remove extension as we will always be exporting as .wav
    NSString *fileNameWithoutExtension = [self cleanString:[fileName stringByDeletingPathExtension]];
    
    // Add user created prefix (if exists) and see if we need to keep original prefix or overwrite it
    if (exportPrefix) {
        [mutableFileName appendString:exportPrefix];
        if ([exportConfig.replaceOriginalFilePrefix boolValue]) {
            NSString *slicedFileName = [fileNameWithoutExtension substringFromIndex:exportPrefix.length];
            [mutableFileName appendString:slicedFileName];
        } else {
            [mutableFileName appendString:fileNameWithoutExtension];
        }
    } else {
        [mutableFileName appendString:fileNameWithoutExtension];
    }
    
    // Now we need to see if string needs trimming back to the permitted number of characters (with/wihout appended file number)
    NSNumber *permittedNumberOfCharactersInFileName = exportConfig.permitedNumberOfCharactersInFileName;
    BOOL appendNumberToFileName = [exportConfig.appendNumberToFileName boolValue];
    
    // Check if we need to append file number
    if (appendNumberToFileName) {
        if ((mutableFileName.length + fileNumberAsString.length) > permittedNumberOfCharactersInFileName.longValue) {
            // Total string length including number is too long, we need to trim it down
            NSString *slicedString = [mutableFileName substringToIndex:permittedNumberOfCharactersInFileName.integerValue - fileNumberAsString.length];
            mutableFileName = [[NSMutableString alloc]init];
            [mutableFileName appendString:slicedString];
            [mutableFileName appendString:fileNumberAsString];
        } else {
            // Total string (including file number) doesnt go over permitted limit so we are cool
            [mutableFileName appendString:fileNumberAsString];
        }
    } else if (mutableFileName.length > permittedNumberOfCharactersInFileName.longValue) {
        // We are not appending file number but the string is still too long
        NSString *slicedString = [mutableFileName substringToIndex:permittedNumberOfCharactersInFileName.integerValue];
        mutableFileName = [[NSMutableString alloc]init];
        [mutableFileName appendString:slicedString];
    }
    
    [mutableFileName appendString:@".wav"];
    return [mutableFileName copy];
}

+(NSString*)cleanString:(NSString*)string
{
    NSString *cleanedString = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    return cleanedString;
}

@end
