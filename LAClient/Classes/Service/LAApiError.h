//
//  LAApiError.h
//  LightAPIClient
//
//  Created by Developer iOS on 7/10/13.
//  Copyright (c) 2013 BitBlox. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "LAJsonRepresentation.h"

@interface LAApiError : LAJsonRepresentation

@property(strong) NSString *title;
@property(nonatomic, retain) NSArray *messages;
@property NSInteger statusCode;

+(id)errorWithTitle:(NSString*)title
           messages:(NSArray*)messages
         statusCode:(NSInteger)statusCode;

@end
