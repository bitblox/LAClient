//
//  LAJsonRepresentation.m
//  LightAPIClient
//
//  Created by Developer iOS on 7/10/13.
//  Copyright (c) 2013 BitBlox. All rights reserved.
//

#import "LAJsonRepresentation.h"

@interface LAJsonRepresentation()
@end

@implementation LAJsonRepresentation
@synthesize links = _links;

-(NSArray*)links{
    if(_links == nil){
        _links = @[];
    }
    return _links;
}
-(void)setLinks:(NSArray *)links{
    _links = [self typedArrayWithType:[LAJsonLink class] value:links];
}

-(LAJsonLink*)selfLink{
    return [self linkWithRef:@"self"];
}
-(LAJsonLink*)linkWithRef:(NSString*)ref{
    LAJsonLink *l = nil;
    for(LAJsonLink *link in self.links){
        if([[link.rel lowercaseString] isEqualToString:[ref lowercaseString]]){
            l = link;
            break;
        }
    }
    
    return l;
}

-(BOOL)isEqual:(id)object{
    if(![object isKindOfClass:[self class]]){
        return FALSE;
    } else {
        LAJsonLink *mine = [self linkWithRef:@"self"];
        LAJsonLink *other = [object linkWithRef:@"self"];
        return [mine.href isEqualToString:other.href];
    }
}

@end
