//
//  SerialNumberController.m
//  mpc-audio
//
//  Created by Carl  on 11/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

#import "SerialNumberController.h"
#import "ServerResponse.h"
#import "ServerComms.h"

NSString * const USER_DEFS_AUTHORISED_EMAIL = @"mpc.audio.USER_DEFS_AUTHORISED_EMAIL";

@implementation SerialNumberController

+(BOOL)userHasAuthorisedApp
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSString *authorisedUser = [defs objectForKey:USER_DEFS_AUTHORISED_EMAIL];
    if (authorisedUser) {
        return YES;
    } else {
        return NO;
    }
}

+(NSString *)getAuthorisedUsersEmail
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSString *authorisedUser = [defs objectForKey:USER_DEFS_AUTHORISED_EMAIL];
    return authorisedUser;
}

+(void)attemptAuthorisationForKey:(NSString*)key
{
    NSDictionary *jsonDict = @{@"product_permalink" : @"zuIh",
                               @"license_key" : key};
    
    ServerComms *comms = [[ServerComms alloc]init];
    [comms postJSON:jsonDict toUrl:@"https://api.gumroad.com/v2/licenses/verify" withCallBack:^(ServerResponse *responseObject) {
        
        if (responseObject.responseDict) {
            
            NSDictionary *purchaseDict = [responseObject.responseDict objectForKey:@"purchase"];
            
            BOOL purcahseChargedBack = [[purchaseDict objectForKey:@"chargebacked"]boolValue];
            BOOL purchaseRefunded    = [[purchaseDict objectForKey:@"refunded"]boolValue];
            
            NSString *buyersEmail = [purchaseDict objectForKey:@"email"];
        }
        
       
        
    }];
}

@end
