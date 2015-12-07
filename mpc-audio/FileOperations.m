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
    NSMutableString *newFileName = [[NSMutableString alloc]init];
    NSString *exportPrefix = [self cleanString:exportConfig.exportPrefix];
    NSString *fileNumberAsString = [NSString stringWithFormat:@"%ld", (long)fileNumber];
    
    // Remove extension as we will always be exporting as .wav
    NSString *fileNameWithoutExtension = [self cleanString:[fileName stringByDeletingPathExtension]];
    
    // Add user created prefix (if exists) and see if we need to keep original prefix or overwrite it
    if (exportPrefix) {
        [newFileName appendString:exportPrefix];
        if ([exportConfig.replaceOriginalFilePrefix boolValue]) {
            NSString *slicedFileName = [fileNameWithoutExtension substringFromIndex:exportPrefix.length];
            [newFileName appendString:slicedFileName];
        } else {
            [newFileName appendString:fileNameWithoutExtension];
        }
    } else {
        [newFileName appendString:fileNameWithoutExtension];
    }
    
    // Now we need to see if string needs trimming back to the permitted number of characters (with/wihout appended file number)
    NSNumber *permittedNumberOfCharactersInFileName = exportConfig.permitedNumberOfCharactersInFileName;
    BOOL appendNumberToFileName = [exportConfig.appendNumberToFileName boolValue];
    
    // Check if we need to append file number
    if (appendNumberToFileName) {
        if ((newFileName.length + fileNumberAsString.length) > permittedNumberOfCharactersInFileName.longValue) {
            // Total string length including number is too long, we need to trim it down
        NSInteger totalProposedLegth = (newFileName.length + fileNumberAsString.length);
        } else {
            // Total string (including file number) doesnt go over permitted limit so we are cool
            [newFileName appendString:fileNumberAsString];
        }
    } else if (newFileName.length > permittedNumberOfCharactersInFileName.longValue) {
        // We are not appending file number but the string is still too long
        NSString *slicedString = [newFileName substringToIndex:permittedNumberOfCharactersInFileName.integerValue];
        newFileName = [slicedString copy];
    }
    
    [newFileName appendString:@".wav"];
    return [newFileName copy];
}

+(NSString*)cleanString:(NSString*)string
{
    NSString *cleanedString = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    return cleanedString;
}

@end
