//
//  AppDelegate.m
//  Uman
//
//  Created by Cyprien HALLE on 18/02/2015.
//  Copyright (c) 2015 Cyrille Briere. All rights reserved.
//

#import "UMNAppDelegate.h"
#import "UMNStartViewController.h"

@interface UMNAppDelegate ()

@property BOOL backgroundedToLockScreen;
@property UMNStartViewController *startViewController;
@property float initialBrightness;
@property NSTimer* timer;


@end

@implementation UMNAppDelegate

//Sample from AgileWarrior.com

//- (void) showAlarm:(NSString *)text {
//    
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alarm" message:text delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//    
//}

+ (void) setIsStarted:(BOOL) isStarted{
    
    self.isStarted = isStarted;
    
}

-(void)loose{
    
    NSLog(@"PERDU!!");
    
}

- (void) setupLocalNotification {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    
    UILocalNotification *localNotification= [[UILocalNotification alloc] init];
    
    NSDate *now = [[NSDate alloc]init];
    NSDate *dateToFire = [now dateByAddingTimeInterval:1];
    NSLog(@"now time: %@",now);
    NSLog(@"fire time: %@", now);
    
    localNotification.fireDate = dateToFire;
    localNotification.alertBody = @"Revenez à l'application!!";
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    
    NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:@"Object 1", @"Key 1", @"Object 2", @"Key 2", nil];
    
    [[UIApplication sharedApplication]scheduleLocalNotification:localNotification];
    
}

static void displayStatusChanged(CFNotificationCenterRef center,
                                 void *observer,
                                 CFStringRef name,
                                 const void *object,
                                 CFDictionaryRef userInfo) {
    if (name == CFSTR("com.apple.springboard.lockcomplete")) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kDisplayStatusLocked"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}






- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(loose) userInfo:nil repeats:false];

    _initialBrightness = [[UIScreen mainScreen]brightness];
    NSLog(@"Brightness is at %f", _initialBrightness);
    [[_startVC timer] fire];

    
    UIUserNotificationType types = UIUserNotificationTypeBadge |
    UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    
    UIUserNotificationSettings *mySettings =
    [UIUserNotificationSettings settingsForTypes:types categories:nil];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    displayStatusChanged,
                                    CFSTR("com.apple.springboard.lockcomplete"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);

    
    //Sample from AgileWarrior
//    UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
//    
//    if (notification) {
//        [self showAlarm:notification.alertBody];
//        NSLog(@"AppDelegate didFinishLaunchingWithOptions");
//        application.applicationIconBadgeNumber=0;
//        
//    }
//    
//    [self.window makeKeyAndVisible];
    return YES;
}

-(void) application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    
    //Sample from AgileWarrior
//    
//    [self showAlarm:notification.alertBody];
//    application.applicationIconBadgeNumber = 0;
//    NSLog(@"AppDelegate didReceiveLocalNotification @%", notification.userInfo);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
    [[_startVC timer] invalidate];
    [[UIScreen mainScreen]setBrightness:_initialBrightness];

    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}



- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    
    
//    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
//    if (state == UIApplicationStateInactive) {
//        NSLog(@"Sent to background by locking screen");
//    } else if (state == UIApplicationStateBackground) {
//        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"kDisplayStatusLocked"]) {
//            if (self.isStarted) {
//                [self setupLocalNotification];
//            }
//            NSLog(@"Sent to background by home button/switching to other app");
//        } else {
//            NSLog(@"Sent to background by locking screen");
//        }
//    }
    if (self.isStarted) {
        [self setupLocalNotification];
        [_timer fire];

    }

    
    
    // Ne Fonctionne plus depuis iOS 8
    //CGFloat screenBrightness = [[UIScreen mainScreen] brightness];
    //NSLog(@"Screen brightness: %f", screenBrightness);
    //self.backgroundedToLockScreen = screenBrightness <= 0.0;
    
    

    // Le code suivant ne fonctionne plus depuis iOS 7
//    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
//    if (state == UIApplicationStateInactive) {
//        NSLog(@"Sent to background by locking screen");
//    } else if (state == UIApplicationStateBackground) {
//        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"kDisplayStatusLocked"]) {
//            NSLog(@"Sent to background by home button/switching to other app");
//        } else {
//            NSLog(@"Sent to background by locking screen");
//        }
//    }
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"kDisplayStatusLocked"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [_timer invalidate];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
