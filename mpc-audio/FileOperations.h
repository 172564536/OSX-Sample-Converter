//
//  FileOperations.h
//  mpc-audio
//
//  Created by Carl  on 06/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileOperations : NSObject

+(BOOL)createFolderIfDoesNotExistForUrl:(NSURL *)folderUrl;
+(BOOL)deleteFileIfExists:(NSURL *)fileUrl;

@end
