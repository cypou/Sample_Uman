//
//  AppDelegate.m
//  Pauser
//
//  Created by Laurent Cerveau on 10/12/14.
//  Copyright (c) 2014 fevbri. All rights reserved.
//

@import Foundation;
@import UIKit;

#import <FacebookSDK/FacebookSDK.h>

#import "PAUAppDelegate.h"

#import "PAUBackend.h"

#import "PAUMainViewController.h"
#import "PAUSignInUpViewController.h"
#import "PAUWaitingViewController.h"

@interface PAUAppDelegate ()

@end



#define PAUAPPDELEGATELOG YES && PAUGLOBALLOGENABLED

#define kPAUOfflineViewTag 2727

#define kPAUApplicationDelegateRatingAlertTag 345
#define kPAUApplicationDelegateUserNonRegisteredAlertTag 346
#define kPAUApplicationDelegateRegistrationFailedAlertTag 347
#define kPAUApplicationDelegateStartupFailedAlertTag 348

@implementation PAUAppDelegate


//Cette methode lance la notification de fin de jeu
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
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
}

// cette methode permet de faire la distinction lock/home
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
    //Gather all data prelaunch
    [self _setUpGetRunTimeEnvironment];
    [self _setUpGatherLaunchEnvironment:launchOptions];
    
    //Register for all notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleNotification:) name:kPAURegistrationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleNotification:) name:kPAUSessionStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleNotification:) name:kPAUSessionStopNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleNotification:) name:kPAUNetworkStateDidEnterOnLineMode object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleNotification:) name:kPAUNetworkStateDidEnterOffLineMode object:nil];
    
    
    //we force the loading of the waiting view controller now
    [self.window makeKeyAndVisible];

    [UINavigationBar appearance].barTintColor = [UIColor colorWithRed:38.0/255.0 green:110.0/255.0 blue:150.0/255.0 alpha:1.0];
    [UINavigationBar appearance].tintColor = [UIColor colorWithRed:38.0/255.0 green:110.0/255.0 blue:150.0/255.0 alpha:1.0];
    [UINavigationBar appearance].titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};

    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    PAULog(PAUAPPDELEGATELOG, @" --> Starting session for user");
    PAUWaitingViewController *waitingViewController = self.topWaitingViewController;

    
    //Now connect for the proper user. If never used we register with anonymous
    BOOL tmpBool = [[PAUDataProviderManager sharedProviderManager] startSessionForUser:kPAULastUser];
    if(NO == tmpBool) {
        
        if( 0 /*NO == [WIDDataProviderManager sharedProviderManager].isOnLine*/) {
            PAULog(PAUAPPDELEGATELOG, @" --> Fail because offline");
            [waitingViewController activateOfflineMode];
        } else {
            [waitingViewController performSegueWithIdentifier:@"waiting_to_signinup" sender:waitingViewController];
            PAULog(PAUAPPDELEGATELOG, @" --> Fail no last user. Will register");
        }
    }
    //Ce bloc permet la differenciation lock/home
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    displayStatusChanged,
                                    CFSTR("com.apple.springboard.lockcomplete"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);

    
    return YES;


}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    //CGFloat screenBrightness = [[UIScreen mainScreen] brightness];
//    NSLog(@"Screen brightness: %f", screenBrightness);
//    self.backgroundedToLockScreen = screenBrightness <= 0.0;
    
    PAUDataProvider *currentDataProvider = [[PAUDataProviderManager sharedProviderManager] providerForUser:[PAUDataProviderManager sharedProviderManager].currentUserUUID];
    PAUChallenge *tmpChallenge = (PAUChallenge *)[currentDataProvider.dataStore objectWithUUID:@"com.current.challenge"];
    
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if (state == UIApplicationStateInactive) {
        NSLog(@"Sent to background by locking screen");
    } else if (state == UIApplicationStateBackground) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"kDisplayStatusLocked"]) {
            if (tmpChallenge.started) {
                [self setupLocalNotification];
            }
            NSLog(@"Sent to background by home button/switching to other app");
        } else {
            NSLog(@"Sent to background by locking screen");
        }
    }

//    Code de Laurent
//    if(tmpChallenge.started) {
//        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
//        localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0.1];
//        localNotification.alertBody = [NSString stringWithFormat:@"Défi perdu!"];
//        localNotification.soundName = UILocalNotificationDefaultSoundName;
//        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
//         [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
//    }
//    [((UINavigationController *)self.window.rootViewController) popViewControllerAnimated:NO];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    //This block makes difference between lock and changement of application
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"kDisplayStatusLocked"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    if(self.backgroundedToLockScreen) {
        NSLog(@"from background screen ");
    } else {

    }

}

- (void)applicationDidBecomeActive:(UIApplication *)application {
        [FBAppCall handleDidBecomeActive];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark == SET UP STEPS ==
/* Startup part 1: find out the application inherent parameters that never change between launches */
- (void)_setUpGetRunTimeEnvironment
{
    self.developmentStage = kPAUApplicationAlpha;
    self.runDevVersion = (self.developmentStage < kPAUApplicationFinal);
    _uniqueStartTime = CFAbsoluteTimeGetCurrent();
    
    
    //Usually do stuff like be more verbose or connect to a crash reporter in a dev version
    if(self.runDevVersion) {
        //        [TestFlight setDeviceIdentifier:[[[UIDevice currentDevice] identifierForVendor] UUIDString]];
        //        [TestFlight takeOff:@"d3609d19-e165-42a5-ad6a-cc40a9d142ac"];
    }
}

/* Startup part 2: find out how the app was launched */
- (void)_setUpGatherLaunchEnvironment:(NSDictionary *)launchOptions
{
    self.firstLaunch = (NO == [[NSUserDefaults standardUserDefaults] boolForKey:@"PAUFirstTimeHasPassed"]);
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"PAUlastLaunchedVersion"];
    
    // upgrade detection
    NSNumber *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
    NSString *marketingVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    
    NSNumber *previousLaunchVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"PAUlastLaunchedVersion"];
    NSString *previousMarketingLaunchedVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"WIDlastLaunchedShortVersion"];
    
    //store last marketing version
    if((nil == previousMarketingLaunchedVersion) || (NO == [marketingVersion isEqualToString:previousMarketingLaunchedVersion])) {
        self.upgradeLaunch = YES;
        [[NSUserDefaults standardUserDefaults] setObject:marketingVersion forKey:@"PAUlastLaunchedShortVersion"];
    }
    
    //store last version
    if((nil == previousLaunchVersion) || (NO == [version isEqual:previousLaunchVersion])) {
        [[NSUserDefaults standardUserDefaults] setObject:version forKey:@"PAUlastLaunchedVersion"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
}

/* Startup part 2: Present Rate app if needed */
- (void) _setUpAskForApplicationRatingIfNeeded
{
    self.hasRated = [[NSUserDefaults standardUserDefaults] boolForKey:@"PAUHasRated"];
    if (YES == self.hasRated)
        return;
    
    if (YES == self.firstLaunch) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"PAUFirstTimeHasPassed"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return;
    }
    return;
    srandom((unsigned) (time(NULL)));
    int index = (int)(random()%8);
    
    if(0 == index) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"app_delegate_rate_title", @"Rate Pauser!") message:NSLocalizedString(@"app_delegate_rate_sentence", @"Help us by rating Pauser")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"app_delegate_rate_buttonappstore", @"App Store")
                                              otherButtonTitles:NSLocalizedString(@"app_delegate_rate_buttonlater", @"Later"), NSLocalizedString(@"app_delegate_rate_buttonnever", @"Never"),nil];
        alert.tag = kPAUApplicationDelegateRatingAlertTag;
        [alert show];
    }
}


#pragma mark == NOTIFICATION/ KVO ==
/* Will handle major notifications (login/logout, network related */
- (void) _handleNotification:(NSNotification *)notification
{
    PAULog(PAUAPPDELEGATELOG, @"[PAUAPPDELEGATELOG] received notification %@", [notification name]);
    
    if([[notification name] isEqualToString:kPAUNetworkStateDidEnterOnLineMode]) {
        [self _setOnlineUIMode:YES];
        if(self.topWaitingViewController) {
            BOOL tmpBool = [[PAUDataProviderManager sharedProviderManager] startSessionForUser:kPAULastUser];
            if(NO == tmpBool){
            }
        }
    } else if([[notification name] isEqualToString:kPAUNetworkStateDidEnterOffLineMode]) {
        [self _setOnlineUIMode:NO];
    } else  if([[notification name] isEqualToString:kPAURegistrationNotification]) {
        PAUDataProvider *tmpProvider =[[PAUDataProviderManager sharedProviderManager] providerForUser:[notification userInfo][kPAURegistrationUserUUIDKey]];
        if(kPAUDataProviderStateNoSession == tmpProvider.state ) {
            [tmpProvider startSession];
        } else if(kPAUDataProviderStatePendingRegistrationApproval == tmpProvider.state ) {
            [self.topSigninupViewController.activityView stopAnimating];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Pending registration!", @"Pending registration!!") message:NSLocalizedString(@"Before using Pauser you need to approve its usage by clicking on the registration email you should have received", @"Before using PetitBambou you need to approve its usage by clicking on the registration email you should have received") delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"OK")  otherButtonTitles:nil];
            alert.tag = kPAUApplicationDelegateUserNonRegisteredAlertTag;
            [alert show];
        } else {
            [self.topSigninupViewController.activityView stopAnimating];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"app_delegate_registration_error_title", @"Title when registetration error") message:NSLocalizedString(@"app_delegate_registration_error_message", @"Message when registetration error") delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"OK")  otherButtonTitles:nil];
            alert.tag = kPAUApplicationDelegateRegistrationFailedAlertTag;
            [alert show];
        }
        
    } else if([[notification name] isEqualToString:kPAUSessionStartNotification]) {
        
        if(YES == [[notification userInfo][kPAUSessionStartStatusKey] boolValue] && (nil!= [PAUDataProviderManager sharedProviderManager].currentUserUUID)) {
            
            //            BOOL preventShow = (UIRemoteNotificationTypeNone == [UIApplication sharedApplication].enabledRemoteNotificationTypes);
            
            //            if(!preventShow) {
            [self _setUpAskForApplicationRatingIfNeeded];
            //            }
            
            PAUDataProvider *currentProvider = [[PAUDataProviderManager sharedProviderManager] providerForUser:[PAUDataProviderManager sharedProviderManager].currentUserUUID];
            PAUUser *meUser = (PAUUser *)[currentProvider.dataStore objectWithUUID:[PAUDataProviderManager sharedProviderManager].currentUserUUID];
            
            [currentProvider fetchBaseDataWithCompletionBlock:^(BOOL success) {
                if(YES == success) {
                    if(self.topSigninupViewController) {
                        [self.topSigninupViewController performSegueWithIdentifier:@"signinup_to_main" sender:self.topSigninupViewController];
                    } else if (self.topWaitingViewController) {
                        PAULog(PAUAPPDELEGATELOG, @" --> Segue waiting_to_mainsw");
                        [self.topWaitingViewController performSegueWithIdentifier:@"waiting_to_main" sender:self.topWaitingViewController];
                    }
                    NSString *tmpSystem = [UIDevice currentDevice].systemVersion;
                    
//                    if([tmpSystem hasPrefix:@"8"]) {
//                        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
//                        
//                        [[UIApplication sharedApplication] registerForRemoteNotifications];
//                    } else {
//                        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound)];
//                    }
                    
                    
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error at start!", @"Error at start!") message:@"Nous sommes désolés, nous travaillons actuellement a la remise en route du service." delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"Try Later", @"Try Later")
                                                          otherButtonTitles:nil];
                    alert.tag = kPAUApplicationDelegateStartupFailedAlertTag;
                    [alert show];
                    
                }
            }];
            
            
        } else {
            PAUDataProvider *tmpProvider =[[PAUDataProviderManager sharedProviderManager] providerForUser:[PAUDataProviderManager sharedProviderManager].currentUserUUID];
            
            PAUError *tmpError = (PAUError *)[tmpProvider.dataStore objectWithUUID:[notification userInfo][kPAUSessionErrorUUIDKey]];
            
            NSString *message = @"An error has occured";
            if(self.topSigninupViewController) {
                [self.topSigninupViewController.activityView stopAnimating];
            }
            if([tmpError isKindOfClass:[PAUError class]]) {
                message =[NSString stringWithFormat:@"%@ status (%ld)", message, (long)tmpError.code];
            }
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error at start!", @"Error at start!") message:message delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Try Later", @"Try Later")
                                                  otherButtonTitles:nil];
            alert.tag = kPAUApplicationDelegateStartupFailedAlertTag;
            [alert show];
            
        }
    } else if([[notification name] isEqualToString:kPAUSessionStopNotification]) {
        [(UINavigationController *)self.window.rootViewController popToRootViewControllerAnimated:NO];
        [self.topWaitingViewController performSegueWithIdentifier:@"waiting_to_slide" sender:self.topWaitingViewController];
    }
}

/* Handling of UIMode */
- (void) _setOnlineUIMode:(BOOL) isOnline
{
    UIView *tmpView = [self.window.rootViewController.view viewWithTag:kPAUOfflineViewTag];
    PAUWaitingViewController *waitingViewController = self.topWaitingViewController;
    
    if((NO == isOnline) && (nil == tmpView)) {
        if(waitingViewController) {
            [self.topWaitingViewController activateOfflineMode];
            //Make a label on the waiting view controller
        } else {
            //For now not more additional label
            return;
            UILabel *tmpLabel = [[UILabel alloc] initWithFrame:self.window.rootViewController.view.frame];
            tmpLabel.textAlignment = NSTextAlignmentCenter;
            tmpLabel.backgroundColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:0.7];
            tmpLabel.textColor = [UIColor whiteColor];
            tmpLabel.font = [UIFont boldSystemFontOfSize:17];
            tmpLabel.text = NSLocalizedString(@"No Network", @"No Network");
            tmpLabel.tag = kPAUOfflineViewTag;
            tmpLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
            [self.window.rootViewController.view addSubview:tmpLabel];
        }
    } else {
        return;
        [[self.window.rootViewController.view viewWithTag:kPAUOfflineViewTag] removeFromSuperview];
        //If we have the waitinv view controller
        if(waitingViewController) {
            //TODO reluanch the log
        } else {
            //if there is a hail or run we do resync
            
        }
    }
}



#pragma mark == EASY ACCESS TO CONTROLLER ==
/* Will return the waiting view controller if displayed */
-(PAUWaitingViewController *) topWaitingViewController
{
    PAUWaitingViewController *result = nil;
    if(NO == [self.window.rootViewController isKindOfClass:[UINavigationController class]]) return  result;
    UIViewController *tmpController =[((UINavigationController *)self.window.rootViewController) topViewController];
    if([tmpController isKindOfClass:[PAUWaitingViewController class]]) {
        result = (PAUWaitingViewController *)tmpController;
    }
    return result;
}

/* Will return the waiting view controller if displayed */
-(PAUSigninUpViewController *) topSigninupViewController
{
    PAUSigninUpViewController *result = nil;
    if(NO == [self.window.rootViewController isKindOfClass:[UINavigationController class]]) return  result;
    
    UIViewController *tmpController =[((UINavigationController *)self.window.rootViewController) topViewController];
    if([tmpController isKindOfClass:[PAUSigninUpViewController class]]) {
        result = (PAUSigninUpViewController *)tmpController;
    }
    return result;
}

/* Will return the home view controller if displayed */
-(PAUMainViewController *) topMainViewController
{
    PAUMainViewController *result = nil;
    if(NO == [self.window.rootViewController isKindOfClass:[UINavigationController class]]) return  result;
    
    UIViewController *tmpController =[((UINavigationController *)self.window.rootViewController) topViewController];
    if([tmpController isKindOfClass:[PAUMainViewController class]]) {
        result = (PAUMainViewController *)tmpController;
    }
    return result;
}

#pragma mark == OPEN URL FOR FACEBOOK HANDLING ==
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    // attempt to extract a token from the url
    BOOL wasHandled =  [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    return wasHandled;
}



@end
