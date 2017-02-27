//
//  LAServiceFacade.m
//  LightAPIClient
//
//  Created by Seth Jordan on 7/10/13.
//  Copyright (c) 2013 SourceGroove. All rights reserved.
//

#import "LAServiceFacade.h"
#import "LAClient.h"
#import "LASimpleOAuthProvider.h"

static int LADefaultHTTPConnectionTimeout = 60;


@interface LAServiceFacade()

@end

@implementation LAServiceFacade

#pragma mark -
#pragma mark - Property Overrides
#pragma mark -
-(NSString*)currentUserId{
    return [self.apiClient currentUser];
}

-(void)setDebugEnabled:(BOOL)debugEnabled{
    _debugEnabled = debugEnabled;
    self.apiClient.debugEnabled = debugEnabled;
    self.locationServices.debugEnabled = debugEnabled;
}
-(NSString*)appName{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
}
-(NSString*)appVersion{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}
-(NSString*)appBuild{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

#pragma mark -
#pragma mark - Creational
#pragma mark -
-(id)initWithSettings:(LAServiceConfig *)settings{
    if([self init]){
        
        //huddle api client
        self.locationServices = [LALocationServiceFacade sharedFacade];
        [self configureNotifications];
        
        // la client
        NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSString *userAgent = [NSString stringWithFormat:@"ios-%@", version];

        LASimpleOAuthProvider *provider = [[LASimpleOAuthProvider alloc] initWithURL:[NSURL URLWithString:settings.oauthUri]
                                                                      securityDomain:settings.oauthClientId
                                                                            clientId:settings.oauthClientId
                                                                        clientSecret:settings.oauthClientSecret];

        if(settings.oauthHeaderFormat.length > 0){
            provider.oauthHeaderFormat = settings.oauthHeaderFormat;
        }
        
        self.apiClient = [[LAClient alloc] initWithURL:[NSURL URLWithString:settings.apiUri]];
        self.apiClient.securityProvider = provider;
        self.apiClient.cachePolicy = NSURLRequestReloadIgnoringCacheData;
        self.apiClient.connectionTimeoutInSeconds = LADefaultHTTPConnectionTimeout;
        self.apiClient.connectionUserAgent = userAgent;
        self.apiClient.debugEnabled = self.debugEnabled;

    }
    return self;
}

-(NSString*)description{
    return [NSString stringWithFormat:@"Confifgured service facade for api: %@", self.apiClient.baseUrl];
}

-(void)configureNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationAuthorizationChanged:) name:NotificationLocationAuthorizationStatusChange object:nil];
}
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark - Location
#pragma mark -
-(void)registerForLocationServices{
    [self.locationServices.locationManager requestWhenInUseAuthorization];
    [self.locationServices.locationManager requestAlwaysAuthorization];
}
-(void)startLocationServicesWhileInUse{
    [self.locationServices.locationManager requestWhenInUseAuthorization];
    [self.locationServices startUpdatingLocation];
}
-(void)startLocationServicesAlways{
    [self.locationServices.locationManager requestAlwaysAuthorization];
    [self.locationServices startUpdatingLocation];
}
-(void)stopLocationServices{
    [self.locationServices stopUpdatingLocation];
}
-(void)locationAuthorizationChanged:(NSNotification*)notification{
    if([self.locationServices isLocationServicesAvailable]){
        if(self.debugEnabled){
            NSLog(@"Location services are now available....");
        }
        [self.locationServices startUpdatingLocation];
    } else {
        [self.locationServices stopUpdatingLocation];
    }
}

#pragma mark -
#pragma mark - Notifications
#pragma mark -
-(void)registerForNotifications{
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
}
-(BOOL)isRemoteNotifcationsAvailable{
    return [[UIApplication sharedApplication] currentUserNotificationSettings].types != UIUserNotificationTypeNone;
}
-(BOOL)isRegisteredForRemoteNotifications{
    return [[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
}
-(BOOL)isRegisteredForLocalNotifications{
    UIUserNotificationSettings *grantedSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    return !(grantedSettings.types == UIUserNotificationTypeNone);
}
-(void)postLocalNotificationWithMessage:(NSString*)message{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [NSDate date];
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.alertBody = message;
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

#pragma mark -
#pragma mark - Security
#pragma mark -
-(BOOL)requiresLogin{
    return (self.apiClient == nil || [self.apiClient requiresLogin]);
}
-(void)logout{
    NSLog(@"Logging out");
    [self.apiClient logout];
}
-(void)loginUser:(NSString*)username
        password:(NSString*)password
        callback:(void(^)(NSString* username, LAApiError *error))callback{
    
    [self.apiClient loginUser:username
                           password:password
                           callback:^(NSString *username, NSError *error) {
                               if(error != nil){
                                   LAApiError *e = [LAApiError errorWithTitle:@"Login Error"
                                                                 messages:@[[error localizedDescription]]
                                                               statusCode:error.code];
                                   callback(username, e);
                               } else {
                                   NSLog(@"Logged user in user %@", username);
                                   callback(username, nil);

                               }
                           }];
}

#pragma mark - API Overrides
-(void)getResource:(Class)clazz atPath:(NSString*)path callback:(LAServiceRequestCallback)callback{
    [self.apiClient getResource:clazz atPath:path callback:^(id resource, NSHTTPURLResponse *response, NSError *error) {
        callback(resource, [self catchApiErrorWithError:error statsCode:response.statusCode]);
    }];
}
-(void)getResourceList:(Class)clazz atPath:(NSString*)path callback:(LAServiceRequestCallback)callback{
    [self.apiClient getResourceList:clazz atPath:path
                           callback:^(id resource, NSHTTPURLResponse *response, NSError *error) {
                               callback(resource, [self catchApiErrorWithError:error statsCode:response.statusCode]);
                           }];

}
-(void)deleteResourceAtPath:(NSString*)path callback:(LAServiceRequestCallback)callback{
    [self.apiClient deleteResourceAtPath:path callback:^(id resource, NSHTTPURLResponse *response, NSError *error) {
        callback(resource, [self catchApiErrorWithError:error statsCode:response.statusCode]);
    }];
}
-(void)putResource:(id<LARepresentation>)resource atPath:(NSString*)path callback:(LAServiceRequestCallback)callback{
    [self.apiClient putResource:resource atPath:path callback:^(id resource, NSHTTPURLResponse *response, NSError *error) {
        callback(resource, [self catchApiErrorWithError:error statsCode:response.statusCode]);
    }];
}
-(void)postResource:(id<LARepresentation>)resource atPath:(NSString*)path callback:(LAServiceRequestCallback)callback{
    [self.apiClient postResource:resource atPath:path callback:^(id resource, NSHTTPURLResponse *response, NSError *error) {
        callback(resource, [self catchApiErrorWithError:error statsCode:response.statusCode]);
    }];
}

#pragma mark - Misc API Helpers
-(void)killAllRequests{
    [self.apiClient killAllRequests];
}
-(NSString*)urlEncodedStringFromString:(NSString*)string{
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (CFStringRef)string,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                 kCFStringEncodingUTF8));
}
-(LAApiError*)catchApiErrorWithError:(NSError*)error statsCode:(NSInteger)statusCode{
    
    //create api-specific error
    LAApiError *apiError = nil;
    if(error != nil && error.code == LAClientLoginErrorCode){
        apiError = [[LAApiError alloc] init];
        apiError.title = @"Login Error";
        apiError.messages = [NSArray arrayWithObject:@"Authentication required"];
        apiError.statusCode = LAClientLoginErrorCode;
        
    } else if ((error != nil && error.code <= 0) || statusCode == 0 || statusCode == 504){
        apiError = [[LAApiError alloc] init];
        apiError.title = @"Network Error";
        apiError.messages = [NSArray arrayWithObject:@"Please be sure you have a network connection"];
        apiError.statusCode = statusCode;
        
    } else if (statusCode == 500) {
        // Internal Server error
        apiError = [[LAApiError alloc] init];
        apiError.title = @"Server Error";
        apiError.messages = [NSArray arrayWithObject:@"Error occured communicating with BAH servers"];
        apiError.statusCode = statusCode;
        
        
    } else if(statusCode < 200 || statusCode > 299){
        NSData *d = [[error localizedDescription] dataUsingEncoding:NSUTF8StringEncoding];
        if(d){
            apiError = [[LAApiError alloc] initWithData:d];
        }
        /* If the api isn't returning an 'ErrorMessage' representation, then
         the payload isn't json and the above call returns nil, so
         we need to manually build one
         */
        if(apiError == nil){
            apiError = [[LAApiError alloc] init];
            apiError.title = @"Unexpected Error";
            if(error != nil){
                apiError.messages = [NSArray arrayWithObject:[error localizedDescription]];
            }
        }
        apiError.statusCode = statusCode;
        
    }
    
    // do something with it if it's app-wide
    if(apiError != nil){
        if(apiError.statusCode == LAClientLoginErrorCode){
            NSLog(@"LAClientLoginErrorCode - requesting logout");
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationSecuredStoreAuthenticationError object:apiError];
            
        } else if ((apiError.statusCode == 403 && [apiError.title isEqualToString:@"Unauthorized Client"])){
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationSecuredStoreApiError object:apiError];
            
        } else if (apiError.statusCode == 0 || apiError.statusCode == 504){
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationSecuredStoreApiError object:apiError];
        }
    }
    
    return apiError;
}

@end
