//
//  LocactionServiceFacade.m
//  LightAPIClient
//
//  Created by Developer iOS on 7/10/13.
//  Copyright (c) 2013 BitBlox. All rights reserved.
//

#import "LALocationServiceFacade.h"
static double kAcceptibleAccuracyInMeters = 30.0;
static NSInteger kAcceptibleAccuracyWaitTimeInSeconds = 10;

@interface LALocationServiceFacade()<CLLocationManagerDelegate>
@property BOOL isUpdatingLocation;
@property NSDate *lastInaccurateLocationUpdateTime;
@end

@implementation LALocationServiceFacade

static LALocationServiceFacade *sharedFacade = nil;

#pragma mark - Property Override
-(void)setLastKnownLocation:(CLLocation *)lastKnownLocation{
    
    if(self.lastInaccurateLocationUpdateTime == nil){
        self.lastInaccurateLocationUpdateTime = [NSDate date];
    }
    
    BOOL differentLocation = (_lastKnownLocation.coordinate.latitude != lastKnownLocation.coordinate.latitude
                              || _lastKnownLocation.coordinate.longitude != lastKnownLocation.coordinate.longitude);
    BOOL accurateEnough = (lastKnownLocation.horizontalAccuracy <= self.acceptibleAccuracyInMeters
                           || [self.lastInaccurateLocationUpdateTime timeIntervalSinceNow] >= self.acceptibleAccuracyWaitTimeInSeconds);
    
    if((differentLocation && accurateEnough) || _lastKnownLocation == nil){
        _lastKnownLocation = lastKnownLocation;
        self.lastInaccurateLocationUpdateTime = nil;
        
        if(self.debugEnabled){
            NSLog(@"Changed location - dispatching NotificationLocationUpdated - %f,%f",
                  lastKnownLocation.coordinate.latitude, lastKnownLocation.coordinate.longitude);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationLocationUpdated object:lastKnownLocation];
        
    } else if(differentLocation && self.debugEnabled){
        NSLog(@"Location not accruate enough and we haven't timed out yet waiting");
        
    }
}

+(LALocationServiceFacade*)sharedFacade{
    @synchronized(self) {
        if(sharedFacade == nil){
            sharedFacade = [LALocationServiceFacade new];
            sharedFacade.locationManager = [[CLLocationManager alloc] init];
            sharedFacade.locationManager.distanceFilter = 20.0;
            sharedFacade.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            sharedFacade.locationManager.delegate = sharedFacade;
            sharedFacade.acceptibleAccuracyWaitTimeInSeconds = kAcceptibleAccuracyWaitTimeInSeconds;
            sharedFacade.acceptibleAccuracyInMeters = kAcceptibleAccuracyInMeters;
        }
    }
    return sharedFacade;
}

-(void)startUpdatingLocation{
    if(!self.isUpdatingLocation && [self isLocationServicesAvailable]){
        if(self.debugEnabled){
            NSLog(@"Starting to update location");
        }
        [self.locationManager startUpdatingLocation];
        self.isUpdatingLocation = TRUE;
    }
}
-(void)stopUpdatingLocation{
    if(self.isUpdatingLocation){
        if(self.debugEnabled){
            NSLog(@"Stopping location updates");
        }
        [self.locationManager stopUpdatingLocation];
        self.isUpdatingLocation = FALSE;
    }
}
-(BOOL)isLocationServicesAvailable{
    BOOL enabled = [CLLocationManager locationServicesEnabled];
    BOOL authorized = ([self isLocationServicesAuthorizedAlways] || [self isLocationServicesAuthorizedWhenInUse]);
    if(self.debugEnabled){
        NSLog(@"Location services enabled? %d authorized? %d", enabled, authorized);
    }
    return (enabled && authorized);
}
-(BOOL)isLocationFencingAvailable{
    return ([self isLocationServicesAuthorizedAlways]
            && [self isLocationServicesAvailable]
            && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined);
}
-(BOOL)isLocationServicesAuthorizedAlways{
    return ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways);
}
-(BOOL)isLocationServicesAuthorizedWhenInUse{
    return ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse);
}

#pragma mark - LocationManagerDelegate Location
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    self.lastKnownLocation = [locations lastObject];
}
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationLocationAuthorizationStatusChange object:nil];
}

#pragma mark - Fences
-(void)enableFenceForLatitude:(CLLocationDegrees)latitude
                    longitude:(CLLocationDegrees)longitude
                       radius:(CLLocationDistance)radius
                   identifier:(NSString*)identifier{
    
    CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(latitude, longitude);
    CLLocationDegrees rad = radius;
    if (rad > self.locationManager.maximumRegionMonitoringDistance) {
        rad = self.locationManager.maximumRegionMonitoringDistance;
    }
    CLRegion *region = [[CLCircularRegion alloc] initWithCenter:centerCoordinate
                                                         radius:rad
                                                     identifier:identifier];
    [self.locationManager startMonitoringForRegion:region];
}
-(void)removeAllFences{
    for(CLRegion *region in self.locationManager.monitoredRegions){
        [self.locationManager stopMonitoringForRegion:region];
    }
}
-(void)removeFenceForIdentifier:(NSString*)identifier{
    for(CLRegion *region in self.locationManager.monitoredRegions){
        if ([region.identifier isEqualToString:identifier]) {
            [self.locationManager stopMonitoringForRegion:region];
        }
    }
}
-(void)logFences{
    for(CLRegion *region in self.locationManager.monitoredRegions){
        NSLog(@"Monitored region: %@", [self descriptionWithRegion:region]);
    }
}


#pragma mark - LocationManagerDelegate Region monitoring
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region{
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationRegionEntered object:region];
}
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region{
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationRegionExited object:region];
}
-(void) locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error{
    if(error){
        NSLog(@"Error monitoring %@ %@", [self descriptionWithRegion:region], error);
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationRegionMonitoringFailed object:region];
    }
}
- (void)locationManager:(CLLocationManager *)manager
      didDetermineState:(CLRegionState)state
              forRegion:(CLRegion *)region{
    if(self.debugEnabled){
        NSLog(@"didDetermineStateForRegion: %@ %ld", region.identifier, (long)state);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationRegionStateDetermined object:region];
}
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region{
    if(self.debugEnabled){
        NSLog(@"didStartMonitoringForRegion: %@", region.identifier);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationRegionMonitoringStarted object:region];
}

#pragma mark - misc
-(NSString*)descriptionWithRegion:(CLRegion*)region{
    CLCircularRegion *cl = (CLCircularRegion*)region;
    return [NSString stringWithFormat:@"region %@ %f,%f X %f",
            cl.identifier,
            cl.center.latitude,
            cl.center.longitude,
            cl.radius];
}

@end
