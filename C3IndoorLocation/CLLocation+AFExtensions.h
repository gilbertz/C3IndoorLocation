//
//  CLLocation+AFExtensions.h
//  C3IndoorLocation
//
//  Created by zhaoguoqi on 15/10/25.
//  Copyright © 2015年 zhaoguoqi. All rights reserved.
//


#import <CoreLocation/CoreLocation.h>

@interface CLLocation (AFExtensions)
- (double)bearingInRadiansTowardsLocation:(CLLocation *)towardsLocation;
- (double)bearingInDegreesTowardsLocation:(CLLocation *)towardsLocation;
- (CLLocation *)locationAtDistance:(CLLocationDistance)atDistance alongBearingInRadians:(double)bearingInRadians;
+ (CLLocation *)locationWithCoordinate:(CLLocationCoordinate2D)someCoordinate;
@end
