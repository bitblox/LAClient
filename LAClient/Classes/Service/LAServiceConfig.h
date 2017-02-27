//
//  LAServiceConfig.h
//  LightAPIClient
//
//  Created by Seth Jordan on 7/10/13.
//  Copyright (c) 2013 SourceGroove. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LAServiceConfig : NSObject
@property NSString *apiUri;
@property NSString *oauthUri;
@property NSString *oauthClientId;
@property NSString *oauthClientSecret;
@property NSString *oauthHeaderFormat;
@end
