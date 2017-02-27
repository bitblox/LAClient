//
//  NSError+LAAdditions.h
//  LightAPIClient
//
//  Created by Seth Jordan on 7/10/13.
//  Copyright (c) 2013 SourceGroove. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *LAClientErrroDomain = @"LAClient Error";

@interface NSError(LAAdditions)
+(NSError*)errorWithMessage:(NSString*)message code:(long)code;
@end
