//
//  LAOAuthToken.h
//  LightApiClient
//
//  Object representing an OAuth token issued by an OAuth server.
//
//  Created by Developer iOS on 6/13/13.
//  Copyright (c) 2013 BitBlox. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "LAJsonRepresentation.h"

@interface LAOAuthToken : LAJsonRepresentation

@property(strong) NSString* token_type;
@property(strong) NSString* access_token;
@property(strong) NSString* refresh_token;
@property(strong) NSString* expires_in;
@property(strong) NSDate* issued;
@property(strong) NSString* error;
@property(strong) NSString* error_description;
@property(strong) NSString* username;

-(bool)isExpired;
-(bool)isValid;



@end
