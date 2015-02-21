//
//  UMNStartViewController.m
//  Uman
//
//  Created by Cyprien HALLE on 19/02/2015.
//  Copyright (c) 2015 Cyrille Briere. All rights reserved.
//

#import "UMNStartViewController.h"

@interface UMNStartViewController ()

@end

@implementation UMNStartViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupLocalNotification];
    
    // Do any additional setup after loading the view.
}

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
