//
//  PAUCounterViewController.m
//  Pauser
//
//  Created by Laurent Cerveau on 10/31/14.
//  Copyright (c) 2014 fevbri. All rights reserved.
//

#import "PAUCounterViewController.h"
#import "PAUAppDelegate.h"
#import "PAUBackend.h"

@interface PAUCounterViewController ()

@end

@implementation PAUCounterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


-(NSString *)title
{
    return @"Pauser";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    [self.navigationController setNavigationBarHidden:NO];
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.title =@"Pauser";

    PAUDataProvider *currentDataProvider = [[PAUDataProviderManager sharedProviderManager] providerForUser:[PAUDataProviderManager sharedProviderManager].currentUserUUID];
    PAUChallenge *tmpChallenge = (PAUChallenge *)[currentDataProvider.dataStore objectWithUUID:@"com.current.challenge"];

    if(NO == tmpChallenge.started) {
        tmpChallenge.started = YES;
        PAUAppDelegate *tmpDelegate = (PAUAppDelegate *)([UIApplication sharedApplication].delegate);
        tmpChallenge.remainingDuration = tmpChallenge.durationInSeconds;
        self.timerLabel.text = [NSString stringWithFormat:@"%0.f", tmpChallenge.durationInSeconds];
        tmpDelegate.gameTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_doUpdateTimer:) userInfo:nil repeats:YES];
    }
}

- (void)_doUpdateTimer:(NSTimer*)timer
{
    PAUDataProvider *currentDataProvider = [[PAUDataProviderManager sharedProviderManager] providerForUser:[PAUDataProviderManager sharedProviderManager].currentUserUUID];
    PAUChallenge *tmpChallenge = (PAUChallenge *)[currentDataProvider.dataStore objectWithUUID:@"com.current.challenge"];
    
    if(tmpChallenge.remainingDuration > 1.0) {
        tmpChallenge.remainingDuration = tmpChallenge.remainingDuration-1;
        self.timerLabel.text = [NSString stringWithFormat:@"%0.f", tmpChallenge.remainingDuration];
    } else {
        [timer invalidate];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Bravo! Défi gagné", nil) message:NSLocalizedString(@"Personne n'a touché à son téléphone!", @"Personne n'a touché à son téléphone!")
                delegate:self
                cancelButtonTitle:NSLocalizedString(@"OK", nil)                                              otherButtonTitles:nil];
        [alert show];

    }
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    PAUAppDelegate *tmpDelegate = (PAUAppDelegate *)([UIApplication sharedApplication].delegate);
    PAUDataProvider *currentDataProvider = [[PAUDataProviderManager sharedProviderManager] providerForUser:[PAUDataProviderManager sharedProviderManager].currentUserUUID];
    
    PAUChallenge *tmpChallenge = (PAUChallenge *)[currentDataProvider.dataStore objectWithUUID:@"com.current.challenge"];
//    [tmpChallenge.inviteesUUIDs removeAllObjects];
//    tmpChallenge.title = nil;
//    tmpChallenge.challengeDescription = nil;
//    tmpChallenge.durationInSeconds = 0.0;
//    tmpChallenge.remainingDuration = 0.0;
    tmpChallenge.started = NO;
    [self.navigationController popViewControllerAnimated:YES];
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
