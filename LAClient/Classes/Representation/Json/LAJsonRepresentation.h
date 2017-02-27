//
//  LAJsonRepresentation.h
//  LightAPIClient
//
//  Created by Seth Jordan on 7/10/13.
//  Copyright (c) 2013 SourceGroove. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LAAbstractJsonRepresentation.h"
#import "LAJsonLink.h"

@interface LAJsonRepresentation : LAAbstractJsonRepresentation

@property (nonatomic, retain) NSArray *links;

-(LAJsonLink*)selfLink;
-(LAJsonLink*)linkWithRef:(NSString*)ref;
@end
