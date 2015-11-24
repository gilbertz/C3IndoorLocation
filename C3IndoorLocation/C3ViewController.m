//
//  C3ViewController.m
//  C3IndoorLocation
//
//  Created by zhaoguoqi on 15/10/25.
//  Copyright © 2015年 zhaoguoqi. All rights reserved.
//

#import "C3ViewController.h"
#import "C3ArrowView.h"
#import "CLLocationManager+AFExtensions.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "C3Layer.h"
#import "C3LeftTurnLayer.h"
#import "C3RightTurnLayer.h"
#import <AVFoundation/AVFoundation.h>

//weixin
//static NSString * const kUUID = @"FDA50693-A4E2-4FB1-AFCF-C6EB07647825";
//yunzi
//static NSString * const kUUID = @"23A01AF0-232A-4518-9C0E-323FB773F5EF";
//estimote
static NSString * const kUUID = @"B9407F30-F5F8-466E-AFF9-25556B57FE6D";
//bright
//static NSString * const kUUID = @"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0";
//april
//static NSString * const kUUID = @"B5B182C7-EAB1-4988-AA99-B5C1517008D9";

#define  ARCHITECTSCALE 20

static NSString * const kIdentifier = @"SomeIdentifier";
static void * const kMonitoringOperationContext = (void *)&kMonitoringOperationContext;
static void * const kRangingOperationContext = (void *)&kRangingOperationContext;

typedef NS_ENUM(NSUInteger, NTSectionType) {
    NTOperationsSection,
    NTDetectedBeaconsSection
};

typedef NS_ENUM(NSUInteger, NTOperationsRow) {
    NTRangingRow
};

@interface C3ViewController ()<C3ArrowViewDelegate,UIWebViewDelegate,CLLocationManagerDelegate,UITableViewDataSource,UITableViewDelegate>

@property (strong, nonatomic) C3ArrowView *arrowView;
@property (strong, nonatomic) UILabel *navigationLabel;
@property (strong, nonatomic) UILabel *navigationTitleLabel;
@property (strong, nonatomic) UILabel *locationLabel;
@property (strong, nonatomic) UILabel *locationTitleLabel;
@property (strong, nonatomic) UILabel *distanceLabel;
@property (strong, nonatomic) UILabel *distanceTitleLabel;
@property (strong, nonatomic) UIImagePickerController *picker;
@property (strong, nonatomic) UIView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) NSArray *detectedBeacons;
@property (nonatomic, weak) UISwitch *rangingSwitch;
@property (nonatomic, unsafe_unretained) void *operationContext;
@property (strong, nonatomic) UIWebView *myWebView;
@property (strong, nonatomic) UIView *overlayView;
@property (strong, nonatomic) C3RightTurnLayer *rightTurnLayer;
@property (strong, nonatomic) C3Layer *straightLayer;
@property (strong, nonatomic) C3LeftTurnLayer *leftTurnLayer;
@property (assign, nonatomic) BOOL isAddSublayer;
@property (strong, nonatomic) CATransformLayer *container;
@property (strong, nonatomic) UIView *directionView;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray *destinationArray;
//AVCaptureSession对象来执行输入设备和输出设备之间的数据传递
@property (nonatomic, strong) AVCaptureSession * session;
//AVCaptureDeviceInput对象是输入流
@property (nonatomic, strong) AVCaptureDeviceInput * videoInput;
//照片输出流对象，当然我的照相机只有拍照功能，所以只需要这个对象就够了
@property (nonatomic, strong) AVCaptureStillImageOutput * stillImageOutput;
//预览图层，来显示照相机拍摄到的画面
@property (nonatomic, strong) AVCaptureVideoPreviewLayer  * previewLayer;
//放置预览图层的View
@property (nonatomic, strong) UIView * cameraShowView;
//信息栏
@property (nonatomic, strong)UIView *footerInfoView ;
@property (nonatomic, strong)UIView *headerInfoView ;
@property (nonatomic, strong)UIButton *destinationChooseButton;

@end

@implementation C3ViewController

#pragma mark - AVFoundation camera
- (void) initialSession
{
    //这个方法的执行我放在init方法里了
    self.session = [[AVCaptureSession alloc] init];
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:nil];
    //[self fronCamera]方法会返回一个AVCaptureDevice对象，因为我初始化时是采用前摄像头，所以这么写，具体的实现方法后面会介绍
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    //这是输出流的设置参数AVVideoCodecJPEG参数表示以JPEG的图片格式输出图片
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    
}

- (AVCaptureDevice *)backCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (void) setUpCameraLayer
{
    if (self.previewLayer == nil) {
        self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        UIView * view = self.cameraShowView;
        CALayer * viewLayer = [view layer];
        [viewLayer setMasksToBounds:YES];
        
        CGRect bounds = [view bounds];
        [self.previewLayer setFrame:bounds];
        
        [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [viewLayer insertSublayer:self.previewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
        
        CATransform3D transform = CATransform3DMakeRotation(3*M_PI/2, 0, 0, 1);
        self.cameraShowView.layer.transform =  transform;
        
        
    }
}

#pragma mark - Lifecycle

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self initialSession];
    self.cameraShowView = [[UIView alloc] initWithFrame:CGRectMake(85.5, -85.5+50, 512, 683)];
    [self setUpCameraLayer];
    [self.view addSubview:self.cameraShowView];
    
    self.headerInfoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 683, 50)];
    self.headerInfoView.backgroundColor = [UIColor grayColor];
    self.headerInfoView.alpha = 0.5;
    [self.view addSubview:self.headerInfoView];
    
    UILabel *welcomeLabel = [[UILabel alloc] initWithFrame:CGRectMake(300, 10, 200, 30)];
    welcomeLabel.font = [UIFont boldSystemFontOfSize:20];
    welcomeLabel.textColor = [UIColor whiteColor];
    welcomeLabel.text = @"搬运车导航系统";
    [self.headerInfoView addSubview:welcomeLabel];
    
    //添加下下部信息栏
    self.footerInfoView = [[UIView alloc] initWithFrame:CGRectMake(0, 562, 683, 206)];
    self.footerInfoView.backgroundColor = [UIColor grayColor];
    self.footerInfoView.alpha = 0.5;
    [self.view addSubview:self.footerInfoView];
    
    self.locationTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(250, 30, 100, 30)];
    self.locationTitleLabel.text = @"目的地:";
    self.locationTitleLabel.textColor = [UIColor whiteColor];
    self.locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(400, 30, 100, 30)];
    self.locationLabel.textColor = [UIColor whiteColor];
    
    
    self.distanceTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(250, 90, 50, 30)];
    self.distanceTitleLabel.text = @"距离:";
    self.distanceTitleLabel.textColor = [UIColor whiteColor];
    
    self.distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(400, 90, 100, 30)];
    self.distanceLabel.textColor = [UIColor whiteColor];
    
    
    self.navigationTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(250, 150, 50, 30)];
    self.navigationTitleLabel.text = @"导航:";
    self.navigationTitleLabel.textColor = [UIColor whiteColor];
    
    self.navigationLabel = [[UILabel alloc] initWithFrame:CGRectMake(400, 150, 200, 30)];
    self.navigationLabel.textColor = [UIColor whiteColor];
    
    
    [self.footerInfoView addSubview:self.locationTitleLabel];
    [self.footerInfoView addSubview:self.locationLabel];
    [self.footerInfoView addSubview:self.distanceTitleLabel];
    [self.footerInfoView addSubview:self.distanceLabel];
    [self.footerInfoView addSubview:self.navigationTitleLabel];
    [self.footerInfoView addSubview:self.navigationLabel];
    
    self.mapView = [[UIView alloc] initWithFrame:CGRectMake(683, 0, 341, 768)];
    self.mapView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.mapView];
    
    //mapView上的mywebview
    self.myWebView = [[UIWebView alloc] initWithFrame:self.mapView.bounds];
    self.myWebView.backgroundColor = [UIColor whiteColor];
    
    NSString *localHTMLPageFilePath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    NSURL *localHTMLPageFileURL = [NSURL fileURLWithPath:localHTMLPageFilePath];
    [self.myWebView loadRequest:[NSURLRequest requestWithURL:localHTMLPageFileURL]];
    self.myWebView.delegate=self;
    self.myWebView.scalesPageToFit = YES;
    [self.mapView addSubview:self.myWebView];
    
    //选择目的地butthon和tableview
    self.destinationArray = @[@"208",@"209"];
    self.destinationChooseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.destinationChooseButton setImage:[UIImage imageNamed:@"list"] forState:UIControlStateHighlighted];
    [self.destinationChooseButton setImage:[UIImage imageNamed:@"list"] forState:UIControlStateNormal];
    self.destinationChooseButton.frame = CGRectMake(screen_width - 50, 30, 30, 30);
    [self.destinationChooseButton addTarget:self action:@selector(destinationChoose) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.destinationChooseButton];
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.frame = CGRectMake(683, 0, 341, 768);
    
    self.directionView = [[UIView alloc] initWithFrame:CGRectMake(screen_width/3, screen_height/2, 200, 400)];
    [self.view addSubview:self.directionView];
    //开始搜寻beacon
    [self startRangingForBeacons];
    
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.session) {
        [self.session startRunning];
    }
    [self setupArrowViewInView:self.view];
    //隐藏状态栏
    [[UIApplication sharedApplication] setStatusBarHidden:TRUE];
    
}

#pragma mark - Perspective  transform
CATransform3D CATransform3DMakePerspective(CGPoint center, float disZ)
{
    CATransform3D transToCenter = CATransform3DMakeTranslation(-center.x, -center.y, 0);
    CATransform3D transBack = CATransform3DMakeTranslation(center.x, center.y, 0);
    CATransform3D scale = CATransform3DIdentity;
    scale.m34 = -1.0f/disZ;
    return CATransform3DConcat(CATransform3DConcat(transToCenter, scale), transBack);
}

CATransform3D CATransform3DPerspect(CATransform3D t, CGPoint center, float disZ)
{
    return CATransform3DConcat(t, CATransform3DMakePerspective(center, disZ));
}

#pragma mark - Setup

- (void)setupArrowViewInView:(UIView *)view
{
    CGRect frame = CGRectMake(3.0*view.frame.size.width / 10.0,
                              1*view.frame.size.height / 10.0,
                              1.0 * view.frame.size.width / 10.0,
                              1* view.frame.size.height / 6.0);
    self.arrowView = [[C3ArrowView alloc] initWithFrame:frame];
    self.arrowView.delegate = self;
    [view addSubview:self.arrowView];
}

#pragma mark - NAArrowViewDelegate

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    //        self.distanceLabel.text = [manager distanceToLocation:self.arrowView.destination];
}

#pragma mark - Button actions
- (void)destinationChoose {
    [self.view addSubview:self.tableView];
}

#pragma mark - UITableView datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = self.destinationArray[indexPath.row];
    return cell;
}

#pragma mark - UITableView delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    self.locationLabel.text = self.destinationArray[indexPath.row];
    NSString *jsonDataString = [NSString stringWithFormat:@"button(%@)",self.destinationArray[indexPath.row]];
    [self.myWebView stringByEvaluatingJavaScriptFromString:jsonDataString];
    
    if ([self.destinationArray[indexPath.row] isEqualToString:@"R208"]) {
        self.arrowView.destination =[[CLLocation alloc] initWithLatitude:31.02608 longitude:121.43825];
    }else{
        self.arrowView.destination =[[CLLocation alloc] initWithLatitude:31.02608 longitude:121.43825];
    }
    
    if (!self.arrowView.isPointing) {
        [self.arrowView startPointing];
    }
    
    [self.tableView removeFromSuperview];
}

#pragma mark UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    //获取请求的绝对路径.
    NSString *requestString = [[request URL]absoluteString];
    //提交请求时候分割参数的分隔符
    NSLog(@"request: %@",requestString);
    NSArray *components = [requestString componentsSeparatedByString:@":"];
    NSString *direction = @"";
    NSString *distance = @"";
    NSString *totalDistance = @"";
    NSString *location = @"";
    
    //判断是否是产生距离信息的url
    BOOL isGenerate = [(NSString *)[components objectAtIndex:0]isEqualToString:@"generate"];
    if (isGenerate) {
        if([(NSString *)[components objectAtIndex:1]isEqualToString:@"right"])
        {
            direction = @"右转";
            self.rightTurnLayer = [C3RightTurnLayer layer];
            self.rightTurnLayer.bounds=self.directionView.bounds;
            self.rightTurnLayer.anchorPoint=CGPointMake(0.25, 0.5);
            self.rightTurnLayer.backgroundColor=[UIColor clearColor].CGColor;
            [self.rightTurnLayer setNeedsDisplay];
            CATransform3D transform = CATransform3DMakeRotation(M_PI/3, 1, 0, 0);
            self.rightTurnLayer.transform =  CATransform3DPerspect(transform, CGPointMake(0, 0), 200);
            [self.container removeFromSuperlayer];
            self.container = [[CATransformLayer alloc] init];
            [self.container addSublayer:self.rightTurnLayer];
            [self.directionView.layer addSublayer:self.container];
            
        }else if([(NSString *)[components objectAtIndex:1]isEqualToString:@"left"]){
            direction = @"左转";
            self.leftTurnLayer = [C3LeftTurnLayer layer];
            self.leftTurnLayer.bounds=self.directionView.bounds;
            self.leftTurnLayer.anchorPoint=CGPointMake(0.25, 0.5);
            self.leftTurnLayer.backgroundColor=[UIColor clearColor].CGColor;
            [self.leftTurnLayer setNeedsDisplay];
            CATransform3D transform = CATransform3DMakeRotation(M_PI/3, 1, 0, 0);
            self.leftTurnLayer.transform =  CATransform3DPerspect(transform, CGPointMake(0, 0), 200);
            [self.container removeFromSuperlayer];
            self.container = [[CATransformLayer alloc] init];
            [self.container addSublayer:self.leftTurnLayer];
            [self.directionView.layer addSublayer:self.container];
        }else if([(NSString *)[components objectAtIndex:1]isEqualToString:@"straight"]){
            direction = @"直行";
            self.straightLayer = [C3Layer layer];
            self.straightLayer.bounds=self.directionView.bounds;
            self.straightLayer.anchorPoint=CGPointMake(0.25, 0.5);
            self.straightLayer.backgroundColor=[UIColor clearColor].CGColor;
            [self.straightLayer setNeedsDisplay];
            CATransform3D transform = CATransform3DMakeRotation(M_PI/3
                                                                , 1, 0, 0);
            self.straightLayer.transform =  CATransform3DPerspect(transform, CGPointMake(0, 0), 200);
            [self.container removeFromSuperlayer];
            self.container = [[CATransformLayer alloc] init];
            [self.container addSublayer:self.straightLayer];
            [self.directionView.layer addSublayer:self.container];
            
        }
        
        distance = [components objectAtIndex:2];
        totalDistance = [components objectAtIndex:3];
        location = [components objectAtIndex:4];
        
        if ([distance isEqualToString:@"0"]) {
            self.navigationLabel.text = @"未知";
        }else{
            distance = [NSString stringWithFormat:@"%ld", [distance integerValue]/ARCHITECTSCALE ];
            distance = [distance stringByAppendingString:@" meters "];
            self.navigationLabel.text = [distance stringByAppendingString:direction];
        };
        
        if ([totalDistance isEqualToString:@"0"]) {
            self.distanceLabel.text = @"未知";
        }else{
            totalDistance = [NSString stringWithFormat:@"%ld", [totalDistance integerValue]/ARCHITECTSCALE ];
            totalDistance = [totalDistance stringByAppendingString:@" meters "];
            self.distanceLabel.text = totalDistance;
        };
        
        if ([location isEqualToString:@""]) {
            self.locationLabel.text = @"未知";
        }else{
            self.locationLabel.text = [components objectAtIndex:4];
        };
        
        //检测到的beacon数组
        NSMutableArray *dictArr = [NSMutableArray array];
        for (int i = 0; i < self.detectedBeacons.count; i++) {
            CLBeacon *beacon = self.detectedBeacons[i];
            
            NSString *rssiString = [NSString stringWithFormat:@"%ld", labs(beacon.rssi)];
            NSDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:[beacon.minor floatValue]],@"minor",[NSNumber numberWithFloat:[beacon.major floatValue]],@"major", [NSNumber numberWithInt:[rssiString intValue]] ,@"rssi",[NSNumber numberWithInt:59],@"measuredPower",nil];
            [dictArr addObject:dict];
        }
        
        NSData *jsonData  =[self toJSONData: dictArr];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                     encoding:NSUTF8StringEncoding];
        NSString *jsonDataString = [NSString stringWithFormat:@"show(%@)", jsonString];
        [self.myWebView stringByEvaluatingJavaScriptFromString:jsonDataString];
        return false;
    }
    return true;
}

- (NSData *)toJSONData:(id)theData{
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:theData options:NSJSONWritingPrettyPrinted error:&error];
    if ([jsonData length] > 0 && error == nil){
        return jsonData;
    }else{
        return nil;
    }
}

#pragma mark - Common
- (void)createBeaconRegion
{
    if (self.beaconRegion)
        return;
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:kUUID];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:kIdentifier];
    self.beaconRegion.notifyEntryStateOnDisplay = YES;
}

- (void)createLocationManager
{
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
}

- (void)startRangingForBeacons
{
    self.operationContext = kRangingOperationContext;
    
    [self createLocationManager];
    
    [self checkLocationAccessForRanging];
    
    self.detectedBeacons = [NSArray array];
    [self turnOnRanging];
}

- (void)turnOnRanging
{
    NSLog(@"Turning on ranging...");
    
    if (![CLLocationManager isRangingAvailable]) {
        NSLog(@"Couldn't turn on ranging: Ranging is not available.");
        self.rangingSwitch.on = NO;
        return;
    }
    
    if (self.locationManager.rangedRegions.count > 0) {
        NSLog(@"Didn't turn on ranging: Ranging already on.");
        return;
    }
    
    [self createBeaconRegion];
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
    
    NSLog(@"Ranging turned on for region: %@.", self.beaconRegion);
}

- (void)stopRangingForBeacons
{
    if (self.locationManager.rangedRegions.count == 0) {
        NSLog(@"Didn't turn off ranging: Ranging already off.");
        return;
    }
    
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
    
    self.detectedBeacons = [NSArray array];
    
    NSLog(@"Turned off ranging.");
}

#pragma mark - Location manager delegate methods
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (![CLLocationManager locationServicesEnabled]) {
        NSLog(@"Couldn't turn on ranging: Location services are not enabled.");
        self.rangingSwitch.on = NO;
        return;
        
    }
    
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    switch (authorizationStatus) {
        case kCLAuthorizationStatusAuthorizedAlways:
            self.rangingSwitch.on = YES;
            return;
            
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            self.rangingSwitch.on = YES;
            
            return;
            
        default:
            NSLog(@"Couldn't turn on monitoring: Required Location Access(WhenInUse) missing.");
            self.rangingSwitch.on = NO;
            return;
            break;
    }
}

- (NSArray *)filteredBeacons:(NSArray *)beacons
{
    // Filters duplicate beacons out; this may happen temporarily if the originating device changes its Bluetooth id
    NSMutableArray *mutableBeacons = [beacons mutableCopy];
    
    NSMutableSet *lookup = [[NSMutableSet alloc] init];
    for (int index = 0; index < [beacons count]; index++) {
        CLBeacon *curr = [beacons objectAtIndex:index];
        NSString *identifier = [NSString stringWithFormat:@"%@/%@", curr.major, curr.minor];
        
        // this is very fast constant time lookup in a hash table
        if ([lookup containsObject:identifier]) {
            [mutableBeacons removeObjectAtIndex:index];
        } else {
            [lookup addObject:identifier];
        }
    }
    
    return [mutableBeacons copy];
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region {
    NSArray *filteredBeacons = [self filteredBeacons:beacons];
    
    if (filteredBeacons.count == 0) {
        NSLog(@"No beacons found nearby.");
    } else {
        NSLog(@"Found %lu %@.", (unsigned long)[filteredBeacons count],
              [filteredBeacons count] > 1 ? @"beacons" : @"beacon");
        
    }
    self.detectedBeacons = filteredBeacons;
}

#pragma mark - Location access methods (iOS8/Xcode6)
- (void)checkLocationAccessForRanging {
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
}

@end

