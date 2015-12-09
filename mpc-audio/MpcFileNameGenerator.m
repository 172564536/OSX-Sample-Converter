//
//  MpcFileNameGenerator.m
//  mpc-audio
//
//  Created by Carl  on 08/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import "MpcFileNameGenerator.h"
#import "ExportConfig.h"

@implementation MpcFileNameGenerator

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
    
    // Protect against user selecting same destination folder as input AND not selecting any options to alter name (truncate/prefix/append number)
    if ([fileName isEqualToString:mutableFileName]) {
        long charToReplaceIndex = mutableFileName.length - 5;
        NSString *lastCharacterBeforeFileExtension = [mutableFileName substringWithRange:NSMakeRange(charToReplaceIndex, 1)];
        if ([lastCharacterBeforeFileExtension isEqualToString:@"C"] || ([lastCharacterBeforeFileExtension isEqualToString:@"c"])) {
            // picking '_' or 'C' with will mean it can read from 1 file and write to the other in the 'AudioFileReaderWriter'
            [mutableFileName replaceCharactersInRange:NSMakeRange(charToReplaceIndex, 1) withString:@"_"];
        } else {
            [mutableFileName replaceCharactersInRange:NSMakeRange(charToReplaceIndex, 1) withString:@"C"];
        }        
    }
    
    return [mutableFileName copy];
}

+(NSString*)cleanString:(NSString*)string
{
    NSString *cleanedString = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    return cleanedString;
}

@end
