//
//  LAClient.m
//  LightApiClient
//
//  Created by Developer iOS on 6/13/13.
//  Copyright (c) 2013 BitBlox. All rights reserved.
//
#import "LAClient.h"
#import <UIKit/UIKit.h>
#import "LAOAuthToken.h"
#import "NSError+LAAdditions.h"
#import "NSString+LAAdditions.h"

static int DEFAULT_CONNECTION_TIMEOUT = 60;
static NSString *DEFAULT_USER_AGENT = @"iOS";

@interface LAClient()<NSURLSessionDelegate, NSURLSessionDataDelegate>
@property(strong) NSURL *apiBase;
@property(strong) NSMutableDictionary *statusCodeNotifications;
@property(strong) NSURLSession *urlSession;
@end

@implementation LAClient

#pragma mark -
#pragma mark Creational
#pragma mark -
- (id)initWithURL:(NSURL*)url{
    NSParameterAssert(url);

    self = [super init];
    if(self){
        self.apiBase = url;
        self.connectionTimeoutInSeconds = DEFAULT_CONNECTION_TIMEOUT;
        self.connectionUserAgent = DEFAULT_USER_AGENT;
        self.cachePolicy = NSURLRequestUseProtocolCachePolicy;
        self.statusCodeNotifications = [NSMutableDictionary dictionary];
        self.urlSession = [self defaultUrlSession];
    }
    
    return self;
}

-(void)killAllRequests{
    [self.urlSession invalidateAndCancel];
    self.urlSession = [self defaultUrlSession];
}

-(NSURL*)baseUrl{
    return  self.apiBase;
}

#pragma mark -
#pragma mark API Calls
#pragma mark -
//GETS
-(void)getResource:(Class)clazz atPath:(NSString*)path callback:(LAClientRequestCallback)callback{
    [self getResource:clazz atURL:[self apiURLWithPath:path] callback:callback];
}
-(void)getResource:(Class)clazz atURL:(NSURL*)url callback:(LAClientRequestCallback)callback{
    NSMutableURLRequest *request = [self jsonRequestWithMethod:@"GET" url:url];
    [self dispatchRequest:request forResource:clazz isList:FALSE callback:callback];
}
-(void)getResourceList:(Class)clazz atPath:(NSString*)path callback:(LAClientRequestCallback)callback{
    [self getResourceList:clazz atURL:[self apiURLWithPath:path] callback:callback];
}
-(void)getResourceList:(Class)clazz atURL:(NSURL*)url callback:(LAClientRequestCallback)callback{
    NSMutableURLRequest *request = [self jsonRequestWithMethod:@"GET" url:url];
    [self dispatchRequest:request forResource:clazz isList:TRUE callback:callback];
}
//DELETE
-(void)deleteResourceAtPath:(NSString*)path callback:(LAClientRequestCallback)callback{
    [self deleteResourceAtURL:[self apiURLWithPath:path] callback:callback];
}
-(void)deleteResourceAtURL:(NSURL*)url callback:(LAClientRequestCallback)callback{
    NSMutableURLRequest *request = [self jsonRequestWithMethod:@"DELETE" url:url];
    [self dispatchRequest:request forResource:nil isList:FALSE callback:callback];
}
//PUT
-(void)putResource:(id<LARepresentation>)resource atPath:(NSString*)path callback:(LAClientRequestCallback)callback{
    [self putResource:resource atURL:[self apiURLWithPath:path] callback:callback];
}
-(void)putResource:(id<LARepresentation>)resource atURL:(NSURL*)url callback:(LAClientRequestCallback)callback{
    NSMutableURLRequest *request = [self jsonRequestWithMethod:@"PUT" url:url];
    [request setHTTPBody:[resource toData]];
    // not sure, but I think I have to do this to get the class type or it'll only see the protocol
    id resourePointer = resource;
    [self dispatchRequest:request forResource:[resourePointer class] isList:FALSE callback:callback];
}
//POST
-(void)postResource:(id<LARepresentation>)resource atPath:(NSString*)path callback:(LAClientRequestCallback)callback{
    [self postResource:resource atURL:[self apiURLWithPath:path] callback:callback];
}
-(void)postResource:(id<LARepresentation>)resource atURL:(NSURL*)url callback:(LAClientRequestCallback)callback{
    NSMutableURLRequest *request = [self jsonRequestWithMethod:@"POST" url:url];
    [request setHTTPBody:[resource toData]];
    
    // not sure, but I think I have to do this to get the class type or it'll only see the protocol
    id resourePointer = resource;
    [self dispatchRequest:request forResource:[resourePointer class] isList:FALSE callback:callback];
}
//HEAD
-(void)headResourceAtPath:(NSString*)path callback:(LAClientRequestCallback)callback{
    [self headResourceAtURL:[self apiURLWithPath:path] callback:callback];
}
-(void)headResourceAtURL:(NSURL*)url callback:(LAClientRequestCallback)callback{
    NSMutableURLRequest *request = [self jsonRequestWithMethod:@"HEAD" url:url];
    [self dispatchRequest:request forResource:nil isList:FALSE callback:callback];
}
//non-json requests....
-(void)getResourceAtPath:(NSString*)path callback:(LAClientRequestCallback)callback{
    [self getResourceAtURL:[self apiURLWithPath:path] callback:callback];
}
-(void)getResourceAtURL:(NSURL*)url callback:(LAClientRequestCallback)callback{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    [self dispatchRequest:request forResource:[NSData class] isList:FALSE callback:callback];
}

#pragma mark -
#pragma mark Security/authentication
#pragma mark -
-(BOOL)requiresLogin{
    return (self.securityProvider != nil && [self.securityProvider requiresLogin]);
}
-(void)loginUser:(NSString*)username
        password:(NSString*)password
        callback:(void(^)(NSString* username, NSError *error))callback{
    
    [self.securityProvider loginUser:username
                          password:password
                          callback:^(NSString *username, NSError *error) {
                              callback(username, error);
                          }];
}
-(void)logout{
    [self.securityProvider logout];
}
-(NSString*)currentUser{
    return [self.securityProvider currentUser];
}


#pragma mark -
#pragma mark Private helper
#pragma mark -
-(void)dispatchRequest:(NSMutableURLRequest*)request
           forResource:(Class)clazz
                isList:(BOOL)isList
              callback:(LAClientRequestCallback)callback{
    
    //NSAssert(request.URL, @"URL is required to dispatch a request");
    if(request.URL == nil){
        NSLog(@"Unable to dispatch a request for %@ with a nil URL", clazz);
        callback(nil, nil, [NSError errorWithMessage:@"Invalid URL" code:400]);
        return;
    }
    
    if(self.securityProvider != nil){
        [self dispatchSecureRequest:request forResource:clazz isList:isList callback:callback];
    } else {
        [self dispatchRegularRequest:request forResource:clazz isList:isList callback:callback];
    }
}
-(void)dispatchSecureRequest:(NSMutableURLRequest*)request forResource:(Class)clazz isList:(BOOL)isList callback:(LAClientRequestCallback)callback{    
    if([self.securityProvider requiresLogin]){
        // we can't dispatch a secure request because there's no oauth token
        NSLog(@"Security client requires login so throwing an error to indicate we need to show the login screen (trying to access %@)", request.URL);
        callback(nil, nil, [NSError errorWithMessage:@"No OAuth Token found - throw a login" code:LAClientLoginErrorCode]);
        
    } else if([self.securityProvider requiresRefresh]){
        NSLog(@"Security client requires credential refresh so initiating credential refresh");
        // the token is expired, so we need to refresh before we can proceed
        [self.securityProvider refreshCredentialToQueue:[[NSOperationQueue alloc] init]
                           completionCallback:^(NSString *username, NSError *error) {
                               if(error == nil){
                                   //NOTE WE ARE ON A BACKGROUND THREAD HERE... so we stay on it to make the original call
                                   // we got a new token, so let's update the request header with the access token and send it
                                   __block LAClient *manager = self;
                                   [self.securityProvider secureRequest:request];
                                   [manager dispatchRegularRequest:request forResource:clazz isList:isList callback:callback];
                                   
                               } else {
                                   
                                   //NOTE WE ARE ON A BACKGROUND THREAD HERE...
                                   if(error != nil && error.code == LAClientRefreshInProgressErrorCode){
                                       NSLog(@"Unable to refresh credential because it is currently being refreshed, so sleeping for 1 second and retrying the call");
                                       [NSThread sleepForTimeInterval:1];
                                       [self dispatchSecureRequest:request forResource:clazz isList:isList callback:callback];
                                       
                                   } else {
                                       // we were unable to refresh the oauth token for some reason so lets callback the error on the main queue
                                       NSError *e = [NSError errorWithMessage:[error localizedDescription]
                                                                         code:error.code];
                                       
                                       //create the failure block to send back to the main thread
                                       void (^failureBlock)(void) = ^(void){callback(nil, nil, e);};
                                       if ([NSThread isMainThread]){
                                           failureBlock();
                                       } else {
                                           dispatch_sync(dispatch_get_main_queue(), failureBlock);
                                       }
                                   }
                        
                               }
        }];
        
    } else {
        // looks like a good oauth token, so we can send it
        [self.securityProvider secureRequest:request];
        [self dispatchRegularRequest:request forResource:clazz isList:isList callback:callback];
        
    }    
}

-(void)dispatchRegularRequest:(NSURLRequest*)request
                  forResource:(Class)clazz
                       isList:(BOOL)isList
                     callback:(LAClientRequestCallback)callback{
    
    if(clazz != nil && ![self isSupportedClass:clazz]){
        NSLog(@"Object %@ is not a supported class for deserialization. Does it conform to the 'LARepresentaion' protocol?", [clazz class]);
        return;
    }
        
    if(self.debugEnabled){
        NSLog(@"Dispatching request for %@ at %@ %@", clazz, request.HTTPMethod, request.URL);
        //NSLog(@"Request headers %@", [request allHTTPHeaderFields]);
        if(request.HTTPBody != nil){
            NSLog(@"Request payload: %@", [[NSString alloc] initWithData:request.HTTPBody
                                                                encoding:NSUTF8StringEncoding]);
        }
    }
    

    [UIApplication sharedApplication].networkActivityIndicatorVisible = TRUE;
    
    [[self.urlSession dataTaskWithRequest:request
                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                               //stop the indicator from spinning
                               [UIApplication sharedApplication].networkActivityIndicatorVisible = FALSE;

                               if(self.debugEnabled){
                                   NSLog(@"Received response: %@ %ld (data size: %lu)",
                                         response.URL,
                                         (long)((NSHTTPURLResponse*)response).statusCode,
                                         (unsigned long)data.length);
                                   //NSLog(@"Raw response payload: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                                   //NSLog(@"DiskCache: %i of %i", [[NSURLCache sharedURLCache] currentDiskUsage], [[NSURLCache sharedURLCache] diskCapacity]);
                                   //NSLog(@"MemoryCache: %i of %i", [[NSURLCache sharedURLCache] currentMemoryUsage], [[NSURLCache sharedURLCache] memoryCapacity]);
                               }
                           
                           
                               [self handleResponse:response
                                           forClass:clazz
                                             asList:isList
                                               data:data
                                              error:error
                                           callback:callback];
                           }] resume];
    
}
-(void)handleResponse:(NSURLResponse*)response
             forClass:(Class)clazz
               asList:(BOOL)asList
                 data:(NSData*)data
                error:(NSError*)error
             callback:(LAClientRequestCallback)callback{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    NSInteger statusCode = 0;
    id resource = nil;
    NSError *apiError = nil;
    
    if(httpResponse != nil){
        statusCode = httpResponse.statusCode;
    }
    
    if(error == nil && statusCode >= 200 && statusCode < 300){
        // looks like the call was successful, so carry on...
        if(clazz == [NSData class]){
            resource = data;
            
        } else if (clazz == [UIImage class]){
            resource = [UIImage imageWithData:data];
        
        } else if(data != nil && data.length > 0){
            resource = [self buildReturnObject:clazz fromData:data isList:asList];
        }
    } else if (statusCode == 0){
        apiError = [NSError errorWithMessage:[NSString stringWithFormat:@"Network error connecting to %@", [error.userInfo objectForKey:NSURLErrorFailingURLStringErrorKey]]
                                        code:statusCode];
    } else if (error == nil && data != nil){
        //we have data (implied error == nil according to docs) but not a 200 (api error)
        NSString *dataAsString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stripHtml];
        if([dataAsString isEqualToString:@"token not found, expired or invalid"] || [dataAsString isEqualToString:@"Invalid token"]){
            apiError = [NSError errorWithMessage:dataAsString
                                            code:LAClientLoginErrorCode];
            NSLog(@"Invalid oauth token - could be the token or the api is not able to validate it");
            
        } else {
            apiError = [NSError errorWithMessage:dataAsString code:statusCode];
        }

    } else {
        [NSError errorWithMessage:[error localizedDescription] code:statusCode];
    }
    
    callback(resource, httpResponse, apiError);
}
-(NSURLSession*)defaultUrlSession{
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.requestCachePolicy = self.cachePolicy;
    sessionConfig.URLCache =  [NSURLCache sharedURLCache];
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    
    return session;
}
-(NSMutableURLRequest*)jsonRequestWithMethod:(NSString*)method
                                         url:(NSURL*)url{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:method];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:self.connectionUserAgent forHTTPHeaderField:@"User-Agent"];
    [request setCachePolicy:self.cachePolicy];
    [request setTimeoutInterval:self.connectionTimeoutInSeconds];

    return request;
}
-(NSURL*) apiURLWithPath:(NSString*)path{
    // this is dirty, but I'm having probs with [NSURL URLWithString:path relativeToURL:self.apiBase]
    
    NSString *api = [self.apiBase description];
    NSString *slash = @"/";
    NSString *uri = nil;
    BOOL baseHasSuffix = [api hasSuffix:slash];
    BOOL pathHasPrefix = [path hasPrefix:slash];
    
    if(baseHasSuffix && pathHasPrefix){
        uri = [NSString stringWithFormat:@"%@%@", api, [path substringFromIndex:0]];
    } else if(!baseHasSuffix && !pathHasPrefix){
        uri = [NSString stringWithFormat:@"%@%@%@", api, slash, path];
    } else {
        uri = [NSString stringWithFormat:@"%@%@", api, path];
    }
    
    
    
    return [NSURL URLWithString:uri];
}
-(id)buildReturnObject:(Class)clazz fromData:(NSData*)data isList:(BOOL)isList{
    id obj = nil;
    
    if(data == nil){
        NSLog(@"Data is nil, so can't build anything\n");
        return obj;
    }
    
    if(clazz == nil){
        obj = data;
        
    } else if(isList){
        NSArray *array = [clazz arrayWithData:data];
        obj = array;
        
    } else {
        obj = [[clazz alloc] initWithData:data];
        
    }

    return obj;    
}
-(BOOL)isSupportedClass:(Class)clazz{
    BOOL supported = FALSE;
    
    if(clazz == nil){
        return supported;
    }
    
    if(clazz == [NSData class]
       || clazz == [UIImage class]
       || [clazz conformsToProtocol:@protocol(LARepresentation)]){
        supported = TRUE;
    }

    return supported;
}

-(NSHTTPURLResponse*)mockURLResponseForImage:(UIImage*)image atURL:(NSURL*)url{
    NSString *filename = [NSString stringWithFormat:@"%@", url];
    NSData *data = nil;
    if ([filename rangeOfString: @".jpg" options: NSCaseInsensitiveSearch].location != NSNotFound
        || [filename rangeOfString: @".jpeg" options: NSCaseInsensitiveSearch].location != NSNotFound) {
        data = UIImageJPEGRepresentation(image, 100);
    } else {
        data = UIImagePNGRepresentation(image);
    }
    
    return [self mockURLResponseForData:data atURL:url];
}
-(NSHTTPURLResponse*)mockURLResponseForData:(NSData*)data atURL:(NSURL*)url{
    NSString *contentLength = [NSString stringWithFormat:@"%lu", (unsigned long)data.length];
    NSHTTPURLResponse *r = [[NSHTTPURLResponse alloc] initWithURL:url
                                                       statusCode:200
                                                      HTTPVersion:@"1.1"
                                                     headerFields:@{@"Content-Length":contentLength}];
    return r;
}

-(NSString*)description{
    if(self.securityProvider != nil){
        return [NSString stringWithFormat:@"LACLient [API Uri: %@, HTTP Timeout: %d, USER Agent: %@, Security Client: %@]",
                self.apiBase, self.connectionTimeoutInSeconds, self.connectionUserAgent, self.securityProvider];
    } else {
        return [NSString stringWithFormat:@"LACLient [API Uri: %@, HTTP Timeout: %d, USER Agent: %@]",
                self.apiBase, self.connectionTimeoutInSeconds, self.connectionUserAgent];
    }
}

@end

