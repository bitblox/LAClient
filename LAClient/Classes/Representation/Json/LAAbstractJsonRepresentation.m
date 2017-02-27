//
//  LAAbstractJsonRepresentation.m
//  LightAPIClient
//
//  Created by Seth Jordan on 7/10/13.
//  Copyright (c) 2013 SourceGroove. All rights reserved.
//

#import "LAAbstractJsonRepresentation.h"
#import <objc/runtime.h>
#import "NSDate+LAAdditions.h"
#import "NSString+LAAdditions.h"

@implementation LAAbstractJsonRepresentation

#pragma mark -
#pragma mark - LAResource implementataion
#pragma mark -


+(NSArray*) arrayWithString:(NSString*)json{
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    return [self arrayWithData:data];
}
+(NSArray*) arrayWithData:(NSData*)data{
    if(data == nil){
        return nil;
    }
    NSMutableArray *list = [[NSMutableArray alloc] init];
    for(NSDictionary *dict in [self parseJsonArray:data]){
        [list addObject:[[[self class] alloc] initWithDictionary:dict]];
    }
    
    return list;
}
+(NSData*) dataWithArray:(NSArray*)array{
    NSMutableArray *dicts = [NSMutableArray arrayWithCapacity:array.count];
    for(LAAbstractJsonRepresentation *rep in array){
        [dicts addObject:[rep toDictionary]];
    }
    
    NSError *parseError = nil;
    NSData* data = [NSJSONSerialization dataWithJSONObject:dicts
                                                   options:kNilOptions error:&parseError];
    
    if(parseError != nil){
        NSLog(@"Error converting to json: %@", [parseError localizedDescription]);
        return nil;
    }
    return data;
}

-(NSArray*)typedArrayWithType:(Class)clazz value:(id)value{
    NSMutableArray *list = [NSMutableArray array];
    if([value isKindOfClass:[NSString class]] && ((NSString*)value).length == 0){
        return nil;
    } else if([value isKindOfClass:[NSNull class]]){
        return  nil;
    } else if(![value isKindOfClass:[NSArray class]] && ![value isKindOfClass:[NSDictionary class]] && ![value isKindOfClass:clazz]){
        NSLog(@"Unable to deserialize value %@ '%@' because it is not an array", [value class], value);
        return nil;
    }
    for(id obj in value){
        if([obj isKindOfClass:[NSDictionary class]]){
            [list addObject:[[clazz alloc] initWithDictionary:obj]];
        } else if ([obj isKindOfClass:clazz]){
            [list addObject:obj];
        } else {
            NSLog(@"Unable to deserialize a %@ object to a typed entry: %@", [obj class], obj);
        }
    }
    return [NSArray arrayWithArray:list];
}

-(id)initWithData:(NSData*)data{
    NSParameterAssert(data);
    //NSLog(@"Creating %@ from (length=%d) %@", [self class],  data.length, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    if([super init]){
        
        if(data.length == 0){
            return nil;
        }
        
        NSError* error = nil;
        id object = [NSJSONSerialization JSONObjectWithData:data
                                                    options:kNilOptions
                                                      error:&error];
        if (error != nil){
            NSLog(@"Error creating %@ from '%@' %@", [self class],
                  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding],
                  [error localizedDescription]);
            return nil;
        }
        
        if([object isKindOfClass:[NSDictionary class]]){
            return [self initWithDictionary:object];
        }
        
    }
    
    NSLog(@"Unable to create %@ from json data %@, returning nil",
          [self class],
          [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    return nil;
}
-(NSData*) toData{
    NSDictionary *dict = [self toDictionary];
    if(![NSJSONSerialization isValidJSONObject:dict]){
        NSLog(@"%@ is not a valid JSON-serializable object. If it has custom properties, implement your own 'toDictionary' method.", [self class]);
        return nil;
    }
    NSError *parseError = nil;
    NSData* data = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:&parseError];
    
    if(parseError != nil){
        NSLog(@"Error converting to json: %@", [parseError localizedDescription]);
        return nil;
    }
    return data;
}
-(id)initWithString:(NSString*)string{
    return [self initWithData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}
-(NSString*) toString{
    return [[NSString alloc] initWithData:[self toData] encoding:NSUTF8StringEncoding];
}

#pragma mark -
#pragma mark - private
#pragma mark -
+(NSArray*) parseJsonArray:(NSData*)data{
    NSError* error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data
                                                options:kNilOptions
                                                  error:&error];
    if (error != nil){
        NSLog(@"Error: %@ - %@", [error localizedDescription], error);
        return nil;
    }
    
    if([object isKindOfClass:[NSArray class]]){
        return (NSArray*)object;
    } else {
        NSLog(@"Error: data was not an array: %@",
              [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        return nil;
    }
}

-(id)initWithDictionary:(NSDictionary*)dictionary{
    if([dictionary isKindOfClass:[NSDictionary class]]){
        
        for(NSString *key in dictionary){
            id value = [dictionary objectForKey:key];
            if([self isSetterForProperty:key] && value != nil){
                [self value:value forPropertyName:key];
                
            } else {
                if(![key isEqualToString:@"hash"] && ![key isEqualToString:@"description"] && ![key isEqualToString:@"debugDescription"]){
                    //NSLog(@"Dictionary contains key ('%@') that does not correspond to a property on the %@ object", key, [self class]);
                }
            }
        }
    }
    return self;
}

-(id)toDictionary{
    return [NSDictionary dictionaryWithDictionary:
            [self dictionaryForClass:[self class]]];
}

-(NSMutableDictionary*)dictionaryForClass:(Class)classType{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    Class superClass  = class_getSuperclass(classType);
    if  (superClass != nil && ![superClass isEqual:[NSObject class]]){
        [dict addEntriesFromDictionary:[self dictionaryForClass:superClass]];
    }
    
    unsigned int propertyCount;
    objc_property_t * propertyList = class_copyPropertyList(classType, &propertyCount);
    for (int i = propertyCount - 1; i >= 0; --i) {
        objc_property_t property = propertyList[i];
        
        const char *property_name = property_getName(property);
        NSString *propertyName = [NSString stringWithCString:property_name encoding:NSASCIIStringEncoding];
        
        if (propertyName && ![self isRootObjectProperty:propertyName]){
            id value = [self valueForKey:propertyName];
            
            //NSLog(@"PROPERTY NAME: %@ on %@ = %@", propertyName, classType, value);
            
            if(value == nil){
                value = @"";
            } else if ([value conformsToProtocol:@protocol(LARepresentation)]){
                value = [value toDictionary];
                
            } else if([value isKindOfClass:[NSString class]]){
                value = ((NSString*)value).length == 0 ? @"" : value;
                
            } else if([value isKindOfClass:[NSDate class]] && self.dateformatter != nil){
                value = [self.dateformatter stringFromDate:(NSDate*)value];

            } else if ([value isKindOfClass:[NSDate class]]) {
                value = [(NSDate*)value toISO8601];
                
            } else if ([value isKindOfClass:[NSArray class]]){
                //serialize array to json
                NSMutableArray *serializedArray = [NSMutableArray array];
                for(id obj in value){
                    if([obj respondsToSelector:NSSelectorFromString(@"toDictionary")]){
                        [serializedArray addObject:[obj toDictionary]];
                    } else {
                        [serializedArray addObject:obj];
                    }
                }
                value = serializedArray;
            }
            [dict setValue:value forKey:propertyName];
        }
    }
    free(propertyList);
    return dict;
}

-(BOOL)isRootObjectProperty:(NSString*)propertyName{
    return ([propertyName isEqualToString:@"debugDescription"]
            || [propertyName isEqualToString:@"hash"]
            || [propertyName isEqualToString:@"superclass"]
            || [propertyName isEqualToString:@"dateformatter"]
            );
}
-(void) value:(id)value forPropertyName:(NSString*)propertyName{
    Class propertyClass = [self classWithPropetyName:propertyName];
    
    if(propertyClass == [NSDate class] && self.dateformatter != nil && [value isKindOfClass:[NSString class]]){
        if(((NSString*)value).length > 0){
            NSDate *d = [self.dateformatter dateFromString:value];
            if(d != nil){
                [self setValue:d forKey:propertyName];
            }
        } else {
            NSLog(@"Unable to set %@ with value %@", propertyName, value);
        }
    } else if(propertyClass == [NSDate class]){
        [self setValue:[NSDate dateWithObject:value] forKey:propertyName];
        
    } else if ([propertyClass conformsToProtocol:@protocol(LARepresentation)]){
        id<LARepresentation> stronglyTypedValue = [[propertyClass alloc] initWithDictionary:value];
        [self setValue:stronglyTypedValue forKey:propertyName];
        
    } else {
        [self setValue:value forKey:propertyName];
    }
}

-(BOOL) isSetterForProperty:(NSString*)propertyName{
    NSString *propName = [propertyName stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                               withString:[[propertyName substringToIndex:1] uppercaseString]];
    NSString* setter = [NSString stringWithFormat:@"set%@:", propName];
    
    if([self respondsToSelector:NSSelectorFromString(setter)]){
        return TRUE;
    } else {
        return FALSE;
    }
    
}

-(Class)classWithPropetyName:(NSString*)propertyName{
    
    objc_property_t property = class_getProperty([self class], [propertyName UTF8String]);
    const char *attr = property_getAttributes(property);
    NSString *attributes = [NSString stringWithCString:attr encoding:NSUTF8StringEncoding];
    NSArray *attributeParts = [attributes componentsSeparatedByString:@"\""];
    
    Class clazz = [NSString class];
    NSString* attrTypeDescriptor = [attributeParts objectAtIndex:0];
    //NSLog(@"%@ property %@ type %@", [self class], propertyName, attributeParts);
    if([attrTypeDescriptor isEqualToString:@"T@"]){
        NSString *propertyTypeName = [attributeParts objectAtIndex:1];
        clazz = NSClassFromString(propertyTypeName);
        
    } else if([attrTypeDescriptor isEqualToString:@"Ti"]) {
        clazz = [NSNumber class];
    }
    
    return clazz;
}


@end
