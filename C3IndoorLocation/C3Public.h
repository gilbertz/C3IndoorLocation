//
//  C3Public.h
//  C3IndoorLocation
//
//  Created by zhao on 15/11/23.
//  Copyright © 2015年 zhaoguoqi. All rights reserved.
//

#ifndef C3Public_h
#define C3Public_h

// 1.判断是否为iOS7
#define iOS7 ([[UIDevice currentDevice].systemVersion doubleValue] >= 7.0)

// 2.获得RGB颜色
#define RGBA(r, g, b, a)                    [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
#define RGB(r, g, b)                        RGBA(r, g, b, 1.0f)

#define navigationBarColor RGB(33, 192, 174)
#define separaterColor RGB(235, 235, 235)

#define MSRedColor RGB(255,51,102)
#define MSTextColor RGB(51,51,51)
#define MSGrayColor RGB(80,80,80)
#define MSBlackColor RGB(21,22,31)
#define MSSeparatorLineColor RGB(204, 204, 204)
#define MSDARKGRAY RGB(32,32,32)
#define MSDARKYELLOW RGB(210,152,47)
// 3.是否为4inch
#define fourInch ([UIScreen mainScreen].bounds.size.height == 568)

// 4.屏幕大小尺寸
#define screen_width [UIScreen mainScreen].bounds.size.width
#define screen_height [UIScreen mainScreen].bounds.size.height

//重新设定view的Y值
#define setFrameY(view, newY) view.frame = CGRectMake(view.frame.origin.x, newY, view.frame.size.width, view.frame.size.height)
#define setFrameX(view, newX) view.frame = CGRectMake(newX, view.frame.origin.y, view.frame.size.width, view.frame.size.height)
#define setFrameH(view, newH) view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, newH)

//取view的坐标及长宽
#define W(view)    view.frame.size.width
#define H(view)    view.frame.size.height
#define X(view)    view.frame.origin.x
#define Y(view)    view.frame.origin.y

//5.常用对象
#define APPDELEGATE ((AppDelegate *)[UIApplication sharedApplication].delegate)

//6.经纬度
#define LATITUDE_DEFAULT 39.983497
#define LONGITUDE_DEFAULT 116.318042

//7.
#define IOS_VERSION [[[UIDevice currentDevice] systemVersion] floatValue]

//8.section gaodu
#define TABLEVIEW_SECTION_HEADER_HIGHT 10
#define TABLEVIEW_AD_HIGHT 200

//9.图片尺寸比例
#define IMAGE_16_9 9/16
#define IMAGE_7_10 10/7
#define IMAGE_1_1  1/1

//cell
#define RECOMMAND_MARGIN 10
#define RECOMMAND_HEADER_HIGHT 50
#define RECOMMAND_HEADER_MARGIN 10
#define RECOMMAND_FOOTER_HIGHT 10

#endif /* C3Public_h */
