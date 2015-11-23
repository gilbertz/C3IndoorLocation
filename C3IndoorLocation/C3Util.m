//
//  C3Util.m
//  C3IndoorLocation
//
//  Created by zhao on 15/11/23.
//  Copyright © 2015年 zhaoguoqi. All rights reserved.
//

#import "C3Util.h"

@implementation C3Util
#pragma mark - color
+ (CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length {
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}

+ (UIColor *) colorWithHexString: (NSString *) hexString {
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = [C3Util colorComponentFrom: colorString start: 0 length: 1];
            green = [C3Util colorComponentFrom: colorString start: 1 length: 1];
            blue  = [C3Util colorComponentFrom: colorString start: 2 length: 1];
            break;
        case 4: // #ARGB
            alpha = [C3Util colorComponentFrom: colorString start: 0 length: 1];
            red   = [C3Util colorComponentFrom: colorString start: 1 length: 1];
            green = [C3Util colorComponentFrom: colorString start: 2 length: 1];
            blue  = [C3Util colorComponentFrom: colorString start: 3 length: 1];
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = [C3Util colorComponentFrom: colorString start: 0 length: 2];
            green = [C3Util colorComponentFrom: colorString start: 2 length: 2];
            blue  = [C3Util colorComponentFrom: colorString start: 4 length: 2];
            break;
        case 8: // #AARRGGBB
            alpha = [C3Util colorComponentFrom: colorString start: 0 length: 2];
            red   = [C3Util colorComponentFrom: colorString start: 2 length: 2];
            green = [C3Util colorComponentFrom: colorString start: 4 length: 2];
            blue  = [C3Util colorComponentFrom: colorString start: 6 length: 2];
            break;
        default:
            return nil;
    }
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}



+ (BOOL)iOS7OrLater {
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0) {
        return YES;
    }
    return NO;
}

+ (BOOL)iOS6OrLater {
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0) {
        return YES;
    }
    return NO;
}

+ (UIImage *)image:(NSString *)imageName inBundle:(NSString *)bundle {
    UIImage *ret = [UIImage imageNamed:[NSString stringWithFormat:@"%@/%@", bundle, imageName]];
    
    //尝试绝对路径获取
    NSArray *suffixArray = nil;
    if([UIScreen mainScreen].scale == 1.f) {
        suffixArray = @[@".png", @".jpg", @"@2x.png", @"@2x.jpg"];
    } else {
        suffixArray = @[@"@2x.png", @"@2x.jpg", @".png", @".jpg"];
    }
    NSString *resPath = [[NSBundle mainBundle] resourcePath];
    for(NSString *suffix in suffixArray) {
        ret = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/%@%@", resPath, bundle, imageName, suffix]];
        if(ret) {
            break;
        }
    }
    
    if (!ret) {
        NSLog(@"%s %@ missing image: %@", __FUNCTION__, @"", imageName);
    }
    
    return ret;
}
@end
