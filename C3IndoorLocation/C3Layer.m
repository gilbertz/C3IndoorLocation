//
//  C3Layer.m
//  C3IndoorLocation
//
//  Created by zhaoguoqi on 15/11/8.
//  Copyright © 2015年 zhaoguoqi. All rights reserved.
//

#import "C3Layer.h"

@implementation C3Layer

-(void)drawInContext:(CGContextRef)ctx
{
    /*画直线箭头角形*/
    CGPoint sPoints[7];//坐标点
    sPoints[0] =CGPointMake(50, 0);//坐标1
    sPoints[1] =CGPointMake(0, 100);//坐标2
    sPoints[2] =CGPointMake(30, 100);//坐标3
    sPoints[3] =CGPointMake(30, 300);
    sPoints[4] =CGPointMake(70, 300);
    sPoints[5] =CGPointMake(70, 100);
    sPoints[6] =CGPointMake(100, 100);
    CGContextAddLines(ctx, sPoints, 7);//添加线
    CGContextClosePath(ctx);//封起来
    CGContextSetRGBFillColor(ctx, 0, 1, 0, 0.5);
    CGContextFillPath(ctx);

}

@end
