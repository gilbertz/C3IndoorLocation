//
//  C3LeftArrowView.m
//  C3IndoorLocation
//
//  Created by zhaoguoqi on 15/11/7.
//  Copyright © 2015年 zhaoguoqi. All rights reserved.
//

#import "C3LeftArrowView.h"

@interface C3LeftArrowView()

@property (strong, nonatomic) CATransformLayer *container;
@property (strong, nonatomic) CAShapeLayer *top;
@property (strong, nonatomic) CAShapeLayer *bottom;
@property (strong, nonatomic) CALayer *left;
@property (strong, nonatomic) CALayer *right;
@property (strong, nonatomic) CALayer *back;
@property (strong, nonatomic) CALayer *backCurveLeft;
@property (strong, nonatomic) CALayer *backCurveRight;
@property (strong, nonatomic) CALayer *backLeft;
@property (strong, nonatomic) CALayer *backRight;

@property (strong, nonatomic) UIColor *borderColor;
@property (assign, nonatomic) CGFloat cornerRadius;
@property (assign, nonatomic) CGFloat borderWidth;
@property (assign, nonatomic) CGFloat opacity;

@property (assign, nonatomic) BOOL shouldRebuild;
@property (assign, nonatomic) BOOL isPointing;
@property (assign, nonatomic) BOOL isBouncing;

@property (assign, nonatomic) CGFloat thickness;
@property (strong, nonatomic) UIColor *color;

@end
@implementation C3LeftArrowView

static const CGFloat kArrowThickness = 15;
static const CGFloat kArrowBorderWidth = 1.0;
static const CGFloat kArrowCornerRadius = 3.0;
static const CGFloat kArrowOpacity = 0.5;

CG_INLINE CGRect CGRectForm(CGPoint p, CGSize s)
{
    CGRect rect;
    rect.origin = p;
    rect.size = s;
    return rect;
}

#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setColor:[UIColor greenColor]];
        [self setBorderColor:[UIColor whiteColor]];
        [self setThickness:kArrowThickness];
        [self setBorderWidth:kArrowBorderWidth];
        [self setCornerRadius:kArrowCornerRadius];
        [self setOpacity:kArrowOpacity];
        [self setBackgroundColor:[UIColor clearColor]];
        [self setOpaque:NO];
        [self rebuild];
        
    }
    return self;
}

- (void)rebuild
{
    for (CALayer *layer in self.layer.sublayers) {
        for (CALayer *sublayer in layer.sublayers) {
            [sublayer removeFromSuperlayer];
        }
        [layer removeFromSuperlayer];
    }
    
    [self buildLayers:self.frame];
    
    [self.layer addSublayer:self.container];
    [self.container addSublayer:self.top];
    [self.container addSublayer:self.bottom];
    [self.container addSublayer:self.left];
    [self.container addSublayer:self.right];
    [self.container addSublayer:self.backLeft];
    [self.container addSublayer:self.backRight];
    
    for (CALayer *layer in self.container.sublayers) {
        [self modifyLayer:layer
              withBGColor:self.color
              borderColor:self.borderColor
              borderWidth:self.borderWidth
             cornerRadius:self.cornerRadius
                  opacity:self.opacity];
        layer.shouldRasterize = YES;
        layer.rasterizationScale = [UIScreen mainScreen].scale;
        layer.drawsAsynchronously = YES;
    }
    
    CATransform3D transform;
    transform = CATransform3DMakeRotation(1.05, 1, 0, 0);
    self.container.transform = transform;
    
    self.shouldRebuild = NO;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.shouldRebuild = YES;
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    self.shouldRebuild = YES;
}

- (void)setBorderColor:(UIColor *)borderColor
{
    _borderColor = borderColor;
    self.shouldRebuild = YES;
}

- (void)setThickness:(CGFloat)thickness
{
    _thickness = thickness;
    self.shouldRebuild = YES;
}

- (void)addArrowMaskToShapeLayer:(CAShapeLayer *)layer
{
    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(0,
                                       layer.frame.size.height)];
    [shapePath addLineToPoint:CGPointMake(layer.frame.size.width / 2.0,
                                          0)];
    [shapePath addLineToPoint:CGPointMake(layer.frame.size.width,
                                          layer.frame.size.height)];
    [shapePath addLineToPoint:CGPointMake(layer.frame.size.width / 2.0,
                                          3.0 * layer.frame.size.height /
                                          4.0)];
    [shapePath addLineToPoint:CGPointMake(0,
                                          layer.frame.size.height)];
    
    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.path = [shapePath CGPath];
    mask.lineJoin = kCALineJoinRound;
    layer.mask = mask;
}

- (void)setAnchorPoint:(CGPoint)anchorPoint forLayer:(CALayer *)layer
{
    CGPoint newPoint = CGPointMake(layer.bounds.size.width * anchorPoint.x,
                                   layer.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(layer.bounds.size.width *
                                   layer.anchorPoint.x,
                                   layer.bounds.size.height *
                                   layer.anchorPoint.y);
    
    CGPoint position = layer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    layer.position = position;
    layer.anchorPoint = anchorPoint;
}

- (void)modifyLayer:(CALayer *)layer
        withBGColor:(UIColor *)bgColor
        borderColor:(UIColor *)borderColor
        borderWidth:(CGFloat)borderWidth
       cornerRadius:(CGFloat)cornerRadius
            opacity:(CGFloat)opacity
{
    layer.backgroundColor = [bgColor CGColor];
    layer.opacity = opacity;
    layer.borderColor = [borderColor CGColor];
    layer.borderWidth = borderWidth;
    layer.cornerRadius = cornerRadius;
}

- (void)buildLayers:(CGRect)frame
{
    self.container = [CATransformLayer layer];
    [self buildContainerLayer:self.container withFrame:frame];
    
    self.top = [CAShapeLayer layer];
    [self buildTopLayer:self.top withFrame:frame];
    
    self.bottom = [CAShapeLayer layer];
    [self buildBottomLayer:self.bottom withFrame:frame];
    
    self.left = [CALayer layer];
    [self buildLeftLayer:self.left withFrame:frame];
    
    self.right = [CALayer layer];
    [self buildRightLayer:self.right withFrame:frame];
    
    self.backLeft = [CALayer layer];
    [self buildBackLeftLayer:self.backLeft withFrame:frame];
    
    self.backRight = [CALayer layer];
    [self buildBackRightLayer:self.backRight withFrame:frame];
}


- (void)buildContainerLayer:(CATransformLayer *)container
                  withFrame:(CGRect)frame
{
    container.frame = CGRectForm(CGPointMake(0, 0), frame.size);
}

- (void)buildTopLayer:(CAShapeLayer *)top withFrame:(CGRect)frame
{
    top.transform = CATransform3DMakeTranslation(0, 0, self.thickness / 2.0);
    top.frame = CGRectForm(CGPointMake(0, 0), frame.size);
    
    [self addArrowMaskToShapeLayer:top];
}

- (void)buildBottomLayer:(CAShapeLayer *)bottom withFrame:(CGRect)frame
{
    bottom.transform =
    CATransform3DMakeTranslation(0, 0, -self.thickness / 2.0);
    bottom.frame = CGRectForm(CGPointMake(0, 0), frame.size);
    
    [self addArrowMaskToShapeLayer:bottom];
}

- (void)buildLeftLayer:(CALayer *)left withFrame:(CGRect)frame
{
    CGFloat hypot = hypotf(frame.size.height, frame.size.width/2.0);
    left.frame = CGRectForm(CGPointMake(0,
                                        frame.size.height - hypot),
                            CGSizeMake(self.thickness,
                                       hypot));
    
    [self setAnchorPoint:CGPointMake(0, 1.0) forLayer:left];
    
    CATransform3D rotation = CATransform3DMakeRotation(M_PI_2, 0, 1, 0);
    CGFloat angle = atanf((frame.size.width/2.0) / frame.size.height);
    rotation = CATransform3DRotate(rotation, -angle, 1, 0, 0);
    rotation = CATransform3DTranslate(rotation, -self.thickness / 2.0, 0, 0);
    left.transform = rotation;
}

- (void)buildRightLayer:(CALayer *)right withFrame:(CGRect)frame
{
    CGFloat hypot = hypotf(frame.size.height, frame.size.width/2.0);
    right.frame = CGRectForm(CGPointMake(frame.size.width,
                                         frame.size.height - hypot),
                             CGSizeMake(self.thickness,
                                        hypot));
    
    [self setAnchorPoint:CGPointMake(0, 1.0) forLayer:right];
    
    CATransform3D rotation = CATransform3DMakeRotation(M_PI_2, 0, 1, 0);
    CGFloat angle = atanf((frame.size.width/2.0) / frame.size.height);
    rotation = CATransform3DRotate(rotation, angle, 1, 0, 0);
    rotation = CATransform3DTranslate(rotation, -self.thickness / 2.0, 0, 0);
    right.transform = rotation;
}

- (void)buildBackLayer:(CALayer *)back withFrame:(CGRect)frame
{
    back.frame = CGRectForm(CGPointMake(0,
                                        frame.size.height - self.thickness /
                                        2.0),
                            CGSizeMake(frame.size.width,
                                       self.thickness));
    
    back.transform = CATransform3DMakeRotation(M_PI_2, 1, 0, 0);
}

- (void)buildBackLeftLayer:(CALayer *)backLeft withFrame:(CGRect)frame
{
    CGFloat leg1 = frame.size.width / 2.0;
    CGFloat leg2 = frame.size.height / 4.0;
    
    CGFloat hypot = hypotf(leg1, leg2);
    
    CGFloat angle = atan(leg2 / leg1);
    
    [self setAnchorPoint:CGPointMake(0, 0) forLayer:backLeft];
    
    backLeft.frame = CGRectMake(0,
                                frame.size.height,
                                hypot*1.01,
                                self.thickness);
    backLeft.transform = CATransform3DMakeRotation(M_PI_2, 1, 0, 0);
    backLeft.transform = CATransform3DRotate(backLeft.transform,
                                             -angle,
                                             0.0,
                                             1.0,
                                             0.0);
    backLeft.transform = CATransform3DTranslate(backLeft.transform,
                                                0,
                                                -self.thickness / 2.0,
                                                0);
}

- (void)buildBackRightLayer:(CALayer *)backRight withFrame:(CGRect)frame
{
    CGFloat leg1 = frame.size.width / 2.0;
    CGFloat leg2 = frame.size.height / 4.0;
    
    CGFloat hypot = hypotf(leg1, leg2);
    
    CGFloat angle = atanf(leg2 / leg1);
    
    [self setAnchorPoint:CGPointMake(0, 0) forLayer:backRight];
    
    backRight.frame = CGRectMake(frame.size.width,
                                 frame.size.height,
                                 hypot*1.01,
                                 self.thickness);
    backRight.transform = CATransform3DMakeRotation(M_PI_2, 1, 0, 0);
    backRight.transform = CATransform3DRotate(backRight.transform,
                                              (angle + M_PI),
                                              0.0,
                                              1.0,
                                              0.0);
    backRight.transform = CATransform3DTranslate(backRight.transform,
                                                 0,
                                                 -self.thickness / 2.0,
                                                 0);
}



@end
