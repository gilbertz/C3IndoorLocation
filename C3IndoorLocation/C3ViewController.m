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

@interface C3ViewController ()<C3ArrowViewDelegate,UIWebViewDelegate,CLLocationManagerDelegate, CBPeripheralManagerDelegate>

@property (strong, nonatomic) C3ArrowView *arrowView;
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
    UIView *overlayView = [[UIView alloc] initWithFrame:self.view.frame];
    
    //overlay的背景透明
    overlayView.opaque = NO;
    overlayView.backgroundColor = [UIColor clearColor];
    
    //功能面板透明度
    self.controlsView.alpha = 0.9;
    //overlay上添加右侧的功能面板
    [overlayView addSubview:self.controlsView];
    //overlay上添加箭头
    [self setupArrowViewInView:overlayView];
    //overlay上添加目的地、距离、导航信息
    [overlayView addSubview:self.distanceLabel];
    [overlayView addSubview:self.locationLabel];
    [overlayView addSubview:self.locationTitleLabel];
    [overlayView addSubview:self.distanceTitleLabel];
    [overlayView addSubview:self.navigationLabel];
    [overlayView addSubview:self.navigationTitleLabel];
    //overlay置为camera视图的view
    self.picker.cameraOverlayView = overlayView;

    //controlsView上的mywebview
    NSString *localHTMLPageFilePath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    NSURL *localHTMLPageFileURL = [NSURL fileURLWithPath:localHTMLPageFilePath];
    [self.myWebView loadRequest:[NSURLRequest requestWithURL:localHTMLPageFileURL]];
    
    self.myWebView.delegate=self;
    self.myWebView.scalesPageToFit = YES;
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
}

#pragma mark - Button actions
- (IBAction)buttonPressed:(UIButton *)sender {
    if ([sender.titleLabel.text isEqualToString:@"R208"]) {
        self.arrowView.destination =
        [[CLLocation alloc] initWithLatitude:31.02608
                                   longitude:121.43825];
        NSString *jsonDataString = [NSString stringWithFormat:@"button(%@)", @"R208"];
        [self.myWebView stringByEvaluatingJavaScriptFromString:jsonDataString];
    }
    
    self.locationLabel.text = sender.titleLabel.text;
    
    if (!self.arrowView.isPointing) {
        [self.arrowView startPointing];
    }
}

#pragma mark - NAArrowViewDelegate

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    self.distanceLabel.text = [manager distanceToLocation:self.arrowView.destination];
}

#pragma mark UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    //获取请求的绝对路径.
    NSString *requestString = [[request URL]absoluteString];
    //提交请求时候分割参数的分隔符

    NSArray *components = [requestString componentsSeparatedByString:@":"];
    NSString *direction = @"";
    NSString *distance = @"";
    NSString *totalDistance = @"";

    //判断是否是产生距离信息的url
    BOOL equal = [(NSString *)[components objectAtIndex:0]isEqualToString:@"generate"];
    if (equal) {
            //过滤请求是否是我们需要的.不需要的请求不进入条件
            if([(NSString *)[components objectAtIndex:1]isEqualToString:@"right"])
            {
                direction = @"右转";
            }else if([(NSString *)[components objectAtIndex:1]isEqualToString:@"left"]){
                direction = @"左转";
            }else if([(NSString *)[components objectAtIndex:1]isEqualToString:@"straight"]){
                direction = @"直行";
            }
        distance = [components objectAtIndex:2];
        distance = [NSString stringWithFormat:@"%ld", [distance integerValue]/ARCHITECTSCALE ];
        distance = [distance stringByAppendingString:@" meters "];
        self.navigationLabel.text = [distance stringByAppendingString:direction];
        totalDistance = [components objectAtIndex:3];
        totalDistance = [NSString stringWithFormat:@"%ld", [totalDistance integerValue]/ARCHITECTSCALE ];
        totalDistance = [totalDistance stringByAppendingString:@" meters "];
        self.distanceLabel.text = totalDistance;
        
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

