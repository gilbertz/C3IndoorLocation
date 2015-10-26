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
@property (strong, nonatomic) UIImagePickerController *picker;
@property (weak, nonatomic) IBOutlet UIView *controlsView;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceTitleLabel;
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
    [self.view setTranslatesAutoresizingMaskIntoConstraints:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self startRangingForBeacons];
    self.myWebView.delegate=self;
    self.myWebView.scalesPageToFit = YES;
    
    NSString *localHTMLPageFilePath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    NSURL *localHTMLPageFileURL = [NSURL fileURLWithPath:localHTMLPageFilePath];
    [self.myWebView loadRequest:[NSURLRequest requestWithURL:localHTMLPageFileURL]];
    
    self.picker = [[UIImagePickerController alloc] init];
    self.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.picker.showsCameraControls = NO;
    self.picker.navigationBarHidden = YES;
    self.picker.toolbarHidden = YES;
    //    self.picker.cameraViewTransform =
    //    CGAffineTransformScale(self.picker.cameraViewTransform,
    //                           1.0,
    //                           (self.view.frame.size.height -
    //                            self.controlsView.frame.size.height) /
    //                           self.view.frame.size.width);
    
    UIView *overlayView =
    [[UIView alloc] initWithFrame:self.view.frame];
    
    overlayView.opaque = NO;
    overlayView.backgroundColor = [UIColor clearColor];
    
    [self setupArrowViewInView:overlayView];
    self.controlsView.alpha = 0.5;
    [overlayView addSubview:self.controlsView];
    [overlayView addSubview:self.distanceLabel];
    [overlayView addSubview:self.locationLabel];
    [overlayView addSubview:self.locationTitleLabel];
    [overlayView addSubview:self.distanceTitleLabel];
    [overlayView addSubview:self.navigationLabel];
    [overlayView addSubview:self.navigationTitleLabel];
    
    self.picker.cameraOverlayView = overlayView;
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
    if ([sender.titleLabel.text isEqualToString:@"Featheringill Hall"]) {
        self.arrowView.destination =
        [[CLLocation alloc] initWithLatitude:36.1447809
                                   longitude:-86.8032186];
    } else if ([sender.titleLabel.text isEqualToString:@"Roma"]) {
        self.arrowView.destination =
        [[CLLocation alloc] initWithLatitude:36.1480013
                                   longitude:-86.8083296];
    } else if ([sender.titleLabel.text isEqualToString:@"Ben & Jerry's"]) {
        self.arrowView.destination =
        [[CLLocation alloc] initWithLatitude:36.146143
                                   longitude:-86.7994725];
    } else if ([sender.titleLabel.text isEqualToString:@"Qdoba"]) {
        self.arrowView.destination =
        [[CLLocation alloc] initWithLatitude:36.1504781
                                   longitude:-86.8008202];
    }else if ([sender.titleLabel.text isEqualToString:@"R208"]) {
        self.arrowView.destination =
        [[CLLocation alloc] initWithLatitude:31.02608
                                   longitude:121.43825];
    }
    
    self.locationLabel.text = sender.titleLabel.text;
    self.distanceLabel.text = [self.arrowView.locationManager distanceToLocation:self.arrowView.destination];
    
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ( [request.mainDocumentURL.relativePath isEqualToString:@"/click/false"] ) {
        NSLog( @"not clicked" );
        return false;
    }
    
    if ( [request.mainDocumentURL.relativePath isEqualToString:@"/generateNavigation"] ) {
        NSLog( @"not clicked" );
        return false;
    }
    
    NSString *requestString = [[request URL]absoluteString];//获取请求的绝对路径.
    //提交请求时候分割参数的分隔符
    NSArray *components = [requestString componentsSeparatedByString:@":"];
    NSString *direction = @"";
    NSString *distance = @"";
    if ([components count] >1 && [(NSString *)[components objectAtIndex:0]isEqualToString:@"generateNavigation"]) {
        //过滤请求是否是我们需要的.不需要的请求不进入条件
            if([(NSString *)[components objectAtIndex:0]isEqualToString:@"right"])
            {
                direction = @"右转";
            }else if([(NSString *)[components objectAtIndex:0]isEqualToString:@"left"]){
                direction = @"左转";
            }else if([(NSString *)[components objectAtIndex:0]isEqualToString:@"straight"]){
                direction = @"直行";
            }
        distance = [components objectAtIndex:1];
    }
    self.navigationLabel.text = [distance stringByAppendingString:direction];

    
    if ( [request.mainDocumentURL.relativePath isEqualToString:@"/click/true"] ) {        //the image is clicked, variable click is true
        NSLog( @"image clicked" );
        
        //        [myWebView stringByEvaluatingJavaScriptFromString:@"show([{'minor':4215,'major':10004,'rssi':42,'measuredPower': 59},{'minor':4332,'major':10004,'rssi':49,'measuredPower': 59},{'minor':4180,'major':10004,'rssi':45,'measuredPower': 59},{'minor':4218,'major':10004,'rssi':43,'measuredPower': 59}])"];
        //        NSString *str = [self.detectedBeacons componentsJoinedByString:@","];
        //        NSLog(str);
        //        NSLog(@"params:%@",self.detectedBeacons);
        //        NSData *jsonData  =[self toJSONData : self.detectedBeacons];
        //        NSString *jsonString = [[NSString alloc] initWithData:jsonData
        //                                                     encoding:NSUTF8StringEncoding];
        //        NSLog(jsonString);
        //        NSError* error = nil;
        //        NSString *result = [NSJSONSerialization dataWithJSONObject:self.detectedBeacons
        //                                                    options:kNilOptions error:&error];
        //        NSLog(result);
        //                CLBeacon *beacon = self.detectedBeacons[0];
        //                [self detailsStringForBeacon:beacon];
        //        NSLog([self detailsStringForBeacon:beacon]);
        
        
        NSMutableArray *dictArray = self.detectedBeacons;
        NSMutableArray *dictArr = [NSMutableArray array];
        for (int i = 0; i < dictArray.count; i++) {
            CLBeacon *beacon = self.detectedBeacons[i];
            //            NSUInteger anInteger = [beacon.rssi integerValue];
            NSString *rssiString = [NSString stringWithFormat:@"%li", abs(beacon.rssi)];
            NSDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:[beacon.minor floatValue]],@"minor",[NSNumber numberWithFloat:[beacon.major floatValue]],@"major", [NSNumber numberWithInt:[rssiString intValue]] ,@"rssi",[NSNumber numberWithInt:59],@"measuredPower",nil];
            [dictArr addObject:dict];
        }
        //                NSLog(@"params:%@",dictArr);
        NSData *jsonData  =[self toJSONData : dictArr];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                     encoding:NSUTF8StringEncoding];
        //                NSLog(jsonString);
        NSString *jsonDataString = [NSString stringWithFormat:@"show(%@)", jsonString];
        //        NSLog(jsonDataString);
        [self.myWebView stringByEvaluatingJavaScriptFromString:jsonDataString];
        //                [myWebView stringByEvaluatingJavaScriptFromString:@"show([{'minor':4215,'major':10004,'rssi':42,'measuredPower': 59},{'minor':4332,'major':10004,'rssi':49,'measuredPower': 59},{'minor':4180,'major':10004,'rssi':45,'measuredPower': 59},{'minor':4218,'major':10004,'rssi':43,'measuredPower': 59}])"];
        
        
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

#pragma mark - Table view functionality
- (NSString *)detailsStringForBeacon:(CLBeacon *)beacon
{
    NSString *proximity;
    switch (beacon.proximity) {
        case CLProximityNear:
            proximity = @"Near";
            break;
        case CLProximityImmediate:
            proximity = @"Immediate";
            break;
        case CLProximityFar:
            proximity = @"Far";
            break;
        case CLProximityUnknown:
        default:
            proximity = @"Unknown";
            break;
    }
    
    NSString *format = @"%@, %@ • %@ • %f • %li";
    //    NSLog(format);
    return [NSString stringWithFormat:format, beacon.major, beacon.minor, proximity, beacon.accuracy, beacon.rssi];
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

