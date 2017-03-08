//
//  LAJsonRepresentation.h
//  LightAPIClient
//
//  Created by Developer iOS on 7/10/13.
//  Copyright (c) 2013 BitBlox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LAAbstractJsonRepresentation.h"
#import "LAJsonLink.h"

@interface LAJsonRepresentation : LAAbstractJsonRepresentation

@property (nonatomic, retain) NSArray *links;

-(LAJsonLink*)selfLink;
-(LAJsonLink*)linkWithRef:(NSString*)ref;
@end
