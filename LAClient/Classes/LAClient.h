//
//  LAClient.h
//  LightApiClient
//
//  See also: https://github.com/SourceGroove/LightAPIClient
//
//  This client encapsulates all interaction with a REST api.  This client should be initialized with
//  the appropriate information when the application is launched.
//
//  If your application is an OAuth enabled app, be on the lookout for the 'LAClientLoginErrorCode'
//     which will be thrown from API calls when there is either no OAuth token or it is invalid for some
//     reason.  When this happens, you need to login your user via the loginUser:password:callback: method.
//
//  Created by Seth Jordan on 6/13/13.
//  Copyright (c) 2013 SourceGroove. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "LAJsonRepresentation.h"
#import "LAOAuthProvider.h"

/*
 This callback is returned by all API calls.
 
 Note: If using a SecurityClient, then you need to inspect the error for a failed refresh and
    present your users with a login screen.  To do this, do the following:
    if(error != nil && error.code == LAClientLoginErrorCode){
        //throw a login screen.
    }
 
    This will happen from time to time (specificaly with OAuth) if the server looses it's state information
    or if you switch servers without clearing the app's local state.  For example, it could present
    a refresh token from an old OAuth server to a new one.
 */
typedef void (^ LAClientRequestCallback)(id resource, NSHTTPURLResponse* response, NSError* error);

@interface LAClient : NSObject

#pragma mark -
#pragma mark Creation
#pragma mark -
/*!
 @function intiWithURL:
 @abstract Initializes the manager with the base url of the API it will be interacting with
 @param url
    The base url of the API
 @return a pointer to the manager. 
 */
-(id)initWithURL:(NSURL*)url;

#pragma mark -
#pragma mark Config Properties
#pragma mark -
@property (strong) id<LASecurityProvider> securityProvider;
@property (strong) NSString *connectionUserAgent;
@property int connectionTimeoutInSeconds;
@property NSURLRequestCachePolicy cachePolicy;
@property BOOL debugEnabled;

@property (readonly) NSURL *baseUrl;

#pragma mark -
#pragma mark API calls
#pragma mark -
-(void)getResource:(Class)clazz atPath:(NSString*)path callback:(LAClientRequestCallback)callback;
-(void)getResource:(Class)clazz atURL:(NSURL*)url callback:(LAClientRequestCallback)callback;
-(void)getResourceList:(Class)clazz atPath:(NSString*)path callback:(LAClientRequestCallback)callback;
-(void)getResourceList:(Class)clazz atURL:(NSURL*)url callback:(LAClientRequestCallback)callback;

-(void)deleteResourceAtPath:(NSString*)path callback:(LAClientRequestCallback)callback;
-(void)deleteResourceAtURL:(NSURL*)url callback:(LAClientRequestCallback)callback;

-(void)putResource:(id<LARepresentation>)resource atPath:(NSString*)path callback:(LAClientRequestCallback)callback;
-(void)putResource:(id<LARepresentation>)resource atURL:(NSURL*)url callback:(LAClientRequestCallback)callback;

-(void)postResource:(id<LARepresentation>)resource atPath:(NSString*)path callback:(LAClientRequestCallback)callback;
-(void)postResource:(id<LARepresentation>)resource atURL:(NSURL*)url callback:(LAClientRequestCallback)callback;

-(void)headResourceAtPath:(NSString*)path callback:(LAClientRequestCallback)callback;
-(void)headResourceAtURL:(NSURL*)url callback:(LAClientRequestCallback)callback;

/*
 These two api calls can be used to get representations from the server that you
 do not want deserialized to an LARepresentation. It bypasses the deserialization
 sequence and returns the raw NSData returned from the API call.
 
 These should rarely be needed and if you do need to use them, let me know why 
 so we can improve the client.
 */
-(void)getResourceAtPath:(NSString*)path callback:(LAClientRequestCallback)callback;
-(void)getResourceAtURL:(NSURL*)url callback:(LAClientRequestCallback)callback;

-(void)killAllRequests;

#pragma mark -
#pragma mark Security calls
#pragma mark -
/*!
 @function requiresLogin
 @abstract Determines if the security infrastructure requires a login and if so, 
    if the user needs to login
 @return TRUE if the client requires a login.
 */
-(BOOL)requiresLogin;

/*!
 @function loginUser:::
 @abstract Logs the user in
 */
-(void)loginUser:(NSString*)username
        password:(NSString*)password
         callback:(void(^)(NSString* username, NSError *error))callback;

/*!
 @function logout
 @abstract Logs the user out
 */
-(void)logout;

/*!
 @function currentUser
 @abstract Gets the current user name of the user who's logged in
 @return The user name or nil if no one is logged in
 */
-(NSString*)currentUser;

@end
