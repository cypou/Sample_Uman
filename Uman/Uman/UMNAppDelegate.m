//
//  AppDelegate.m
//  Uman
//
//  Created by Cyprien HALLE on 18/02/2015.
//  Copyright (c) 2015 Cyrille Briere. All rights reserved.
//

#import "UMNAppDelegate.h"
#import "UMNStartViewController.h"
#import "UMNViewController.h"

@interface UMNAppDelegate ()

@property BOOL backgroundedToLockScreen;
@property float initialBrightness;
@property NSTimer* timer;


@end

@implementation UMNAppDelegate



//Methode pour enregistrer la notification
- (void) registerNotification {
    UIUserNotificationType types = UIUserNotificationTypeBadge |
    UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    
    UIUserNotificationSettings *mySettings =
    [UIUserNotificationSettings settingsForTypes:types categories:nil];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    
    
}

//Methode pour envoyer une notif
- (void) setupLocalNotification {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    
    UILocalNotification *localNotification= [[UILocalNotification alloc] init];
    
    NSDate *now = [[NSDate alloc]init];
    NSDate *dateToFire = [now dateByAddingTimeInterval:0];
    
    localNotification.fireDate = dateToFire;
    localNotification.alertBody = @"Vous avez perdu...";
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    
    //NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:@"Object 1", @"Key 1", @"Object 2", @"Key 2", nil];
    
    [[UIApplication sharedApplication]scheduleLocalNotification:localNotification];
    
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [self registerNotification];
    
    _partie = [[UMNGame alloc] init];

    _initialBrightness = [[UIScreen mainScreen]brightness]; //On enregistre la luminosité de base


    return YES;
}

-(void) application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
    [[UIScreen mainScreen]setBrightness:_initialBrightness];
    if (_partie.isStarted) {
        [self setupLocalNotification];

        [_startVC.timer invalidate];
        
    }
    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}



- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    
    
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"kDisplayStatusLocked"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    if (_partie.isStarted) {
        [ROOTVIEW presentViewController:UMNViewController animated:YES completion:^{}];

    }


    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
