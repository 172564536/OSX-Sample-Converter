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
NSString * const SUPPORT_MESSAGE = @"please contact support on: support@mpblaze.rocks";

@implementation SerialNumberController

+(BOOL)userHasAuthorisedApp
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSString *authorisedUser = [defs objectForKey:USER_DEFS_AUTHORISED_EMAIL];
    if (authorisedUser) {
        return NO;
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
    if (!response.connectionMade) {
        return callBack([NSString stringWithFormat:@"Sorry could not connect to Gumroad server at this time. Please check your internet connection or try again later. If this is a persistent issue %@", SUPPORT_MESSAGE], NO);
    }
    
    if (response.responseDict) {
        
        NSDictionary *purchaseDict = [response.responseDict objectForKey:@"purchase"];
        
        if (purchaseDict == nil) {
            NSString *gumroadErrorMessage = [response.responseDict valueForKey:@"message"];
            return callBack(gumroadErrorMessage, NO);
        }
        
        BOOL purchaseChargedBack = [[purchaseDict objectForKey:@"chargebacked"]boolValue];
        if (purchaseChargedBack) {
            return callBack([NSString stringWithFormat:@"Your purchase appears to have been charged back to your payment card, if you believe this to be incorrect  %@", SUPPORT_MESSAGE], NO);
        }
        
        BOOL purchaseRefunded = [[purchaseDict objectForKey:@"refunded"]boolValue];
        if (purchaseRefunded) {
            return callBack([NSString stringWithFormat:@"Your purchase appears to have been refunded, if you believe this to be incorrect %@", SUPPORT_MESSAGE], NO);
        }
        
        NSString *buyersEmail = [purchaseDict objectForKey:@"email"];
        if (buyersEmail) {
            NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
            [defs setObject:buyersEmail forKey:USER_DEFS_AUTHORISED_EMAIL];
            [defs synchronize];
            return callBack(@"Successfully authorised...\nNow get some beats made!", YES);
        } else {
            return callBack([NSString stringWithFormat:@"There was a problem retrieving your email from the Gumroad server, %@", SUPPORT_MESSAGE], NO);
        }
    }
}

@end
