//
//  LABasicAuthClient.h
//  LightApiClient
//
//  Created by Seth Jordan on 6/13/13.
//  Copyright (c) 2013 SourceGroove. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LASecurityProvider.h"

@interface LABasicAuthProvider : NSObject<LASecurityProvider>

/*!
 @function initWithDomain:
 @abstract Initializes the client with the a security domain that will be used to store credentials
 @param securityDomain
 The security domain for this client is a string that will be used to store tokens on the device.
 It will allow you to run multiple client instances who can keep their data separate.
 If this is the same as other clients in memory, you will have issues where you will overwrite each other's data.
 @return a pointer to the client.
 */
-(id)initWithDomain:(NSString*)securityDomain;

@end
