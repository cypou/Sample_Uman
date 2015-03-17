//
//  PAUSigninUpViewController.m
//  Pauser
//
//  Created by Laurent Cerveau on 10/16/14.
//  Copyright (c) 2014 fevbri. All rights reserved.
//

@import Foundation;
@import UIKit;

#import <FacebookSDK/FacebookSDK.h>
#import "PAUBackend.h"
#import "PAUSigninUpViewController.h"

@interface PAUSigninUpViewController ()

@end

@implementation PAUSigninUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //Création de la login view
    FBLoginView *loginView = [[FBLoginView alloc] init];
    loginView.readPermissions = @[@"public_profile", @"email", @"user_friends", @"read_friendlists"];
    loginView.delegate = self;
    //Placement du login au centre de la vue
    CGPoint tmpCenter = self.view.center;
    tmpCenter.y += 180;
    loginView.center = tmpCenter;
    [self.view addSubview:loginView];
//    NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:loginView
//                            attribute:NSLayoutAttributeBottom
//                            relatedBy:NSLayoutRelationEqual
//                            toItem:self.view
//                            attribute:NSLayoutAttributeBottom
//                            multiplier:0
//                            constant:100];
//    c.identifier = @"fbloginpos";
//    [self.view addConstraint:c];
    

    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation


*/

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView
{
    
}

/*!
 @abstract
 Tells the delegate that the view is has now fetched user info
 
 @param loginView   The login view that transitioned its view mode
 
 @param user        The user info object describing the logged in user
 */
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user
{
    [PAUDataProviderManager sharedProviderManager].currentUserUUID = user.objectID;
    PAUDataProvider *tmpProvider = [[PAUDataProviderManager sharedProviderManager] providerForUser:[PAUDataProviderManager sharedProviderManager].currentUserUUID];
    PAUUser *tmpUser = [[PAUUser alloc] initWithUUID:user.objectID];
    tmpUser.email = [user performSelector:@selector(email)];
    tmpUser.facebookID = [user objectID];
    tmpUser.firstName = [user first_name];
    tmpUser.lastName = [user last_name];
    tmpUser.failedChallenges = 4+ (rand() % 5);
    tmpUser.successChallenges = 6 + (rand() % 3);
    [tmpProvider.dataStore addObject:tmpUser withLoadBehavior:kPAUStoreAdditionBehaviorDefault];
    [[PAUDataProviderManager sharedProviderManager] saveLastUserInformationAsPersistent:tmpUser];
    [[NSNotificationCenter defaultCenter] postNotificationName:kPAUSessionStartNotification object:nil userInfo:@{kPAUSessionStartStatusKey:@(YES)}];
}

/*!
 @abstract
 Tells the delegate that the view is now in logged out mode
 
 @param loginView   The login view that transitioned its view mode
 */
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView
{
    
}

/*!
 @abstract
 Tells the delegate that there is a communication or authorization error.
 
 @param loginView           The login view that transitioned its view mode
 @param error               An error object containing details of the error.
 @discussion See https://developers.facebook.com/docs/technical-guides/iossdk/errors/
 for error handling best practices.
 */
- (void)loginView:(FBLoginView *)loginView
      handleError:(NSError *)error
{
    
}



@end
