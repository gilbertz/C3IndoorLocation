//
//  CLLocationManager+AFExtensions.h
//  C3IndoorLocation
//
//  Created by zhaoguoqi on 15/10/25.
//  Copyright © 2015年 zhaoguoqi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef enum {
    GPSAccuracyZeroBars,
    GPSAccuracyOneBar,
    GPSAccuracyTwoBars,
    GPSAccuracyThreeBars,
} GPSAccuracyLevel;

@interface CLLocationManager (AFExtensions)

- (BOOL)withinRadius:(CLLocationDistance)radius ofLocation:(CLLocation *)someLocation;
- (NSString *)directionToLocation:(CLLocation *)someLocation;
- (NSString *)distanceToLocation:(CLLocation *)someLocation;
- (NSString *)distanceAndDirectionTo:(CLLocation *)someLocation;

@end
