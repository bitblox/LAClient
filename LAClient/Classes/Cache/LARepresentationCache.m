//
//  LARepresentationCache.m
//  LightAPIClient
//
//  Created by Developer iOS on 7/10/13.
//  Copyright (c) 2013 BitBlox. All rights reserved.
//

#import "LARepresentationCache.h"

NSString *CachePrefix = @"la.cache.";

@interface LARepresentationCache()
@property (nonatomic, retain) NSMutableDictionary *memoryCache;
@end

@implementation LARepresentationCache

-(id)init{
    self = [super init];
    if(self){
        self.memoryCache = [NSMutableDictionary dictionary];
    }
    return  self;
}

-(void)clearInMemoryOnly{
    self.memoryCache = [NSMutableDictionary dictionary];
}
-(void)clear{
    [self clearInMemoryOnly];
    NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
    NSDictionary * dict = [defs dictionaryRepresentation];
    for(id key in dict) {
        if([key hasPrefix:CachePrefix]){
            [defs removeObjectForKey:key];
        }
    }
    [defs synchronize];
}



#pragma mark -
#pragma mark Private helpers
#pragma mark -

#pragma mark - Object serialization
-(void)setObject:(id)object class:(Class)clazz forKey:(NSString*)key{
    if(![self isCacheableClass:clazz]){
        return;
    }
    
    NSString *json = nil;
    if([object isKindOfClass:[NSArray class]]){
        NSArray *array = (NSArray*)object;
        if(array.count > 0){
            json = [self jsonFromArray:array];
        }
    } else {
        json = [[NSString alloc] initWithData:[object toData] encoding:NSUTF8StringEncoding];
    }
    
    NSString *persistentString = [self persistentStringWithClass:clazz json:json];
    if(persistentString.length > 0){
        //udpate it
        [self.memoryCache setObject:persistentString forKey:key];
        if(![clazz inMemoryCacheOnly]){
            [self persistString:persistentString key:key];
        }
    } else {
        //delete it
        [self.memoryCache removeObjectForKey:key];
        if(![clazz inMemoryCacheOnly]){
            [self deletePersistentStringForKey:key];
        }
    }
}
-(id)objectWithClass:(Class)clazz key:(NSString*)key list:(BOOL)list{
    if(![self isCacheableClass:clazz]){
        return nil;
    }
    
    NSString *persistentString = [self.memoryCache objectForKey:key];
    if(persistentString == nil){
        persistentString = [self loadStringWithKey:key];
        //add to cache in case this is the first launch of the app so we're in synch
        if(persistentString != nil){
            [self.memoryCache setObject:persistentString forKey:key];
        }
    }
    
    id obj = nil;
    if(persistentString.length > 0){
        NSString *json = [self jsonWithPersistentString:persistentString];
        if(json.length > 0){
            if(list){
                obj = [clazz arrayWithData:[json dataUsingEncoding:NSUTF8StringEncoding]];
            } else {
                obj = [[clazz alloc] initWithString:json];
            }
        }
    }
    return obj;
}

#pragma mark - Persistent string stuff (this is where expiration happens)
-(NSString*)persistentStringWithClass:(Class)clazz json:(NSString*)json{
    if(json.length == 0){
        return nil;
    }
    
    
    NSTimeInterval expires = [clazz cacheLifetimeInSeconds] + [[NSDate date] timeIntervalSince1970];
    
    return [NSString stringWithFormat:@"%@::%f::%@", clazz, expires, json];
}
-(NSString*)jsonWithPersistentString:(NSString*)persistenString{
    if(persistenString.length == 0){
        return nil;
    }
    
    NSArray *components = [persistenString componentsSeparatedByString:@"::"];
    if(components.count != 3){
        NSLog(@"Invalid cache entry, not returing it: %@", components);
        return nil;
    }
    
    NSTimeInterval expires = [[components objectAtIndex:1] doubleValue];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    
    if(expires > now){
        return [components objectAtIndex:2];
    } else {
        //NSLog(@"Class %@ expired, so returning nil", [components objectAtIndex:0]);
        return nil;
    }
}

#pragma mark - User defaults stuff
-(NSString*)loadStringWithKey:(NSString*)key{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}
-(void)persistString:(NSString*)string key:(NSString*)key{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:string forKey:key];
    [userDefaults synchronize];
}
-(void)deletePersistentStringForKey:(NSString*)key{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:key];
    [userDefaults synchronize];
}
-(BOOL)isCacheableClass:(Class)clazz{
    if([clazz conformsToProtocol:@protocol(LARepresentation)]
       && [clazz conformsToProtocol:@protocol(LACacheable)]){
        return TRUE;
    } else {
        NSLog(@"Class %@ doesn't conform to LAResource and Cacheable protocols - we can't cache it.", clazz);
        return FALSE;
    }
}

#pragma mark - misc
-(NSString*)jsonFromArray:(NSArray*)array{
    NSMutableString *json = [NSMutableString string];
    [json appendString:@"["];
    
    NSInteger count = 0;
    for(id item in array){
        count++;
        if(item != nil && [item respondsToSelector:NSSelectorFromString(@"toString")]){
            NSString *string = [[NSString alloc] initWithData:[item toData] encoding:NSUTF8StringEncoding];
            if(string.length > 0){
                [json appendString:string];
                if(count < array.count){
                    [json appendString:@","];
                }
            }
        } else {
            NSLog(@"Item does not respond to toString %@", [item class]);
        }
    }
    [json appendString:@"]"];
    
    return json;
}







@end
