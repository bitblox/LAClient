//
//  LARepresentationCache.h
//  LightAPIClient
//
//  Created by Seth Jordan on 7/10/13.
//  Copyright (c) 2013 SourceGroove. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LARepresentation.h"
#import "LACacheable.h"

@interface LARepresentationCache : NSObject

-(void)clear;
-(void)clearInMemoryOnly;

-(void)setObject:(id)object class:(Class)clazz forKey:(NSString*)key;
-(id)objectWithClass:(Class)clazz key:(NSString*)key list:(BOOL)list;
@end
