//
//  NSString+LAAdditions.m
//  LightAPIClient
//
//  Created by Developer iOS on 7/10/13.
//  Copyright (c) 2013 BitBlox. All rights reserved.
//

#import "NSString+LAAdditions.h"

@interface XMLParser : NSObject<NSXMLParserDelegate> {
@private
    NSMutableArray* strings;
}
- (NSString*)getCharsFound;
@end

@implementation XMLParser
- (id)init {
    if((self = [super init])) {
        strings = [[NSMutableArray alloc] init];
    }
    return self;
}
- (void)parser:(NSXMLParser*)parser foundCharacters:(NSString*)string {
    [strings addObject:string];
}
- (NSString*)getCharsFound {
    return [strings componentsJoinedByString:@""];
}
@end

@implementation NSString(LAAdditions)

- (NSString*)stripHtml {
    // take this string obj and wrap it in a root element to ensure only a single root element exists
    // and that any ampersands are escaped to preserve the escaped sequences
    NSString* string = [self stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    string = [NSString stringWithFormat:@"<root>%@</root>", string];
    
    // add the string to the xml parser
    NSStringEncoding encoding = string.fastestEncoding;
    NSData* data = [string dataUsingEncoding:encoding];
    NSXMLParser* parser = [[NSXMLParser alloc] initWithData:data];
    
    // parse the content keeping track of any chars found outside tags (this will be the stripped content)
    XMLParser* parsee = [[XMLParser alloc] init];
    parser.delegate = parsee;
    [parser parse];
    
    // any chars found while parsing are the stripped content
    NSString* strippedString = [parsee getCharsFound];
    
    // get the raw text out of the parsee after parsing, and return it
    return strippedString;
}

@end
  
