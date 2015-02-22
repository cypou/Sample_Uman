//
//  AppDelegate.h
//  Uman
//
//  Created by Cyprien HALLE on 18/02/2015.
//  Copyright (c) 2015 Cyrille Briere. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UMNStartViewController.h"

@interface UMNAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) IBOutlet UMNStartViewController *startVC;
@property BOOL isStarted;

+ (void) setIsStarted : (BOOL) isStarted;



@end

