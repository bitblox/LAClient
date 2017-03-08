//
//  LAOAuthProvider.h
//  LightApiClient
//
//  Created by Developer iOS on 8/3/13.
//  Copyright (c) 2013 BitBlox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LASecurityProvider.h"
#import "LAOAuthToken.h"


/* Error code that indicates a hard error occured while trying to login or refresh a users' credentials.  This
 error code should trigger the user to log in again.
 */
static int const LAClientLoginErrorCode = 666;

/* Error code that indicates a refresh of a user's credentials has failed because they are currently being refreshed.
 This error code should trigger the caller to try again.
 */
static int const LAClientRefreshInProgressErrorCode = 667;

@protocol LAOAuthProvider <NSObject, LASecurityProvider>

@property (nonatomic, retain) LAOAuthToken *token;

/*!
 @function intiWithURL: clientID: clientSecret:
 @abstract Initializes the client with the base url of the oauth server it will be interacting with.
 @param url
 The url of the OAuth authorization endpoint where token grants and refreshes will occur
 @param securityDomain
 The security domain for this oauth client is a string that will be used to store tokens on the device. 
 It will allow you to run multiple LAOAuthClient instances who can keep their tokens 
 separate.
 If this is the same as other oauth clients in memory, you will have token refresh issues or 
 you will be overwriting each other's tokens.
 @param clientId
 The client id representing this client in an OAuth token action
 @param clientSecret
 The client secret for the client id that represents this client in an OAuth token action
 @return a pointer to the client.
 */
-(id)initWithURL:(NSURL *)url
   securityDomain:(NSString*)securityDomain
        clientId:(NSString*)clientId
    clientSecret:(NSString*)clientSecret;

/*!
 @function getTokenForUsername: password:
 @abstract gets a token for the provided username and password
 @param username the username of the user to be authenticated
 @param password the password for the user
 */
-(void)getTokenForUsername:(NSString*)username
                  password:(NSString*)password
        completionCallback:(void(^)(LAOAuthToken* token))completionCallback
             errorCallback:(void(^)(NSError *error))errorCallback;

/*!
 @function refreshTokenToQueue: complectionCallback: errorCallback:
 @abstract refreshes the stored oauth token on the provided NSOperationQueue
 @param queue the NSOperationQueue to run the refresh call on
 @param completionCallback the callback to call when the refresh was successfull
 @param errorCallback the callback to call when the refresh failed
 */
-(void)refreshTokenToQueue:(NSOperationQueue*)queue
        completionCallback:(void (^)(LAOAuthToken *token))completionCallback
             errorCallback:(void (^)(NSError *error))errorCallback;




@end
