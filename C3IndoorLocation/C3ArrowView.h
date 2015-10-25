//
//  C3ArrowView.h
//  C3IndoorLocation
//
//  Created by zhaoguoqi on 15/10/25.
//  Copyright © 2015年 zhaoguoqi. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

@protocol C3ArrowViewDelegate <NSObject>

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations;

@end

@interface C3ArrowView : UIView <CLLocationManagerDelegate>

- (void)startPointing;
- (void)stopPointing;
- (BOOL)isPointing;
- (CLLocationManager *)locationManager;

@property (assign, nonatomic) CGFloat thickness;
@property (strong, nonatomic) UIColor *color;
@property (strong, nonatomic) CLLocation *destination;
@property (assign, nonatomic) id<C3ArrowViewDelegate> delegate;

@end
