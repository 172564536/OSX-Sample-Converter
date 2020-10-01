//
//  ExportOptionsConfig.m
//  mpc-audio
//
//  Created by Carl  on 07/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import "ExportConfig.h"
#import "MpcUserDefaults.h"

@implementation ExportConfig

-(void)buildFromDefaults:(NSDictionary *)defaults
{
    NSNumber *appendNumberToFileName                = [defaults valueForKey:DEFS_KEY_APPEND_NUMBER_TO_FILE_NAME];
    NSNumber *replaceOriginalFilePrefix             = [defaults valueForKey:DEFS_KEY_REPLACE_EXISTING_PREFIX];
    NSNumber *permittedNumberOfCharactersInFileName = [defaults valueForKey:DEFS_KEY_MAX_CHARACTER_COUNT];
    NSNumber *convertSamples                        = [defaults valueForKey:DEFS_KEY_CONVERT_SAMPLES];
    NSNumber *preserveFolderHierarchy               = [defaults valueForKey:DEFS_KEY_PRESERVE_FOLDER_HIERARCHY];
    
    _appendNumberToFileName                = appendNumberToFileName;
    _replaceOriginalFilePrefix             = replaceOriginalFilePrefix;
    _permittedNumberOfCharactersInFileName = permittedNumberOfCharactersInFileName;
    _convertSamples                        = convertSamples;
    _preserveFolderHierarchy               = preserveFolderHierarchy;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"ExportPrefix: %@\nAppendNumber: %@\nReplaceOriginalPrefix: %@\nPermittedNumberOfCharsInFileName: %@\nConvertSamples: %@\n PreserveFolderHierarchy: %@\n",
                                      self.exportPrefix, self.appendNumberToFileName, self.replaceOriginalFilePrefix, self.permittedNumberOfCharactersInFileName, self.convertSamples, self.preserveFolderHierarchy];
}

@end
