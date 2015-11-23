//
//  C3Util.h
//  C3IndoorLocation
//
//  Created by zhao on 15/11/23.
//  Copyright © 2015年 zhaoguoqi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface C3Util : NSObject
+ (UIColor *) colorWithHexString: (NSString *) hexString;

+ (BOOL)iOS7OrLater ;
+ (BOOL)iOS6OrLater;


+ (UIImage *)image:(NSString *)imageName inBundle:(NSString *)bundle;
@end
