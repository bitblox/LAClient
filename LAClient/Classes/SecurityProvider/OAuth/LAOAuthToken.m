//
//  LAOAuthToken.m
//  LightApiClient
//
//  Created by Developer iOS on 6/13/13.
//  Copyright (c) 2013 BitBlox. All rights reserved.
//
#import "LAOAuthToken.h"

@implementation LAOAuthToken

/*
 This value represents the lag that may exist between the time the token was issued by the OAuth server and the
 time we receive it.  We are essentially shortening the token life by this lenght to ensure we don't use expired
 tokens.
*/
double NETWORK_TIME_LAG_IN_SECONDS = 10;

#pragma mark -
#pragma mark Creational
#pragma mark -
-(id)init{
    self = [super init];
    if(self != nil && self.issued == nil){
        self.issued = [NSDate date];
    }
    return self;
}
-(id)initWithDictionary:(NSDictionary *)dictionary{
    self = [super initWithDictionary:dictionary];
    if(self != nil && self.issued == nil){
            self.issued = [NSDate date];
    }
    return self;
}

-(id)initWithData:(NSData *)data{
    self = [super initWithData:data];
    if(self != nil && self.issued == nil){
        self.issued = [NSDate date];
    }
    return self;
}

#pragma mark -
#pragma mark Public
#pragma mark -
-(bool) isValid{
    bool v= (self.access_token.length > 0
             && self.refresh_token.length > 0
             && ![self isExpired]);
    
    return v;
}

-(bool)isExpired{
    double lifeSpan = [self.expires_in doubleValue] - NETWORK_TIME_LAG_IN_SECONDS;
    NSDate* expirationDate = [self.issued dateByAddingTimeInterval:lifeSpan];
    NSDate* now = [NSDate date];

    NSComparisonResult result = [expirationDate compare:now];
    if(result == NSOrderedDescending || result == NSOrderedSame){
        return FALSE;
    } else {
        return TRUE;
    }
}

@end
