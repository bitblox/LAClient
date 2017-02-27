//
//  LocactionServiceFacade.h
//  LightAPIClient
//
//  Created by Seth Jordan on 7/10/13.
//  Copyright (c) 2013 SourceGroove. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "LAApiError.h"

static NSString *NotificationLocationAuthorizationStatusChange = @"NotificationLocationAuthorizationStatusChange";
static NSString *NotificationLocationUpdated = @"NotificationLocationUpdated";
static NSString *NotificationRegionEntered = @"NotificationRegionEntered";
static NSString *NotificationRegionExited = @"NotificationRegionExited";
static NSString *NotificationRegionMonitoringStarted = @"NotificationRegionMonitoringStarted";
static NSString *NotificationRegionMonitoringFailed = @"NotificationRegionMonitoringFailed";
static NSString *NotificationRegionStateDetermined = @"NotificationRegionStateDetermined";

@interface LALocationServiceFacade : NSObject
@property CLLocationManager *locationManager;
@property (nonatomic, retain) CLLocation *lastKnownLocation;
@property BOOL debugEnabled;
@property double acceptibleAccuracyInMeters;
@property NSInteger acceptibleAccuracyWaitTimeInSeconds;

+(LALocationServiceFacade*)sharedFacade;

-(BOOL)isLocationServicesAvailable;
-(BOOL)isLocationServicesAuthorizedAlways;
-(BOOL)isLocationServicesAuthorizedWhenInUse;
-(BOOL)isLocationFencingAvailable;
-(void)startUpdatingLocation;
-(void)stopUpdatingLocation;
-(void)logFences;
-(void)removeAllFences;
-(void)removeFenceForIdentifier:(NSString*)identifier;
-(void)enableFenceForLatitude:(CLLocationDegrees)latitdue
                    longitude:(CLLocationDegrees)longitude
                       radius:(CLLocationDistance)radius
                   identifier:(NSString*)identifier;

@end
