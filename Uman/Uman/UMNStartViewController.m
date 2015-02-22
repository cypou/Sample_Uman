//
//  UMNStartViewController.m
//  Uman
//
//  Created by Cyprien HALLE on 19/02/2015.
//  Copyright (c) 2015 Cyrille Briere. All rights reserved.
//

#import "UMNStartViewController.h"
#import "UMNAppDelegate.h"

@interface UMNStartViewController ()

@end

@implementation UMNStartViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.delegate = (UMNAppDelegate*)[[UIApplication sharedApplication] delegate];
    [self.delegate setIsStarted:YES];
    NSLog(@"PLOP");

    
    
    //Ces lignes permettent d'accéder au VC depuis appdelegate
    //UMNAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    //appDelegate.startVC = self;

    // Do any additional setup after loading the view.
}

- (void) viewWillDisappear:(BOOL)animated {
    
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
