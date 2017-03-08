//
//  LAJsonLink.m
//  LightAPIClient
//
//  Created by Developer iOS on 7/10/13.
//  Copyright (c) 2013 BitBlox. All rights reserved.
//

#import "LAJsonLink.h"

@implementation LAJsonLink
-(NSURL*)url{
   return [NSURL URLWithString:self.path];
}
-(NSString*)href{
    return self.path;
}

@end
