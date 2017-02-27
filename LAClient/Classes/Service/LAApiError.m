//
//  LAApiError.m
//  LightAPIClient
//
//  Created by Seth Jordan on 7/10/13.
//  Copyright (c) 2013 SourceGroove. All rights reserved.
//


#import "LAApiError.h"

@implementation LAApiError

#pragma mark -
#pragma mark Property Overrides
#pragma mark -
-(void)setMessages:(NSArray *)messages{
    if(![messages isKindOfClass:[NSArray class]]
       && ![messages isKindOfClass:[NSString class]]){
        return;
    }
    if([messages isKindOfClass:[NSString class]]){
        _messages = [NSArray arrayWithObject:messages];
    } else {
        NSMutableArray *typedEntries = [[NSMutableArray alloc] init];
        for(id obj in messages){
            if([obj isKindOfClass:[NSString class]]){
                [typedEntries addObject:obj];
            } else {
                NSLog(@"Message items are of type %@", [obj class]);
            }
        }
        _messages = [NSArray arrayWithArray:typedEntries];
    }
}

+(id)errorWithTitle:(NSString*)title
           messages:(NSArray*)messages
         statusCode:(NSInteger)statusCode{
    LAApiError *error = [[LAApiError alloc] init];
    error.title = title;
    error.messages = messages;
    error.statusCode = statusCode;
    
    return error;
}
-(NSString*)description{
    return [self.messages componentsJoinedByString:@", "];
}
@end