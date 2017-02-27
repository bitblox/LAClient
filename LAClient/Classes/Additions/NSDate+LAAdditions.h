//
//  NSDate+LAAdditions.h
//  LightAPIClient
//
//  Created by Seth Jordan on 7/10/13.
//  Copyright (c) 2013 SourceGroove. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate(LAAdditions)

+(NSDate*)dateWithObject:(id)object;
-(NSString*)toISO8601;
-(NSNumber*)toTimeSince1970;

@end
