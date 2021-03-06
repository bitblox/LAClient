//
//  NSError+LAAdditions.m
//  LightAPIClient
//
//  Created by Developer iOS on 7/10/13.
//  Copyright (c) 2013 BitBlox. All rights reserved.
//

#import "NSError+LAAdditions.h"

@implementation NSError(LAAdditions)

+(NSError*)errorWithMessage:(NSString*)message code:(long)code{
    if(message == nil){
        message = @"";
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:message forKey:NSLocalizedDescriptionKey];
    
    return [NSError errorWithDomain:LAClientErrroDomain
                               code:code
                           userInfo:dict];
}

@end
