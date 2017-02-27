//
//  NSDate+LAAdditions.m
//  LightAPIClient
//
//  Created by Seth Jordan on 7/10/13.
//  Copyright (c) 2013 SourceGroove. All rights reserved.
//

#import "NSDate+LAAdditions.h"

static NSString *ISO_8601_DATE = @"yyyy-MM-dd";
static NSString *ISO_8601_DATE_WITH_TIME = @"yyyy-MM-dd'T'HH:mm:ssZ";
static NSString *ISO_8601_DATE_WITH_TIME_AND_MILLIS = @"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ";

@implementation NSDate(LAAdditions)

-(NSString*)toISO8601{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:self];
    NSInteger hour = [components hour];
    if (hour > 0) {
        [format setDateFormat:ISO_8601_DATE_WITH_TIME_AND_MILLIS];
    } else {
        [format setDateFormat:ISO_8601_DATE];
    }
    
    return [format stringFromDate:self];
}

+(NSDate*)dateWithObject:(id)object{
    if([object isKindOfClass:[NSString class]]){
        return [NSDate dateWithISOString:object];
    } else if ([object isKindOfClass:[NSNumber class]]){
        NSNumber *millis = (NSNumber*)object;
        return [self dateWithTimeSinceEpoch:millis];
    }
    
    NSLog(@"I don't know how to parse %@ objects", [object class]);
    return nil;
}


+(NSDate*)dateWithTimeSinceEpochString:(NSString*)milliseconds{
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterNoStyle];
    NSNumber *millis = [f numberFromString:milliseconds];
    
    return [self dateWithTimeSinceEpoch:millis];
}

+(NSDate*)dateWithTimeSinceEpoch:(NSNumber*)milliseconds{
    double millis = [milliseconds doubleValue];
    double seconds = millis / 1000;
    
    return [NSDate dateWithTimeIntervalSince1970:seconds];
}

-(NSNumber*)toTimeSince1970{
    NSTimeInterval secondsSinceEpoch = [self timeIntervalSince1970];
    double millisSinceEpoch = secondsSinceEpoch * 1000;
    return [NSNumber numberWithDouble:millisSinceEpoch];
}
+(NSDate*)dateWithISOString:(NSString *)str{
    if(str.length == 0){
        return nil;
    }
    
    NSString *f = nil;
    
    if(str.length == ISO_8601_DATE.length){
        f = ISO_8601_DATE;
        
    } else if([str containsString:@"."]){
        f = ISO_8601_DATE_WITH_TIME_AND_MILLIS;
        
    } else {
        f = ISO_8601_DATE_WITH_TIME;
    }
    
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [format setDateFormat:f];
    NSDate *d = [format dateFromString:str];
    
    if(d == nil){
        NSLog(@"Warning: unable to parse string '%@' to date using format %@, %@ or %@",
              str, ISO_8601_DATE, ISO_8601_DATE_WITH_TIME, ISO_8601_DATE_WITH_TIME_AND_MILLIS);
    }
    
    return d;
}

@end
