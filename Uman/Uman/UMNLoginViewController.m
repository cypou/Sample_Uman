//
//  UMNLoginViewController.m
//  Uman
//
//  Created by Cyprien HALLE on 17/03/2015.
//  Copyright (c) 2015 Cyrille Briere. All rights reserved.
//

#import "UMNLoginViewController.h"

@implementation UMNLoginViewController

-(void)viewDidLoad {
    
    FBLoginView* loginView = [[FBLoginView alloc] init];
    CGPoint tmpCenter = self.view.center;
    loginView.center = tmpCenter;
    [self.view addSubview:loginView];

    
    
}


@end
