//
//  LAFileCacheBase.m
//  LightAPIClient
//
//  Created by Seth Jordan on 7/10/13.
//  Copyright (c) 2013 SourceGroove. All rights reserved.
//

#import "LAFileCacheProvider.h"

static NSString *CacheItemLifetimesKey = @"com.sourcegroove.cache.Lifetimes";

@interface LAFileCacheProvider()
@property (nonatomic, retain) NSMutableDictionary *cacheItemLifetimes;
@end

@implementation LAFileCacheProvider

-(id)init{
    self = [super init];
    if(self){

    }
    return self;
}
-(void)clear{
    NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error = nil;
    for (NSString *fileName in [fileManager contentsOfDirectoryAtPath:cacheDirectory error:&error]){
        [fileManager removeItemAtPath:[cacheDirectory stringByAppendingPathComponent:fileName] error:&error];
    }
}
-(NSMutableDictionary*)cacheItemLifetimes{
    if(_cacheItemLifetimes == nil){
        _cacheItemLifetimes = [[[NSUserDefaults standardUserDefaults] objectForKey:CacheItemLifetimesKey] mutableCopy];
    }
    
    if(_cacheItemLifetimes == nil){
        _cacheItemLifetimes = [NSMutableDictionary dictionary];
    }
    
    return _cacheItemLifetimes;
}

-(void)cacheData:(NSData *)data withKey:(NSString *)key lifetime:(NSTimeInterval)lifetime{
    NSString *filename = [self filenameWithKey:key];
    if(data != nil && ![[NSFileManager defaultManager] fileExistsAtPath:filename]){
        // create it if it's not there
        [[NSFileManager defaultManager] createFileAtPath:filename contents:data attributes:nil];
        [self setLifetime:lifetime forFilename:filename];
        
    } else {
        //replace it (or delete it if data is nil)
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:filename error:&error];
        if(error){
            NSLog(@"Error deleting cached object at path %@ - %@", filename, error);
        }
        
        if(data != nil){
            [[NSFileManager defaultManager] createFileAtPath:filename contents:data attributes:nil];
            [self setLifetime:lifetime forFilename:filename];
        }
    }
}

-(NSData*)dataWithKey:(NSString *)key{
    NSString *filename = [self filenameWithKey:key];
    
    NSData *data = nil;
    if([[NSFileManager defaultManager] fileExistsAtPath:filename] && ![self isExpiredWithFilename:filename]) {
        data = [[NSData alloc] initWithContentsOfFile:filename];
        
    } else if ([[NSFileManager defaultManager] fileExistsAtPath:filename] && [self isExpiredWithFilename:filename]){
        //it's expired, remove it
        [self cacheData:nil withKey:key lifetime:0];
    }
    
    return data;
}

-(BOOL)isExpiredWithFilename:(NSString*)filename{
    NSError *error;
    NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:filename error:&error];
    if(error){
        NSLog(@"Error getting attributes for file %@", filename);
    }
    NSDate *created = [attr objectForKey:NSFileCreationDate];
    NSTimeInterval age = [[NSDate date] timeIntervalSinceDate:created];
    NSTimeInterval lifetime = [self lifetimeWithFilename:filename];
    
    return (age >= lifetime);
}

-(NSString*)filenameWithKey:(NSString*)key{
    NSString *path = [key stringByReplacingOccurrencesOfString:@"://" withString:@"_"];
    NSString *filename = [path stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    
    NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *uniquePath = [cacheDirectory stringByAppendingPathComponent:filename];
    
    //NSLog(@"PATH: %@", uniquePath);
    return  uniquePath;
}

-(void)setLifetime:(NSTimeInterval)lifetime forFilename:(NSString*)filename{
    [self.cacheItemLifetimes setObject:[NSNumber numberWithDouble:lifetime] forKey:filename];
    [[NSUserDefaults standardUserDefaults] setObject:self.cacheItemLifetimes forKey:CacheItemLifetimesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
-(NSTimeInterval)lifetimeWithFilename:(NSString*)filename{
    NSNumber *interval = [self.cacheItemLifetimes objectForKey:filename];
    return interval.doubleValue;
}

@end
