//
//  LAOAuthClient.h
//  LightAPIClient
//
//  Created by Seth Jordan on 7/10/13.
//  Copyright (c) 2013 SourceGroove. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LAOAuthProvider.h"
#import "LAOAuthToken.h"

/*
 Default Oauth Header format for the Oauth Provider.
 */
static  NSString * const DEFAULT_OAUTH_HEADER_FORMAT = @"Bearer %@";

@interface LASimpleOAuthProvider : NSObject<LAOAuthProvider>
@property (strong)NSString *oauthHeaderFormat;

@end
