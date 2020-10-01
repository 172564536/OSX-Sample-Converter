//
//  AudioFileModel.m
//  MpBlaze
//
//  Created by Carl Taylor on 20/09/2020.
//  Copyright © 2020 Carl Taylor. All rights reserved.
//

#import "AudioFileModel.h"

@interface AudioFileModel ()
@property(readwrite, nonatomic) NSURL *sourceUrl;
@property(readwrite, nonatomic) NSURL *destinationUrl;
@end

@implementation AudioFileModel

- (AudioFileModel *)initWithSourceUrl:(NSURL *)sourceUrl andDestinationUrl:(NSURL *)destinationUrl {
    self = [super init];
    if (self) {
        self.sourceUrl = sourceUrl;
        self.destinationUrl = destinationUrl;
    }
    return self;
}

@end
