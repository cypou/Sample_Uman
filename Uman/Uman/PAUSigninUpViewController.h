//
//  PAUSigninUpViewController.h
//  Pauser
//
//  Created by Laurent Cerveau on 10/16/14.
//  Copyright (c) 2014 fevbri. All rights reserved.
//

#import "PAUBaseViewController.h"

#import <FacebookSDK/FacebookSDK.h>

@interface PAUSigninUpViewController : PAUBaseViewController<FBLoginViewDelegate>

@property (nonatomic,strong) UIActivityIndicatorView *activityView;

@end
