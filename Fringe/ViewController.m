//
//  ViewController.m
//  ScanBeaconSample
//
//  Created by Manish on 10/10/13.
//  Copyright (c) 2013 Self. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MKMapView.h>
#import <MapKit/MKUserLocation.h>
#import <Firebase/Firebase.h>
#import <MapKit/MKPointAnnotation.h>

@interface ViewController ()<CLLocationManagerDelegate,CBPeripheralManagerDelegate>{
    BOOL turnAdvertisingOn;
}

#define TRANSFER_SERVICE_UUID           @"E20A39F4-73F5-4BC4-A12F-17D1AD07A961"
#define TRANSFER_CHARACTERISTIC_UUID    @"08590F7E-DB05-467E-8757-72F6FAEB13D4"

#define NOTIFY_MTU      20

@property (weak, nonatomic) IBOutlet UISwitch *mySwitch;
@property (weak, nonatomic) IBOutlet UIButton *locationButton;
@property (weak, nonatomic) IBOutlet UIView *frostedView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

// Peripheral
@property (strong, nonatomic) CBMutableCharacteristic   *transferCharacteristic;
@property (strong, nonatomic) NSData                    *dataToSend;
@property (nonatomic, readwrite) NSInteger              sendDataIndex;

// Central
@property (strong, nonatomic) CBCentralManager      *centralManager;
@property (strong, nonatomic) CBPeripheral          *discoveredPeripheral;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;
@property (strong, nonatomic) NSMutableData         *data;

//@property (weak, nonatomic) IBOutlet UINavigationItem *navItem;
//@property (weak, nonatomic) IBOutlet UINavigationBar *navBar;
@property NSInteger *count;
@property BOOL first_time;

@end

@implementation ViewController

- (IBAction)infoClick:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Brim is a bluetooth app which allows you to see your friends nearby and receive background notifications." message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    [alert show];
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    // Start up the CBCentralManager
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    // And somewhere to store the incoming data
    _data = [[NSMutableData alloc] init];

//    UIToolbar *toolBar = [[UIToolbar alloc] init];
//    [toolBar setFrame:CGRectMake(0.0,0.0,320.0,180.0)];
//    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
//        [toolBar setAlpha:0.9];
//    }
//    [self.frostedView addSubview:toolBar];
    
    self.frostedView.alpha = 0.8;
    
    self.first_time = true;
    
    _mapView.showsUserLocation = true;
    _mapView.delegate = self;
    
    [self.mySwitch addTarget:self action:@selector(changeSwitch:) forControlEvents:UIControlEventValueChanged];
    
//    MKUserLocation *userLocation = _mapView.userLocation;
//    MKCoordinateRegion region =
//    MKCoordinateRegionMakeWithDistance (
//                                        userLocation.location.coordinate, 20000, 20000);
//    [_mapView setRegion:region animated:NO];
    
//    UIImage *image = [UIImage imageNamed:@"bluelgo.png"];
//    UIImage *myIcon = [ViewController imageWithImage:image scaledToSize:CGSizeMake(35, 35)];
//    self.navItem.titleView = [[UIImageView alloc] initWithImage:myIcon];
    
//    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navbar.png"] forBarMetrics:UIBarMetricsDefault];
    
    self.count = 0;
	// Do any additional setup after loading the view, typically from a nib.
    
    // Set up web view here
    //NSURL *websiteUrl = [NSURL URLWithString:@"http://getblue.herokuapp.com"];
    //NSURLRequest *urlRequest = [NSURLRequest requestWithURL:websiteUrl];
    //[self.webView loadRequest:urlRequest];
    
    [self setoutofrangeColor];
    
    [self currentLocationIdentifier];
    [self initiatePeripheralManagerForBeaconBroadcast];
    [self startRanging];
}

- (void)changeSwitch:(id)sender{
    if([sender isOn]){
        NSLog(@"Switch is ON");
        [self currentLocationIdentifier];
        [self initiatePeripheralManagerForBeaconBroadcast];
        [self startRanging];
    } else{
        NSLog(@"Switch is OFF");
        [self stopBeaconBroadCast];
        [self stopRanging];
        [self setoutofrangeColor];
        [self.centralManager stopScan];
        // Remove annotations
        NSMutableArray * annotationsToRemove = [ self.mapView.annotations mutableCopy ] ;
        [ annotationsToRemove removeObject:self.mapView.userLocation ] ;
        [ self.mapView removeAnnotations:annotationsToRemove ] ;
    }
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    [ self firebaseCallWithLatitude:userLocation];
    if (self.first_time) {
        MKCoordinateRegion mapRegion;
        mapRegion.center = mapView.userLocation.coordinate;
        mapRegion.span.latitudeDelta = 0.2;
        mapRegion.span.longitudeDelta = 0.2;
    
        [mapView setRegion:mapRegion animated: YES];
        self.first_time = false;
        
    }
}

-(void) firebaseCallWithLatitude:(MKUserLocation *)userLocation {
    NSNumber *lat = [NSNumber numberWithDouble:userLocation.coordinate.latitude];
    NSNumber *lng = [NSNumber numberWithDouble:userLocation.coordinate.longitude];
    NSArray *location = [NSArray arrayWithObjects: [lat stringValue], [lng stringValue], nil];
    
    
    Firebase* myRootRef = [[Firebase alloc] initWithUrl:@"https://blue-outsidehacks.firebaseio.com/"];
    Firebase* test = [myRootRef childByAppendingPath:(NSString *)@"/Danish Shaik"];
    // Write data to Firebase
    [test setValue:location];

    
    
    // Read data and react to changes
    [test observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSLog(snapshot.name, snapshot.value);
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        annotation.coordinate = CLLocationCoordinate2DMake([lat doubleValue], [lng doubleValue]);
        annotation.title = snapshot.name;
//        if (![snapshot.name isEqualToString:@"Danish Shaik"]) {
        
        [_mapView removeAnnotations:_mapView.annotations];
        
        [_mapView addAnnotation:annotation];
//
  //  }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
//    NSLog(@"OldLocation %f %f", oldLocation.coordinate.latitude, oldLocation.coordinate.longitude);
//    NSLog(@"NewLocation %f %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
//}

- (void)currentLocationIdentifier {
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [_locationManager startUpdatingLocation];
    
    NSLog(@"%f", _locationManager.location.coordinate.latitude);
    NSLog(@"%f", _locationManager.location.coordinate.longitude);
    
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

-(UIColor*)colorWithHexString:(NSString*)hex
{
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor grayColor];
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    
    if ([cString length] != 6) return  [UIColor grayColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}

#pragma mark - Interaction

//-(IBAction)toggleBroadcasting:(UISwitch *)broadcastingSwitch{
//    BOOL flag = broadcastingSwitch.on;
//    if (flag) {
//        [self initiatePeripheralManagerForBeaconBroadcast];
//    }
//    else{
//        [self stopBeaconBroadCast];
//    }
//}
//
//-(IBAction)toggleRanging:(UISwitch *)rangingSwitch{
//    BOOL flag = rangingSwitch.on;
//    if (flag) {
//        [self startRanging];
//    }
//    else{
//        [self stopRanging];
//    }
//}


#pragma mark - Beacon Range
-(void)startRanging{
    
    // Start annotation
    
    // Annotation should actually be
//    NSString *latitudeString = @"37.312821";
//    NSAssert(latitudeString, @"No latitude");
//    NSString *longitudeString = @"-122.071024";
//    NSAssert(longitudeString, @"No longitude");
//    
//    // create the annotation and add it to the map
//    
//    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
//    annotation.coordinate = CLLocationCoordinate2DMake([latitudeString doubleValue], [longitudeString doubleValue]);
//    annotation.title = @"Danish";
//    annotation.subtitle = @"10707 Santa Lucia Rd";
//    [self.mapView addAnnotation:annotation];
    
    // End annotation

    
    //Check if monitoring is available or not
    if (![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Monitoring not available" message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    if (_locationManager!=nil) {
        if(region){
            region.notifyOnEntry = YES;
            region.notifyOnExit = YES;
            region.notifyEntryStateOnDisplay = YES;
            [_locationManager startMonitoringForRegion:region];
            [_locationManager startRangingBeaconsInRegion:region];
            
        }
        else{
            _uuid = [[NSUUID alloc] initWithUUIDString:@"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"];
            _locationManager = [[CLLocationManager alloc] init];
            _locationManager.delegate = self;
            region = [[CLBeaconRegion alloc] initWithProximityUUID:_uuid identifier:@"COM.SELF.ID"];
            if(region){
                region.notifyOnEntry = YES;
                region.notifyOnExit = YES;
                region.notifyEntryStateOnDisplay = YES;
                [_locationManager startMonitoringForRegion:region];
                [_locationManager startRangingBeaconsInRegion:region];
                
            }
        }
    }
    else{
        _uuid = [[NSUUID alloc] initWithUUIDString:@"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"];
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        region = [[CLBeaconRegion alloc] initWithProximityUUID:_uuid identifier:@"COM.SELF.ID"];
        if(region){
            region.notifyOnEntry = YES;
            region.notifyOnExit = YES;
            region.notifyEntryStateOnDisplay = YES;
            [_locationManager startMonitoringForRegion:region];
            [_locationManager startRangingBeaconsInRegion:region];
            
        }
    }
}



-(void)stopRanging{
    [_locationManager stopRangingBeaconsInRegion:region];
    [_locationManager stopMonitoringForRegion:region];
}

#pragma mark - Beacon broadcast

-(void)initiatePeripheralManagerForBeaconBroadcast{
    if (_peripheralManager) {
        [self advertiseBeacon];
        return;
    }
    
    //This starts a check on the update state delegate to see if bluetooth is powered on or not
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    turnAdvertisingOn = YES;
}

-(void)stopBeaconBroadCast{
    if (_peripheralManager) {
        turnAdvertisingOn = NO;
        [_peripheralManager stopAdvertising];
    }
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    NSLog(@"peripheral %@",peripheral);
    
    //Check if the BLE state was on or not
    if (peripheral.state == CBPeripheralManagerStatePoweredOn && turnAdvertisingOn) {
        [self advertiseBeacon];
    }
}

-(void)advertiseBeacon{
    _uuid = [[NSUUID alloc] initWithUUIDString:@"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"];
    _power = @(broadcastpower);
    CLBeaconRegion *newregion = [[CLBeaconRegion alloc] initWithProximityUUID:_uuid major:10 minor:5 identifier:@"COM.SELF.ID"];
    NSMutableDictionary *peripheralData = [newregion peripheralDataWithMeasuredPower:_power];
    
    NSLog(@"start advertising %@",peripheralData);
    //Advertise the same beacon region and Range the same beacon region
    [_peripheralManager startAdvertising:peripheralData];
    
}

#pragma mark - set range colors

-(void)setinrangeColor{
    self.count = 0;
    [self.locationButton setBackgroundImage:[UIImage imageNamed:@"location.png"] forState:UIControlStateNormal];
    self.view.backgroundColor = [self colorWithHexString:@"2ECC71"];
}

-(void)setoutofrangeColor{
    [self.locationButton setBackgroundImage:[UIImage imageNamed:@"red_location.png"] forState:UIControlStateNormal];
    self.view.backgroundColor = [self colorWithHexString:@"e74c3c"];
    
}

-(void)setfarrangeColor{
    [self.locationButton setBackgroundImage:[UIImage imageNamed:@"yellow_location.png"] forState:UIControlStateNormal];
    self.view.backgroundColor = [self colorWithHexString:@"f1c40f"];
}



#pragma mark - Location manager beacon region delegate

-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region{
    NSLog(@"Enter Region  %@",region);
    [_locationManager startRangingBeaconsInRegion:region];
//    [self sendLocalNotificationForReqgionConfirmationWithText:@"Friends within range!"];
    [self setinrangeColor];
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region{
    NSLog(@"Exit Region  %@",region);
//    [self sendLocalNotificationForReqgionConfirmationWithText:@"Away from your friends!"];
    [_locationManager stopRangingBeaconsInRegion:region];
    [self setoutofrangeColor];
}

-(void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region{
    NSLog(@"Monitoring for %@",region);
    //[self sendLocalNotificationForReqgionConfirmationWithText:@"MONITORING STARTED"];
    
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region{
    if (state == CLRegionStateInside) {
        [_locationManager startRangingBeaconsInRegion:region];
//        [self sendLocalNotificationForReqgionConfirmationWithText:@"REGION INSIDE"];
        [self setinrangeColor];
    }
    else{
        //[[BluetoothManager shared] scan];
        [self sendLocalNotificationForReqgionConfirmationWithText:@"Away from your friends!"];
        [_locationManager stopRangingBeaconsInRegion:region];
        [self setoutofrangeColor];
        
    }
    //[_locationManager startRangingBeaconsInRegion:region];
    
}

-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    
    NSArray *unknownBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityUnknown]];
    if([unknownBeacons count]){
        NSLog(@"unknown beacons %@",unknownBeacons);
        [self setoutofrangeColor];
    }
    
    NSArray *immediateBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityImmediate]];
    if([immediateBeacons count]){
        NSLog(@"immediate beacons %@",immediateBeacons);
        [self setinrangeColor];
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ROFL"
//                                                        message:@"Dee dee doo doo."
//                                                       delegate:self
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
//        [alert show];
//        isSHowing = true;
    }
    
    
    NSArray *nearBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityNear]];
    if([nearBeacons count]){
        NSLog(@"near beacons %@",nearBeacons);
        [self setinrangeColor];
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ROFL"
//                                                        message:@"Dee dee doo doo."
//                                                       delegate:self
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
//        [alert show];
//                prox = true;
        
    }
    
    
    NSArray *farBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityFar]];
    if([farBeacons count]){
        NSLog(@"far beacons %@",farBeacons);
        [self setfarrangeColor];
        
        
        
        MKCoordinateRegion mapRegion;
        mapRegion.center = _mapView.userLocation.coordinate;
        mapRegion.span.latitudeDelta = 0.02;
        mapRegion.span.longitudeDelta = 0.02;
        
        [_mapView setRegion:mapRegion animated: YES];
        self.first_time = false;
        
        
        NSString *lat = [NSString stringWithFormat:@"%2f", _mapView.userLocation.coordinate.latitude];
        NSString *lon = [NSString stringWithFormat:@"%2f", _mapView.userLocation.coordinate.longitude];
        
        //        NSArray *location = [NSString stringWithFormat:@"%@,%@", lat, lon];
        
        
        
        
        
        
//        if (!isShowing) {
            for (UIWindow* window in [UIApplication sharedApplication].windows){
                for (UIView *subView in [window subviews]){
                    if ([subView isKindOfClass:[UIAlertView class]]) {
                        
                    }else {
                        if (self.count < 1) {
                            self.count++;
                            // Uncomment if need alert view
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Proximity Alert"
                                                                            message:@"Some of your friends are leaving range."
                                                                           delegate:self
                                                                  cancelButtonTitle:nil
                                                                  otherButtonTitles:@"OK", nil];
                            [alert show];
                        }
                    }
                }
//            }
        }
    }
    
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
//   isShowing = false;
}

-(void)sendLocalNotificationForReqgionConfirmationWithText:(NSString *)text {
    
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    if (localNotif == nil)
        return;
    
    localNotif.timeZone = [NSTimeZone defaultTimeZone];
    
    localNotif.alertBody = [NSString stringWithFormat:NSLocalizedString(@"%@", nil),
                            text];
    localNotif.alertAction = NSLocalizedString(@"View Details", nil);
    
    localNotif.applicationIconBadgeNumber = 1;
    
    NSDictionary *infoDict = [NSDictionary dictionaryWithObject:text forKey:@"KEY"];
    localNotif.userInfo = infoDict;
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
    
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification NS_AVAILABLE_IOS(4_0){
    UIAlertView *alert  = [[UIAlertView alloc] initWithTitle:notification.alertBody message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

- (NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Central Methods



/** centralManagerDidUpdateState is a required protocol method.
 *  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
 *  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
 *  the Central is ready to be used.
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn) {
        // In a real app, you'd deal with all the states correctly
        return;
    }
    
    // The state must be CBCentralManagerStatePoweredOn...
    
    // ... so start scanning
    [self scan];
    
}


/** Scan for peripherals - specifically for our service's 128bit CBUUID
 */
- (void)scan
{
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    
    NSLog(@"Scanning started");
}


/** This callback comes whenever a peripheral that is advertising the TRANSFER_SERVICE_UUID is discovered.
 *  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is,
 *  we start the connection process
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // Reject any where the value is above reasonable range
    if (RSSI.integerValue > -15) {
        return;
    }
    
    // Reject if the signal strength is too low to be close enough (Close is around -22dB)
    if (RSSI.integerValue < -35) {
        return;
    }
    
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    
    // Ok, it's in range - have we already seen it?
    if (self.discoveredPeripheral != peripheral) {
        
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
        self.discoveredPeripheral = peripheral;
        
        // And connect
        NSLog(@"Connecting to peripheral %@", peripheral);
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}


/** If the connection fails for whatever reason, we need to deal with it.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    [self cleanup];
}


/** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral Connected");
    
    // Stop scanning
    [self.centralManager stopScan];
    NSLog(@"Scanning stopped");
    
    // Clear the data that we may already have
    [self.data setLength:0];
    
    // Make sure we get the discovery callbacks
    peripheral.delegate = self;
    
    // Search only for services that match our UUID
    [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
}


/** The Transfer Service was discovered
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    // Discover the characteristic we want...
    
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:@"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"]] forService:service];
    }
}


/** The Transfer characteristic was discovered.
 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Deal with errors (if any)
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        // And check if it's the right one
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"]]) {
            
            // If it is, subscribe to it
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
    
    // Once this is complete, we just need to wait for the data to come in.
}


/** This callback lets us know more data has arrived via notification on the characteristic
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    // Have we got everything we need?
    if ([stringFromData isEqualToString:@"EOM"]) {
        
        // We have, so show the data,
        NSLog(@"%@", self.data);
//        [self.textview setText:[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]];
        
        // Cancel our subscription to the characteristic
        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        
        // and disconnect from the peripehral
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
    
    // Otherwise, just add the data on to what we already have
    [self.data appendData:characteristic.value];
    
    // Log it
    NSLog(@"Received: %@", stringFromData);
}


/** The peripheral letting us know whether our subscribe/unsubscribe happened or not
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Exit if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
        return;
    }
    
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    }
    
    // Notification has stopped
    else {
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}


/** Once the disconnection happens, we need to clean up our local copy of the peripheral
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Peripheral Disconnected");
    self.discoveredPeripheral = nil;
    
    // We're disconnected, so start scanning again
    [self scan];
}


/** Call this when things either go wrong, or you're done with the connection.
 *  This cancels any subscriptions if there are any, or straight disconnects if not.
 *  (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
 */
- (void)cleanup
{
    // Don't do anything if we're not connected
    if (!self.discoveredPeripheral.isConnected) {
        return;
    }
    
    // See if we are subscribed to a characteristic on the peripheral
    if (self.discoveredPeripheral.services != nil) {
        for (CBService *service in self.discoveredPeripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
                        if (characteristic.isNotifying) {
                            // It is notifying, so unsubscribe
                            [self.discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                            
                            // And we're done.
                            return;
                        }
                    }
                }
            }
        }
    }
    
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
}


/** Catch when someone subscribes to our characteristic, then start sending them data
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central subscribed to characteristic");
    
    // Get the data
    self.dataToSend = @"Hey wait up!";
    
    // Reset the index
    self.sendDataIndex = 0;
    
    // Start sending
    [self sendData];
}


/** Recognise when the central unsubscribes
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central unsubscribed from characteristic");
}


/** Sends the next amount of data to the connected central
 */
- (void)sendData
{
    // First up, check if we're meant to be sending an EOM
    static BOOL sendingEOM = NO;
    
    if (sendingEOM) {
        
        // send it
        BOOL didSend = [_peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        
        // Did it send?
        if (didSend) {
            
            // It did, so mark it as sent
            sendingEOM = NO;
            
            NSLog(@"Sent: EOM");
        }
        
        // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
        return;
    }
    
    // We're not sending an EOM, so we're sending data
    
    // Is there any left to send?
    
    if (self.sendDataIndex >= self.dataToSend.length) {
        
        // No data left.  Do nothing
        return;
    }
    
    // There's data left, so send until the callback fails, or we're done.
    
    BOOL didSend = YES;
    
    while (didSend) {
        
        // Make the next chunk
        
        // Work out how big it should be
        NSInteger amountToSend = self.dataToSend.length - self.sendDataIndex;
        
        // Can't be longer than 20 bytes
        if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
        
        // Copy out the data we want
        NSData *chunk = [NSData dataWithBytes:self.dataToSend.bytes+self.sendDataIndex length:amountToSend];
        
        // Send it
        didSend = [_peripheralManager updateValue:chunk forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        
        // If it didn't work, drop out and wait for the callback
        if (!didSend) {
            return;
        }
        
        NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
        NSLog(@"Sent: %@", stringFromData);
        
        // It did send, so update our index
        self.sendDataIndex += amountToSend;
        
        // Was it the last one?
        if (self.sendDataIndex >= self.dataToSend.length) {
            
            // It was - send an EOM
            
            // Set this so if the send fails, we'll send it next time
            sendingEOM = YES;
            
            // Send it
            BOOL eomSent = [_peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
            
            if (eomSent) {
                // It sent, we're all done
                sendingEOM = NO;
                
                NSLog(@"Sent: EOM");
            }
            
            return;
        }
    }
}


@end
