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

+(void)attemptAuthorisationForKey:(NSString*)key callBack:(void(^)(NSString *userMessage, BOOL AuthSuccess))callback
{
    NSDictionary *jsonDict = @{@"product_permalink" : @"zuIh",
                               @"license_key" : key};
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self makeServerCallOnBackgroundThreadForJSON:jsonDict WithCallBack:^(ServerResponse *responseObject) {
            [self processResponse:responseObject withCallBack:^(NSString *usermesage, BOOL authSuccess) {
                dispatch_async(dispatch_get_main_queue(), ^(){
                    callback(usermesage, authSuccess);
                });
            }];
        }];
    });
}

+(void)makeServerCallOnBackgroundThreadForJSON:(NSDictionary *)jsonDict WithCallBack:(void(^)(ServerResponse *responseObject))callBack
{
    ServerComms *comms = [[ServerComms alloc]init];
    [comms postJSON:jsonDict toUrl:@"https://api.gumroad.com/v2/licenses/verify" withCallBack:^(ServerResponse *responseObject) {
        callBack(responseObject);
    }];
}

+(void)processResponse:(ServerResponse *)response withCallBack:(void(^)(NSString *usermesage, BOOL authSuccess))callBack
{
    if (response.responseDict) {
        
        NSDictionary *purchaseDict = [response.responseDict objectForKey:@"purchase"];
        
        BOOL purcahseChargedBack = [[purchaseDict objectForKey:@"chargebacked"]boolValue];
        BOOL purchaseRefunded    = [[purchaseDict objectForKey:@"refunded"]boolValue];
        
        NSString *buyersEmail = [purchaseDict objectForKey:@"email"];
        
        
        callBack(nil, YES);
        
        // save users email
    }
}

@end
