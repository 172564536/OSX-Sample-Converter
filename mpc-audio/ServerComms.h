//
//  ServerComms.h
//  mpc-audio
//
//  Created by Carl  on 11/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ServerResponse;

@interface ServerComms : NSObject

-(void)postJSON:(id)JSON toUrl:(NSString*)urlString withCallBack:(void(^)(ServerResponse *responseObject))callBack;

@end
