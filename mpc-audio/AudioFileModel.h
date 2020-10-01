//
//  AudioFileModel.h
//  MpBlaze
//
//  Created by Carl Taylor on 20/09/2020.
//  Copyright © 2020 Carl Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioFileModel : NSObject

@property (readonly, nonatomic) NSURL *sourceUrl;
@property (readonly, nonatomic) NSURL *destinationUrl;

-(AudioFileModel *)initWithSourceUrl:(NSURL*)sourceUrl andDestinationUrl:(NSURL*) destinationUrl;

@end
