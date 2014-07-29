//
//  ASFirstViewController.h
//  FringeTabs
//
//  Created by Amundeep Singh on 7/28/14.
//  Copyright (c) 2014 Amundeep Singh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ASFirstViewController : UIViewController {
    IBOutlet MKMapView *mapView;
    
    CLLocationManager *_locationManager;
    NSUUID *_uuid;
    NSNumber *_power;
    
    
}



@end
