//
//  NSDate+LAAdditions.h
//  LightAPIClient
//
//  Created by Developer iOS on 7/10/13.
//  Copyright (c) 2013 BitBlox. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate(LAAdditions)

+(NSDate*)dateWithObject:(id)object;
-(NSString*)toISO8601;
-(NSNumber*)toTimeSince1970;

@end
