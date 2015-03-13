//
//  UMNStartViewController.h
//  Uman
//
//  Created by Cyprien HALLE on 19/02/2015.
//  Copyright (c) 2015 Cyrille Briere. All rights reserved.
//

#import <UIKit/UIKit.h>
#define ROOTVIEW [[[UIApplication sharedApplication] keyWindow] rootViewController]


@interface UMNStartViewController : UIViewController

@property (nonatomic, assign) id delegate;
@property NSTimer *timer;
-(void)loose;


@end
