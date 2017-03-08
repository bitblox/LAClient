//
//  LAOAuthClient.m
//  LightAPIClient
//
//  Created by Developer iOS on 7/10/13.
//  Copyright (c) 2013 BitBlox. All rights reserved.
//

#import "LASimpleOAuthProvider.h"
#import "LAOAuthToken.h"
#import "NSError+LAAdditions.h"
#import <Security/Security.h>
#import "KeychainItemWrapper.h"

@interface LASimpleOAuthProvider()
@property(strong)NSString *clientId;
@property(strong)NSString *clientSecret;
@property(strong)NSURL *uriBase;
@property(strong)NSString *securityDomain;
@property BOOL isRefreshing;
@property BOOL useDefaultsForTokenStorage;
@end

@implementation LASimpleOAuthProvider

@synthesize token = _token;

-(id)initWithURL:(NSURL *)url
   securityDomain:(NSString*)securityDomain
        clientId:(NSString*)clientId
    clientSecret:(NSString*)clientSecret{

    NSParameterAssert(url);
    NSParameterAssert(clientId);
    NSParameterAssert(clientSecret);
    
    self = [super init];
    if(!self){
        return nil;
    }
    
    self.uriBase = url;
    self.securityDomain = securityDomain;
    self.clientId = clientId;
    self.clientSecret = clientSecret;
    self.isRefreshing = FALSE;
    
    /*
     Using the default oauth header format.
     */
    self.oauthHeaderFormat = DEFAULT_OAUTH_HEADER_FORMAT;
    
    /*
     There's some funny business with a nil keychain 
     access group when running multiple apps on the
     simulator, so we use defaults for token storage
     */
#if (TARGET_IPHONE_SIMULATOR)
    NSLog(@"Using user defaults for token storage since you are running in a simulator");
    self.useDefaultsForTokenStorage = TRUE;
#endif

    return self;
}

-(void)setToken:(LAOAuthToken *)token{
    _token = token;
    if(token == nil){
        [self clearToken];
    } else {
        [self saveToken:token];
    }
}
-(LAOAuthToken*)token{
    if(_token == nil){
        _token = [self loadToken];
    }
    return _token;
}

-(NSString*)username{
    if(self.token != nil){
        return self.token.username;
    } else {
        return nil;
    }
}

-(BOOL)isUserLoggedIn{
    if(self.token == nil){
        return FALSE;
    } else {
        return TRUE;
    }
}

#pragma mark - 
#pragma mark - LASecurityClient
#pragma mark - 
-(void)secureRequest:(NSMutableURLRequest*)request{
    NSString *headerValue = [NSString stringWithFormat:self.oauthHeaderFormat, self.token.access_token];
    [request addValue:headerValue forHTTPHeaderField:@"Authorization"];
}
-(void)loginUser:(NSString*)username
        password:(NSString*)password
        callback:(void(^)(NSString* username, NSError *error))callback{
    
    [self getTokenForUsername:username
                     password:password
           completionCallback:^(LAOAuthToken *token) {
               callback(token.username, nil);
           }
                errorCallback:^(NSError *error) {
                    callback(nil, error);
                }];
}
-(void)refreshCredentialToQueue:(NSOperationQueue*)queue
             completionCallback:(void(^)(NSString* username, NSError *error))callback{
    [self refreshTokenToQueue:queue
           completionCallback:^(LAOAuthToken *token) {
               callback(token.username, nil);
           } errorCallback:^(NSError *error) {
               callback(nil, error);
           }];
}
-(void)logout{
    self.token = nil;
}
-(NSString*)currentUser{
    if(self.token != nil){
        return self.token.username;
    } else {
        return nil;
    }
}
-(BOOL)requiresLogin{
    return (self.token == nil);
}
-(BOOL)requiresRefresh{
    return [self.token isExpired];
}

#pragma mark -
#pragma mark - LAOauthClient
#pragma mark -
-(void)getTokenForUsername:(NSString*)username
                  password:(NSString*)password
        completionCallback:(void(^)(LAOAuthToken *token))completionCallback
             errorCallback:(void (^)(NSError *error))errorCallback{

    NSParameterAssert(username);
    NSParameterAssert(password);
    
    NSString *params = [NSString stringWithFormat:@"grant_type=password&username=%@&password=%@&client_id=%@&client_secret=%@&",
                        [self encodedStringFromString:username],
                        [self encodedStringFromString:password],
                        [self encodedStringFromString:self.clientId],
                        [self encodedStringFromString:self.clientSecret]];
    //NSLog(@"PARAMS:: %@", params);
    NSMutableURLRequest *oauthRequest = [NSMutableURLRequest requestWithURL:self.uriBase];
    oauthRequest.HTTPMethod = @"POST";
    oauthRequest.timeoutInterval = 60;
    oauthRequest.HTTPBody = [params dataUsingEncoding:NSUTF8StringEncoding];
    [oauthRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [oauthRequest addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:nil
                                                     delegateQueue:[NSOperationQueue mainQueue]];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = TRUE;
    [[session dataTaskWithRequest:oauthRequest
               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                               [UIApplication sharedApplication].networkActivityIndicatorVisible = FALSE;

                               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;

                               long statusCode = 0;
                               if(httpResponse != nil){
                                   statusCode = httpResponse.statusCode;
                               }
                               
                               if(error == nil && statusCode >= 200 && statusCode < 300){
                                   LAOAuthToken *token = [[LAOAuthToken alloc] initWithData:data];
                                   token.username = username;
                                   self.token = token;
                                   completionCallback(token);
                                   return;
                               }
                               
                               NSError *oauthError = nil;
                               if(error == nil && statusCode == 400){
                                   oauthError = [NSError errorWithMessage:@"Invalid username or password" code:statusCode];
                                   
                               }else if(error != nil && statusCode == 0){
                                   oauthError = [NSError errorWithMessage:@"Error connecting to authorization server" code:statusCode];
                                   
                               } else {
                                   NSLog(@"Error authentication user status code: %ld body: %@", statusCode, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                                   oauthError = [NSError errorWithMessage:@"Error authenticating user" code:statusCode];

                               }
                               self.token = nil;
                               errorCallback(oauthError);

                           }] resume];

}
-(void)refreshTokenToQueue:(NSOperationQueue*)queue
        completionCallback:(void (^)(LAOAuthToken *token))completionCallback
             errorCallback:(void (^)(NSError *error))errorCallback{

    NSParameterAssert(self.token);
    NSParameterAssert(self.token.refresh_token);
  
    if(self.token == nil){
        NSLog(@"We don't have a token so we can't refresh it.");
        errorCallback([NSError errorWithMessage:@"No token to refresh" code:LAClientLoginErrorCode]);
        return;
        
    } else if(self.isRefreshing){
        NSLog(@"Client is currently refreshing the oauth token, so we can't refresh it now");
        errorCallback([NSError errorWithMessage:@"Credential refresh in progress" code:LAClientRefreshInProgressErrorCode]);
        return;
        
    } else {
        NSLog(@"Refreshing OAuth token...");
        self.isRefreshing = TRUE;
    }
    NSString *params = [NSString stringWithFormat:@"grant_type=refresh_token&refresh_token=%@&client_id=%@&client_secret=%@&",
                        self.token.refresh_token,
                        [self encodedStringFromString:self.clientId],
                        [self encodedStringFromString:self.clientSecret]];
    
    NSMutableURLRequest *oauthRequest = [NSMutableURLRequest requestWithURL:self.uriBase];
    oauthRequest.HTTPMethod = @"POST";
    oauthRequest.timeoutInterval = 90;
    oauthRequest.HTTPBody = [params dataUsingEncoding:NSUTF8StringEncoding];
    [oauthRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [oauthRequest addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:nil
                                                     delegateQueue:queue];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = TRUE;
    [[session dataTaskWithRequest:oauthRequest
               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                               [UIApplication sharedApplication].networkActivityIndicatorVisible = FALSE;
                               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
                               // try and create the token from the response
                               LAOAuthToken *t = nil;
                               if(data != nil){
                                   t =  [[LAOAuthToken alloc] initWithData:data];
                               }
                               
                               // if we have a good token, copy the username forward (from logon and complete)
                               if(t != nil && t.error.length == 0){
                                   t.username = self.token.username;
                                   self.token = t;
                                   self.isRefreshing = FALSE;
                                   completionCallback(t);
                                   return;
                               }
                               
                               NSLog(@"OAuth refresh failed!");
                               if(t != nil && t.error.length > 0){
                                   NSString* message = [NSString stringWithFormat:@"%@ %@", t.error, t.error_description];
                                   error = [NSError errorWithMessage:message
                                                                code:LAClientLoginErrorCode];
                                   
                                   NSLog(@"Deleting local token to prevent future attempts because %@ returned: %@ - %@",
                                         self.uriBase, t.error, t.error_description);
                                   self.token = nil;
                                   
                               } else {
                                   NSLog(@"Not deleting local token because error looks network related.  We don't seem to be able to hit %@",
                                         self.uriBase);
                                   error = [NSError errorWithMessage:@"Error connecting to authorization server"
                                                                code:httpResponse.statusCode];
                               }
                               self.isRefreshing = FALSE;
                               errorCallback(error);
                           }] resume];
}

-(NSString*)encodedStringFromString:(NSString*)string{
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                (CFStringRef)string,
                                                                                NULL,
                                                                                (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                kCFStringEncodingUTF8));
}


-(NSString*)description{
    return [NSString stringWithFormat:@"LAOAuthCLient [OAuth Uri: %@, Security Domain: %@, OAuth Client: %@]", self.uriBase, self.securityDomain, self.clientId];
}


#pragma mark -
#pragma mark - Token management
#pragma mark -
-(void)saveToken:(LAOAuthToken*)token{
    if(self.useDefaultsForTokenStorage){
        [self saveTokenToDefaults:token];
    } else {
        [self saveTokenToKeychain:token];
    }
}
-(LAOAuthToken*)loadToken{
    if(self.useDefaultsForTokenStorage){
        return [self loadTokenFromDefaults];
    } else {
        return [self loadTokenFromKeychain];
    }
}
-(void)clearToken{
     if(self.useDefaultsForTokenStorage){
         [self clearTokenFromDefaults];
     } else {
        [self clearTokenFromKeychain];
    }
}

-(void)saveTokenToDefaults:(LAOAuthToken*)token{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *str = [[NSString alloc] initWithData:[token toData] encoding:NSUTF8StringEncoding];
    [userDefaults setObject:str forKey:self.securityDomain];
    [userDefaults synchronize];
}
-(LAOAuthToken*)loadTokenFromDefaults{
    LAOAuthToken *token = nil;
    NSString *json = [[NSUserDefaults standardUserDefaults] objectForKey:self.securityDomain];
    if(json != nil){
        token = [[LAOAuthToken alloc] initWithData:[json dataUsingEncoding:NSUTF8StringEncoding]];
    }
    return token;
}
-(void)clearTokenFromDefaults{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:nil forKey:self.securityDomain];
    [userDefaults synchronize];
}
-(void)saveTokenToKeychain:(LAOAuthToken*)token{
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:self.securityDomain accessGroup:nil];

    NSString *str = [[NSString alloc] initWithData:[token toData] encoding:NSUTF8StringEncoding];
    [keychainItem setObject:self.securityDomain forKey: (id)kSecAttrService];
    [keychainItem setObject:(__bridge id)kSecAttrAccessibleAlways forKey:(__bridge id)kSecAttrAccessible];
    [keychainItem setObject:token.username forKey:(__bridge NSString*)kSecAttrAccount];
    [keychainItem setObject:str forKey:(__bridge NSString*)kSecValueData];
}
-(LAOAuthToken*)loadTokenFromKeychain{
    LAOAuthToken *token = nil;
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:self.securityDomain accessGroup:nil];
    [keychainItem setObject:self.securityDomain forKey: (id)kSecAttrService];
    NSString *json = [keychainItem objectForKey:(__bridge NSString*)kSecValueData];
    if(json != nil && json.length > 0){
        token = [[LAOAuthToken alloc] initWithData:[json dataUsingEncoding:NSUTF8StringEncoding]];
    }
    return token;
}
-(void)clearTokenFromKeychain{
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:self.securityDomain accessGroup:nil];
    [keychainItem setObject:self.securityDomain forKey: (id)kSecAttrService];
    [keychainItem resetKeychainItem];
}

@end
