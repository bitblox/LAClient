//
//  LAAbstractJsonRepresentation.h
//  LightAPIClient
//
//  Created by Developer iOS on 7/10/13.
//  Copyright (c) 2013 BitBlox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LARepresentation.h"

@interface LAAbstractJsonRepresentation : NSObject<LARepresentation>

-(NSArray*)typedArrayWithType:(Class)clazz value:(id)value;

-(id)initWithDictionary:(NSDictionary*)dictionary;
-(NSDictionary*)toDictionary;

//Set this if you want custom date formatting during serialization
@property (nonatomic, retain) NSDateFormatter *dateformatter;

@end
