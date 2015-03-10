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

@property float initialBrightness;



@end

@implementation UMNStartViewController


- (NSTimer*) getTimer {
    return _timer;
}
//Methode pour vérifier si la luminisoté est supérieure à 0.
- (void)turnOffScreen {
    
    float brightness =[[UIScreen mainScreen] brightness];
    if (brightness > 0){
        
        [[UIScreen mainScreen] setBrightness:0.0];
        
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.delegate = (UMNAppDelegate*)[[UIApplication sharedApplication] delegate];
    [self.delegate setIsStarted:YES];

    _initialBrightness = [[UIScreen mainScreen] brightness];
    

    [self performSelector:@selector(turnOffScreen) withObject:nil afterDelay:3.0];
    //NSTimer *timer = [[NSTimer alloc]init];
    
    //Timer recursif (toutes les secondes)
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(turnOffScreen) userInfo:nil repeats:true];
    
    [_timer fire];
    //Ces lignes permettent d'accéder au VC depuis appdelegate
    UMNAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.startVC = self;

    // Do any additional setup after loading the view.
}

- (void) viewDidDisappear:(BOOL)animated {
    [self.delegate setIsStarted:NO];
    [_timer invalidate];
    [[UIScreen mainScreen] setBrightness:_initialBrightness];
    NSLog(@"PLOP");


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
