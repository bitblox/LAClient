//
//  LASecurityClient.h
//  LightApiClient
//
//  Created by Seth Jordan on 6/13/13.
//  Copyright (c) 2013 SourceGroove. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol LASecurityProvider <NSObject>

/*!
 @function secureRequest:
 @abstract secures the provided request.
 @param request the request to secure
 */
-(void)secureRequest:(NSMutableURLRequest*)request;

/*!
 @function loginUser:username:password:callback
 @abstract Logs a user in with a username/password
 @param username username
 @param password password
 @param callback the completion callback
 */
-(void)loginUser:(NSString*)username
        password:(NSString*)password
        callback:(void(^)(NSString* username, NSError *error))callback;


/*!
 @function logout
 @abstract Logs a user out
 */
-(void)logout;

/*!
 @function loginUser:username:password:callback
 @abstract Logs a user in with a username/password
 @param username username
 @param password password
 @param callback the completion callback
 */
-(void)refreshCredentialToQueue:(NSOperationQueue*)queue
             completionCallback:(void(^)(NSString* username, NSError *error))callback;


-(BOOL)requiresLogin;
-(BOOL)requiresRefresh;

-(NSString*)currentUser;


@end
