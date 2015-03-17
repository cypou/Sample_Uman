//
//  AppDelegate.h
//  Pauser
//
//  Created by Laurent Cerveau on 10/12/14.
//  Copyright (c) 2014 fevbri. All rights reserved.
//

@import Foundation;
@import UIKit;


@class PAUMainViewController;
@class PAUWaitingViewController;
@class PAUSigninUpViewController;

/* Indicates where we are in development */
enum {
    kPAUApplicationAlpha = 100,
    kPAUApplicationBeta = 150,
    kPAUApplicationFinal = 200
};

@interface PAUAppDelegate : UIResponder <UIApplicationDelegate>
{
    CFAbsoluteTime                  _uniqueStartTime;
    BOOL                            _wasOffLine;
}

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic,assign)  BOOL  hasRated;        //the user has rated the app in the store
@property (nonatomic, assign) BOOL  firstLaunch;     //this is the first time we launched the app
@property (nonatomic, assign) BOOL  upgradeLaunch;   //we launch a version that was not the last one launched
@property (nonatomic, assign) short developmentStage;//Alpha , beta or other
@property (nonatomic, assign) BOOL  runDevVersion;   //It may be that a dev app has more debug features. Can be
@property (nonatomic, strong) NSTimer *gameTimer;   //It may be that a dev app has more debug features. Can be
@property (nonatomic, assign) BOOL backgroundedToLockScreen;

/* Will return the waiting view controller if displayed */
-(PAUWaitingViewController *) topWaitingViewController;

/* Will return the waiting view controller if displayed */
-(PAUSigninUpViewController *) topSigninupViewController;

/* Will return the main view controller if displayed */
-(PAUMainViewController *) topMainViewController;
@end

