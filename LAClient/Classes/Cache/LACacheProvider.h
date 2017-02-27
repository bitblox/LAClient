//
//  LACacheProvider.h
//  LightAPIClient
//
//  Created by Seth Jordan on 7/10/13.
//  Copyright (c) 2013 SourceGroove. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LACacheProvider <NSObject>

-(void)cacheData:(NSData*)data withKey:(NSString*)key lifetime:(NSTimeInterval)lifetime;
-(NSData*)dataWithKey:(NSString*)key;
-(void)clear;

@end
