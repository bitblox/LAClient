//
//  LAJsonLink.h
//  LightAPIClient
//
//  Created by Seth Jordan on 7/10/13.
//  Copyright (c) 2013 SourceGroove. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LAAbstractJsonRepresentation.h"

@interface LAJsonLink : LAAbstractJsonRepresentation
@property (nonatomic, retain) NSString *rel;
@property (nonatomic, retain) NSString *path;
-(NSURL*)url;
-(NSString*)href;
@end
