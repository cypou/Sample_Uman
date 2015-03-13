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
@property UMNAppDelegate* appDelegate;



@end

@implementation UMNStartViewController



-(void)loose {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"UMNViewController"];
    [self presentViewController:vc animated:YES completion:nil];
    NSLog(@"Perdu");
}



//Methode pour maintenir la luminosité à 0
- (void)turnOffScreen {
    
    float brightness =[[UIScreen mainScreen] brightness];
    if (brightness > 0){
        
        [[UIScreen mainScreen] setBrightness:0.0];
        
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Affectation d'AppDelegate
    //self.delegate = (UMNAppDelegate*)[[UIApplication sharedApplication] delegate];
    _appDelegate = (UMNAppDelegate*)[[UIApplication sharedApplication] delegate];
    _appDelegate.startVC = self; //Permet de faire le lien entre VC et appdelgate
    
    _appDelegate.partie.isStarted = true; //la partie commence

    _initialBrightness = [[UIScreen mainScreen] brightness];
    
    [self performSelector:@selector(turnOffScreen) withObject:nil afterDelay:3.0];
    
    //Timer recursif (toutes les secondes)
    _timer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(turnOffScreen) userInfo:nil repeats:true];
    
    [_timer fire];

    // Do any additional setup after loading the view.
}

- (void) viewDidDisappear:(BOOL)animated {


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
