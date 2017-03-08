//
//  LAServiceFacade.h
//  LightAPIClient
//
//  Created by Developer iOS on 7/10/13.
//  Copyright (c) 2013 BitBlox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LALocationServiceFacade.h"
#import "LAServiceConfig.h"
#import "LAClient.h"
#import "LAApiError.h"

typedef void (^ LAServiceRequestCallback)(id resource, LAApiError* error);

static NSString *NotificationSecuredStoreApiError = @"SecuredStoreApiError";
static NSString *NotificationSecuredStoreAuthenticationError = @"SecuredStoreAuthenticationError";

@interface LAServiceFacade : NSObject
@property LAClient *apiClient;
@property (nonatomic) LALocationServiceFacade *locationServices;
@property (nonatomic) BOOL debugEnabled;
@property (nonatomic, readonly) NSString *currentUserId;
@property (nonatomic) BOOL requiresLogin;
@property (nonatomic, readonly) NSString *appName;
@property (nonatomic, readonly) NSString *appVersion;
@property (nonatomic, readonly) NSString *appBuild;

#pragma mark - Configuration
-(id)initWithSettings:(LAServiceConfig *)settings;
#pragma mark - Notifications
-(void)registerForNotifications;
-(BOOL)isRemoteNotifcationsAvailable;
-(void)postLocalNotificationWithMessage:(NSString*)message;
#pragma mark - Location
-(void)startLocationServicesAlways;
-(void)startLocationServicesWhileInUse;
-(void)stopLocationServices;
#pragma mark - Security
-(BOOL) requiresLogin; -(void) logout;
-(void) loginUser:(NSString*)username password:(NSString*)password
         callback:(void(^)(NSString* username, LAApiError *error))callback;
#pragma mark - Misc
-(void)killAllRequests;
-(NSString*)urlEncodedStringFromString:(NSString*)string;
-(LAApiError*)catchApiErrorWithError:(NSError*)error statsCode:(NSInteger)statusCode;

#pragma mark - API Call convenience methods
-(void)getResource:(Class)clazz atPath:(NSString*)path callback:(LAServiceRequestCallback)callback;
-(void)getResourceList:(Class)clazz atPath:(NSString*)path callback:(LAServiceRequestCallback)callback;
-(void)deleteResourceAtPath:(NSString*)path callback:(LAServiceRequestCallback)callback;
-(void)putResource:(id<LARepresentation>)resource atPath:(NSString*)path callback:(LAServiceRequestCallback)callback;
-(void)postResource:(id<LARepresentation>)resource atPath:(NSString*)path callback:(LAServiceRequestCallback)callback;

@end
