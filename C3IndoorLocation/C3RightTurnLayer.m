//
//  C3RightTurnLayer.m
//  C3IndoorLocation
//
//  Created by zhaoguoqi on 15/11/8.
//  Copyright © 2015年 zhaoguoqi. All rights reserved.
//

#import "C3RightTurnLayer.h"

@implementation C3RightTurnLayer
-(void)drawInContext:(CGContextRef)ctx

{
    /*画直线箭头角形*/
    CGPoint sPoints[9];//坐标点
    sPoints[0] =CGPointMake(200, 50);
    sPoints[1] =CGPointMake(100, 0);
    sPoints[2] =CGPointMake(100, 30);
    sPoints[3] =CGPointMake(30, 30);
    sPoints[4] =CGPointMake(30, 300);
    sPoints[5] =CGPointMake(70, 300);
    sPoints[6] =CGPointMake(70, 70);
    sPoints[7] =CGPointMake(100, 70);
    sPoints[8] =CGPointMake(100, 100);
    CGContextAddLines(ctx, sPoints, 9);//添加线
    CGContextClosePath(ctx);//封起来
    CGContextSetRGBFillColor(ctx, 0, 1, 0, 0.5);
    CGContextFillPath(ctx);
    
}
@end
