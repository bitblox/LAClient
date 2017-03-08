//
//  LARepresentation.h
//  LightApiClient
//
//  Created by Developer iOS on 6/13/13.
//  Copyright (c) 2013 BitBlox. All rights reserved.
//
#import <Foundation/Foundation.h>

@protocol LARepresentation <NSObject>

/*
 Creates an array of typed representations with
 the provided data (typically the response payload
 of an HTTP request)
 */
+(NSArray*) arrayWithData:(NSData*)data;

/*
  Creates data from an array.
 */
+(NSData*) dataWithArray:(NSArray*)array;

/*
 Creates an instance of a typed representation with
 the provided data (typically the response payload
 of an HTTP request)
 */
-(id)initWithData:(NSData*)data;

/*
 Serializes the typed entry to data.
 This is typically used to POST/PUT data
 back to an HTTP resource.
 */
-(NSData*)toData;

@end
