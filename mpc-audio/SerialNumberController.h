//
//  SerialNumberController.h
//  mpc-audio
//
//  Created by Carl  on 11/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SerialNumberController : NSObject

+(BOOL)userHasAuthorisedApp;
+(NSString *)getAuthorisedUsersEmail;
+(void)attemptAuthorisationForKey:(NSString*)key;

@end
