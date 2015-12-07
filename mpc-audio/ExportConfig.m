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
    NSNumber *appendNumberToFileName               = [defaults valueForKey:DEFS_KEY_APPEND_NUMBER_TO_FILE_NAME];
    NSNumber *replaceOriginalFilePrefix            = [defaults valueForKey:DEFS_KEY_REPLACE_EXISTING_PREFIX];
    NSNumber *permitedNumberOfCharactersInFileName = [defaults valueForKey:DEFS_KEY_MAX_CHARACTER_COUNT];
    
    _appendNumberToFileName               = appendNumberToFileName;
    _replaceOriginalFilePrefix            = replaceOriginalFilePrefix;
    _permitedNumberOfCharactersInFileName = permitedNumberOfCharactersInFileName;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"ExportPrefix: %@\nAppendNumber: %@\nReplaceOrignalPrefix: %@\nPermittedNumberOfCharsInFileName: %@\n",
            self.exportPrefix, self.appendNumberToFileName, self.replaceOriginalFilePrefix, self.permitedNumberOfCharactersInFileName];
}

@end
