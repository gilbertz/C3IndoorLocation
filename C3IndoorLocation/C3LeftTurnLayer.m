//
//  C3LeftTurnLayer.m
//  C3IndoorLocation
//
//  Created by zhaoguoqi on 15/11/8.
//  Copyright © 2015年 zhaoguoqi. All rights reserved.
//

#import "C3LeftTurnLayer.h"

@implementation C3LeftTurnLayer

-(void)drawInContext:(CGContextRef)ctx

{
    /*画直线箭头角形*/
    CGPoint sPoints[9];//坐标点
    sPoints[0] =CGPointMake(0, 50);//坐标1
    sPoints[1] =CGPointMake(100, 0);//坐标2
    sPoints[2] =CGPointMake(100, 30);//坐标3
    sPoints[3] =CGPointMake(170, 30);
    sPoints[4] =CGPointMake(170, 300);
    sPoints[5] =CGPointMake(130, 300);
    sPoints[6] =CGPointMake(130, 70);
    sPoints[7] =CGPointMake(100, 70);
    sPoints[8] =CGPointMake(100, 100);
    CGContextAddLines(ctx, sPoints, 9);//添加线
    CGContextClosePath(ctx);//封起来
    CGContextSetRGBFillColor(ctx, 0, 1, 0, 0.5);
    CGContextFillPath(ctx);
    
}

@end
