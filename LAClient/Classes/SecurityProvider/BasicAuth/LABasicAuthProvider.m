//
//  LABasicAuthClient.m
//  LightApiClient
//
//  Created by Seth Jordan on 6/13/13.
//  Copyright (c) 2013 SourceGroove. All rights reserved.
//

#import "LABasicAuthProvider.h"
#import "KeychainItemWrapper.h"

@interface LABasicAuthProvider()
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *creds;
@property (nonatomic, retain) NSString *securityDomain;
@property (nonatomic, retain) NSString *keychainAccessGroup;
@end

@implementation LABasicAuthProvider

-(id)initWithDomain:(NSString*)securityDomain{
    self = [super init];
    if(self){
        self.securityDomain = securityDomain;
        /* we're not supporting this yet, to do so
         means we have to take into consideration app
         entitlements when multiple instances of an client
         are running in an app and across multiple apps...
         */
        self.keychainAccessGroup = nil;
    }
    return self;
}

/*!
 @function secureRequest:
 @abstract secures the provided request.
 @param request the request to secure
 */
-(void)secureRequest:(NSMutableURLRequest*)request{
    NSString *headerValue = [NSString stringWithFormat:@"Basic %@", self.creds];
    [request addValue:headerValue forHTTPHeaderField:@"Authorization"];
}

/*!
 @function loginUser:username:password:callback
 @abstract Logs a user in with a username/password
 @param username username
 @param password password
 @param callback the completion callback
 */
-(void)loginUser:(NSString*)username
        password:(NSString*)password
        callback:(void(^)(NSString* username, NSError *error))callback{

    NSData *encoded = [[NSString stringWithFormat:@"%@:%@", username, password]
                     dataUsingEncoding:NSUTF8StringEncoding];
    self.creds = [encoded base64EncodedStringWithOptions:kNilOptions];
    self.username = username;
}

/*!
 @function logout
 @abstract Logs a user out
 */
-(void)logout{
    self.username = nil;
    self.creds = nil;
}

/*!
 @function loginUser:username:password:callback
 @abstract Logs a user in with a username/password
 @param username username
 @param password password
 @param callback the completion callback
 */
-(void)refreshCredentialToQueue:(NSOperationQueue*)queue
             completionCallback:(void(^)(NSString* username, NSError *error))callback{

    callback(self.username, nil);
}

-(BOOL)requiresLogin{
    return (self.creds == nil);
}
-(BOOL)requiresRefresh{
    return FALSE;
}

-(NSString*)currentUser{
    return self.username;
}
#pragma mark -
#pragma mark - Token management
#pragma mark -
-(void)storeCreds{
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:self.securityDomain
                                                                            accessGroup:self.keychainAccessGroup];

    [keychainItem setObject:self.creds forKey:(__bridge NSString*)kSecValueData];
}
-(void)loadCreds{
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:self.securityDomain
                                                                            accessGroup:self.keychainAccessGroup];
    NSString *credentials = [keychainItem objectForKey:(__bridge NSString*)kSecValueData];
    if(credentials != nil && credentials.length > 0){
        self.creds = credentials;
        self.username = [self usernameFromEncodedCreds:credentials];
    }

}
-(void)clearCreds{
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:self.securityDomain
                                                                            accessGroup:self.keychainAccessGroup];
    [keychainItem resetKeychainItem];
}

-(NSString*)usernameFromEncodedCreds:(NSString*)creds{
    NSData *encoded = [creds dataUsingEncoding:NSUTF8StringEncoding];
    NSData *decoded = [[NSData alloc] initWithBase64EncodedData:encoded options:kNilOptions];
    NSString *str = [[NSString alloc] initWithData:decoded encoding:NSUTF8StringEncoding];
    NSRange match = [str rangeOfString:@":"];
    
    NSString *username = nil;
    if(match.location != NSNotFound){
        username = [str substringWithRange: NSMakeRange (0, match.location)];
    }

    return username;
}

@end
