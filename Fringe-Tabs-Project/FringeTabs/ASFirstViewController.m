//
//  ASFirstViewController.m
//  FringeTabs
//
//  Created by Amundeep Singh on 7/28/14.
//  Copyright (c) 2014 Amundeep Singh. All rights reserved.
//

#import "ASFirstViewController.h"
#import "MapKit/MKMapView.h"
#import "MapKit/MKUserLocation.h"

@interface ASFirstViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property NSInteger *count;
@property BOOL first_time;

@end

@implementation ASFirstViewController




- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.first_time=true;
    
	// Do any additional setup after loading the view, typically from a nib.
    
    [self.tabBarController.tabBar setTintColor:[UIColor greenColor]];
    
    [self.tabBarItem setTitle:@"Map"];

    _mapView.showsUserLocation = true;
    _mapView.delegate = self;
    
    self.count = 0;
    
    [self currentLocationIdentifier];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{

    
    /*
     * Every time the location updates (which is often) after I zoom in further, it goes back to the below delta values (zooming so it "fits")  just try it out and see what happens, try to zoom into our current location and then it zooms back out automatically.  Removing the "first_time" comments make it work but only after it gets our location for the first time..
     */
    
    //    if (self.first_time) {
    
        MKCoordinateRegion mapRegion;
        mapRegion.center = mapView.userLocation.coordinate;
        mapRegion.span.latitudeDelta = 0.05;
        mapRegion.span.longitudeDelta = 0.05;
        
        [mapView setRegion:mapRegion animated: YES];
//        self.first_time = false;
//    }
}

- (void)currentLocationIdentifier {
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [_locationManager startUpdatingLocation];
    
    NSLog(@"%f", _locationManager.location.coordinate.latitude);
    NSLog(@"%f", _locationManager.location.coordinate.longitude);
    
}

@end
