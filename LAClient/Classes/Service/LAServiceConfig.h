//
//  LAServiceConfig.h
//  LightAPIClient
//
//  Created by Developer iOS on 7/10/13.
//  Copyright (c) 2013 BitBlox. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LAServiceConfig : NSObject
@property NSString *apiUri;
@property NSString *oauthUri;
@property NSString *oauthClientId;
@property NSString *oauthClientSecret;
@property NSString *oauthHeaderFormat;
@end
