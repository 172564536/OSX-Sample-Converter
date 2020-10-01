//
//  AudioFileModelFactory.m
//  MpBlaze
//
//  Created by Carl Taylor on 28/09/2020.
//  Copyright © 2020 Carl Taylor. All rights reserved.
//

#import "AudioFileModelFactory.h"
#import "AudioFileModel.h"
#import "ExportConfig.h"

@interface AudioFileModelFactory()
@property(readwrite, nonatomic) BOOL directoryEnumeratorErrorContinueForAll;
@end

@implementation AudioFileModelFactory

- (NSNumber *)countNumberOfAudioFilesPresent:(NSArray *)urls {

    self.directoryEnumeratorErrorContinueForAll = NO;
    int counter = 0;
    for (NSURL *url in urls) {
        if ([self isDirectory:url]) {
            NSArray *subItems = [self collectAllFilesInDirectory:url];
            return [self countNumberOfAudioFilesPresent:subItems];
        } else {
            NSString *extension = [[url pathExtension] lowercaseString];
            if ([extension isEqualToString:@"wav"] || [extension isEqualToString:@"aif"] || [extension isEqualToString:@"aiff"]) {
                counter += 1;
            }
        }
    }
    return [NSNumber numberWithInt:counter];
}

- (NSArray *)convertSourceUrls:(NSArray *)sourceUrls
            parentSourceFolder:(NSURL *)parentSourceFolder
       parentDestinationFolder:(NSURL *)parentDestinationFolder
                  exportConfig:(ExportConfig *)exportConfig {

    self.directoryEnumeratorErrorContinueForAll = NO;
    NSMutableArray *models = [[NSMutableArray alloc] init];
    [self extractAudioFiles:sourceUrls sourceFolder:parentSourceFolder destinationFolder:parentDestinationFolder intoModels:models exportConfig:exportConfig];
    return [models copy];
}

- (void)extractAudioFiles:(NSArray *)sourceFiles
             sourceFolder:(NSURL *)sourceFolder
        destinationFolder:(NSURL *)destinationFolder
               intoModels:(NSMutableArray *)models
             exportConfig:(ExportConfig *)exportConfig {

    [sourceFiles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([self isDirectory:obj]) {
            NSArray *subItems = [self collectAllFilesInDirectory:obj];
            [self extractAudioFiles:subItems sourceFolder:sourceFolder destinationFolder:destinationFolder intoModels:models exportConfig:exportConfig];
        } else {
            NSURL *url = obj;
            NSString *filename = (NSString *) obj;
            NSString *extension = [[filename pathExtension] lowercaseString];
            if ([extension isEqualToString:@"wav"] || [extension isEqualToString:@"aif"] || [extension isEqualToString:@"aiff"]) {

                NSURL *destinationUrl = [self createDestinationURLFromSource:obj
                                                          parentSourceFolder:sourceFolder
                                                     parentDestinationFolder:destinationFolder
                                                     preserveFolderHierarchy:[exportConfig.preserveFolderHierarchy boolValue]];

                AudioFileModel *model = [[AudioFileModel alloc] initWithSourceUrl:url andDestinationUrl:destinationUrl];
                [models addObject:model];
            }
        }
    }];
}

- (BOOL)isDirectory:(NSURL *)url {
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil];
    NSFileAttributeType fileAttributeType = [dictionary valueForKey:NSFileType];
    return [fileAttributeType isEqualToString:NSFileTypeDirectory];
}

-(NSArray *)collectAllFilesInDirectory:(NSURL *)directoryURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];

    NSDirectoryEnumerator *enumerator = [fileManager
            enumeratorAtURL:directoryURL
 includingPropertiesForKeys:keys
                    options:0
               errorHandler:^BOOL(NSURL *url, NSError *error) {
                    if (self.directoryEnumeratorErrorContinueForAll == YES) {
                        return YES;
                    }
                   AudioFileModelFactoryErrorDecision decision = [self.delegate audioFileModelFactoryDidError:[NSString stringWithFormat:@"Error enumerating directories:\n%@", error.description]];
                   switch (decision) {
                       case ERROR_CONTINUE:
                           return YES;
                       case ERROR_CONTINUE_FOR_ALL:
                           self.directoryEnumeratorErrorContinueForAll = YES;
                           return YES;
                       case ERROR_ABORT:
                           return NO;
                   }
                   return NO;
               }];

    NSMutableArray *urls = [[NSMutableArray alloc] init];
    for (NSURL *url in enumerator) {
        NSError *error;
        NSNumber *isDirectory = nil;
        if (![url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
//             handle error????
        }
        else if (![isDirectory boolValue]) {
            [urls addObject:url];
        }
    }

    return [urls copy];
}

-(NSURL*)createDestinationURLFromSource:(NSURL *)source
                     parentSourceFolder:(NSURL *)parentSourceFolder
                parentDestinationFolder:(NSURL *)parentDestinationFolder
                preserveFolderHierarchy:(BOOL)preserveFolderHierarchy {

    NSArray *sourceComponents = [source pathComponents];
    NSString *parentSourceFolderName = [parentSourceFolder pathComponents].lastObject;
    NSArray *parentDestinationComponents = [parentDestinationFolder pathComponents];

    NSMutableArray *newDestinationPathComponents = [[NSMutableArray alloc] initWithArray:parentDestinationComponents];
    [newDestinationPathComponents addObject:parentSourceFolderName];

    if (preserveFolderHierarchy) {
        for (int i = 0; i < sourceComponents.count; ++i) {
            NSString *sourceComp = sourceComponents[i];
            if ([sourceComp isEqual:parentSourceFolderName]) {
                for (int j = i + 1; j < sourceComponents.count; ++j) {
                    [newDestinationPathComponents addObject:sourceComponents[j]];
                }
                break;
            }
        }
    } else {
        [newDestinationPathComponents addObject:[sourceComponents lastObject]];
    }

    return [NSURL fileURLWithPathComponents:newDestinationPathComponents];
}

@end
