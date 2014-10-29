//
//  AppDelegate.m
//  iBeaconCenter
//
//  Created by Manish on 11/10/13.
//  Copyright (c) 2013 Self. All rights reserved.
//

#import "AppDelegate.h"
//#import <Parse/Parse.h>
#import <CoreLocation/CoreLocation.h>
@import CoreLocation;

@interface AppDelegate () <UIApplicationDelegate, CLLocationManagerDelegate>

@property CLLocationManager *locationManager;
@property BOOL isInside;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;

    // Override point for customization after application launch.
    
//    // ****************************************************************************
//    // Fill in with your Parse credentials:
//    // ****************************************************************************
//    [Parse setApplicationId:@"pZBRE8peNS0Xq3bynBrEsU7VQYUilPSEFkgs273V" clientKey:@"KEIJ06FKIsa6yKFVXnBACcWnbdWwA8GXHnxBEMNi"];
//    
//    // ****************************************************************************
//    // Your Facebook application id is configured in Info.plist.
//    // ****************************************************************************
//    
//    // Register for push notifications
//    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
//     UIRemoteNotificationTypeAlert|
//     UIRemoteNotificationTypeSound];
    
//    self.locationManager = [[CLLocationManager alloc] init];
//    self.locationManager.delegate = self;

    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self sendLocalNotificationForReqgionConfirmationWithText:@"Friends within range!"];
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        //code to be executed on the main queue after delay
        [self sendLocalNotificationForReqgionConfirmationWithText:@"Away from friends range!"];
    });
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    /*
     A user can transition in or out of a region while the application is not running. When this happens CoreLocation will launch the application momentarily, call this delegate method and we will let the user know via a local notification.
     */
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    
    if(state == CLRegionStateInside && !self.isInside)
    {
        self.isInside = true;
        notification.alertBody = NSLocalizedString(@"You are now near your friends!", @"");
    }
    else if(state == CLRegionStateOutside && self.isInside)
    {
        self.isInside = false;
        notification.alertBody = NSLocalizedString(@"Away from friends!", @"");
    }
    else
    {
        return;
    }
    
    /*
     If the application is in the foreground, it will get a callback to application:didReceiveLocalNotification:.
     If it's not, iOS will display the notification to the user.
     */
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}


- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    // If the application is in the foreground, we will notify the user of the region's state via an alert.
    NSString *cancelButtonTitle = NSLocalizedString(@"OK", @"Title for cancel button in local notification");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:notification.alertBody message:nil delegate:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
    [alert show];
}


//- (void)application:(UIApplication *)application
//didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
//    // Store the deviceToken in the current installation and save it to Parse.
//    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
//    [currentInstallation setDeviceTokenFromData:newDeviceToken];
//    [currentInstallation saveInBackground];
//}
//
//- (void)application:(UIApplication *)application
//didReceiveRemoteNotification:(NSDictionary *)userInfo {
//    [PFPush handlePush:userInfo];
//}

@end
