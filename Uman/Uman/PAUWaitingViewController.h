//
//  ViewController.h
//  Pauser
//
//  Created by Laurent Cerveau on 10/12/14.
//  Copyright (c) 2014 fevbri. All rights reserved.
//

@import Foundation;
@import UIKit;

#import "PAUBaseViewController.h"



@interface PAUWaitingViewController : PAUBaseViewController

@property (nonatomic,strong) UIActivityIndicatorView *activityView;

-(void) activateOfflineMode;
@end

