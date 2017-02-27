//
//  Cacheable.h
//  LightAPIClient
//
//  Created by Seth Jordan on 7/10/13.
//  Copyright (c) 2013 SourceGroove. All rights reserved.
//


#import <Foundation/Foundation.h>

static const NSInteger LACacheableSecondsInMinute = 60;
static const NSInteger LACacheableSecondsInFiveMinutes = 60*5;
static const NSInteger LACacheableSecondsInHour = 60*60;
static const NSInteger LACacheableSecondsInDay = 60*60*24;
static const NSInteger LACacheableSecondsInWeek = 60*60*24*7;
static const NSInteger LACacheableSecondsInMonth = 60*60*24*7*4;
static const NSInteger LACacheableSecondsInYear = 60*60*24*7*4*12;
static const NSInteger LACacheableSecondsInDecade = 60*60*24*7*4*12*10;

@protocol LACacheable <NSObject>

+(BOOL)inMemoryCacheOnly;
+(NSInteger)cacheLifetimeInSeconds;
@end