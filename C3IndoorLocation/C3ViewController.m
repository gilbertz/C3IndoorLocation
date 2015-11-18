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
#import "C3LeftArrowView.h"
#import "C3Layer.h"
#import "C3LeftTurnLayer.h"
#import "C3RightTurnLayer.h"

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
@property (strong, nonatomic) C3LeftArrowView *leftArrowView;

@property (weak, nonatomic) IBOutlet UILabel *navigationLabel;
@property (weak, nonatomic) IBOutlet UILabel *navigationTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceTitleLabel;
@property (strong, nonatomic) UIImagePickerController *picker;
@property (weak, nonatomic) IBOutlet UIView *controlsView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) NSArray *detectedBeacons;
@property (nonatomic, weak) UISwitch *rangingSwitch;
@property (nonatomic, unsafe_unretained) void *operationContext;
@property (strong, nonatomic) IBOutlet UIWebView *myWebView;
@property (strong, nonatomic)UIView *overlayView;
@property (strong, nonatomic)C3RightTurnLayer *rightTurnLayer;
@property (strong, nonatomic)C3Layer *straightLayer;
@property (strong, nonatomic)C3LeftTurnLayer *leftTurnLayer;
@property (assign, nonatomic) BOOL isAddSublayer;
@property (strong, nonatomic)CATransformLayer *container;
@property (strong, nonatomic)UITableView *tableView;
@property (strong, nonatomic)NSArray *destinationArray;

@end

@implementation C3ViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    //不使用AutoLayout的方式来布局
    [self.view setTranslatesAutoresizingMaskIntoConstraints:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    //开始搜寻beacon
    [self startRangingForBeacons];
    
    //打开摄像头背景
    self.picker = [[UIImagePickerController alloc] init];
    self.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.picker.showsCameraControls = NO;
    self.picker.navigationBarHidden = YES;
    self.picker.toolbarHidden = YES;
    
    //叠加摄像头上的overlay
    self.overlayView = [[UIView alloc] initWithFrame:self.view.frame];
    
    //overlay的背景透明
    self.overlayView.opaque = NO;
    self.overlayView.backgroundColor = [UIColor clearColor];
    
    //功能面板透明度
    self.controlsView.alpha = 0.9;
    //overlay上添加右侧的功能面板
    [self.overlayView addSubview:self.controlsView];
    //overlay上添加箭头
    [self setupArrowViewInView:self.overlayView];
    
    //1.创建自定义的layer
//    C3Layer *layer=[C3Layer layer];
//    layer.bounds=CGRectMake(0, 0, 100, 300);
//    layer.anchorPoint=CGPointMake(0.5, 0.5);
    
//    C3LeftTurnLayer *layer = [C3LeftTurnLayer layer];
//    layer.bounds=CGRectMake(0, 0, 200, 300);
//    layer.anchorPoint=CGPointMake(0.75, 0.5);
    //overlay上添加目的地、距离、导航信息
    [self.overlayView addSubview:self.distanceLabel];
    [self.overlayView addSubview:self.locationLabel];
    [self.overlayView addSubview:self.locationTitleLabel];
    [self.overlayView addSubview:self.distanceTitleLabel];
    [self.overlayView addSubview:self.navigationLabel];
    [self.overlayView addSubview:self.navigationTitleLabel];
    //overlay置为camera视图的view
    self.picker.cameraOverlayView = self.overlayView;

    //controlsView上的mywebview
    NSString *localHTMLPageFilePath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    NSURL *localHTMLPageFileURL = [NSURL fileURLWithPath:localHTMLPageFilePath];
    [self.myWebView loadRequest:[NSURLRequest requestWithURL:localHTMLPageFileURL]];
    
    self.myWebView.delegate=self;
    self.myWebView.scalesPageToFit = YES;
    
    self.destinationArray = @[@"208",@"209"];
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.frame = CGRectMake(512, 0, 512, 768);

}

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

- (void)viewDidAppear:(BOOL)animated
{
    [self presentViewController:self.picker animated:NO completion:nil];
}

#pragma mark - Setup

- (void)setupArrowViewInView:(UIView *)view
{
    CGRect frame = CGRectMake(2.0*view.frame.size.width / 10.0,
                              4*view.frame.size.height / 6.0,
                              1.0 * view.frame.size.width / 10.0,
                              1* view.frame.size.height / 6.0);
    self.arrowView = [[C3ArrowView alloc] initWithFrame:frame];
    self.arrowView.delegate = self;
    [view addSubview:self.arrowView];
    
//    CGRect frame2 = CGRectMake(2.0*view.frame.size.width / 10.0,
//                              2*view.frame.size.height / 6.0,
//                              1.0 * view.frame.size.width / 10.0,
//                              1* view.frame.size.height / 6.0);
//    self.leftArrowView = [[C3LeftArrowView alloc] initWithFrame:frame2];
//    [view addSubview:self.leftArrowView];
}

#pragma mark - NAArrowViewDelegate

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
//        self.distanceLabel.text = [manager distanceToLocation:self.arrowView.destination];
}

#pragma mark - Button actions
- (IBAction)buttonPressed:(UIButton *)sender {
    [self.overlayView addSubview:self.tableView];
    
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
            //过滤请求是否是我们需要的.不需要的请求不进入条件
            if([(NSString *)[components objectAtIndex:1]isEqualToString:@"right"])
            {
                direction = @"右转";
                self.rightTurnLayer = [C3RightTurnLayer layer];
                self.rightTurnLayer.bounds=CGRectMake(0, 0, 200, 300);
                self.rightTurnLayer.anchorPoint=CGPointMake(0.25, 0.5);
                //2.设置layer的属性
                self.rightTurnLayer.backgroundColor=[UIColor clearColor].CGColor;
                self.rightTurnLayer.position=CGPointMake(2.5*self.view.frame.size.width / 10.0,
                                           2*self.view.frame.size.height / 6.0);
                [self.rightTurnLayer setNeedsDisplay];
                CATransform3D transform = CATransform3DMakeRotation(M_PI/3, 1, 0, 0);
                self.rightTurnLayer.transform =  CATransform3DPerspect(transform, CGPointMake(0, 0), 200);
                [self.container removeFromSuperlayer];
                self.container = [[CATransformLayer alloc] init];
                //3.添加layer
                [self.container addSublayer:self.rightTurnLayer];
                [self.overlayView.layer addSublayer:self.container];

            }else if([(NSString *)[components objectAtIndex:1]isEqualToString:@"left"]){
                direction = @"左转";
            }else if([(NSString *)[components objectAtIndex:1]isEqualToString:@"straight"]){
                direction = @"直行";
                self.straightLayer = [C3Layer layer];
                self.straightLayer.bounds=CGRectMake(0, 0, 200, 300);
                self.straightLayer.anchorPoint=CGPointMake(0.25, 0.5);
                //2.设置layer的属性
                self.straightLayer.backgroundColor=[UIColor clearColor].CGColor;
                self.straightLayer.position=CGPointMake(2.5*self.view.frame.size.width / 10.0,
                                                         2*self.view.frame.size.height / 6.0);
                [self.straightLayer setNeedsDisplay];
                CATransform3D transform = CATransform3DMakeRotation(M_PI/3, 1, 0, 0);
                self.straightLayer.transform =  CATransform3DPerspect(transform, CGPointMake(0, 0), 200);
                [self.container removeFromSuperlayer];
                self.container = [[CATransformLayer alloc] init];
                //3.添加layer
                [self.container addSublayer:self.straightLayer];
                [self.overlayView.layer addSublayer:self.container];
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
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:theData
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
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

