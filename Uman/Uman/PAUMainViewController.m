//
//  PAUMainViewController.m
//  Pauser
//
//  Created by Laurent Cerveau on 10/16/14.
//  Copyright (c) 2014 fevbri. All rights reserved.
//

#import "PAUBackend.h"
#import "PAUMainViewController.h"

#import <FacebookSDK/FacebookSDK.h>

@interface PAUMainViewController ()

@end

@implementation PAUMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    PAUDataProvider *currentDataProvider = [[PAUDataProviderManager sharedProviderManager] providerForUser:[PAUDataProviderManager sharedProviderManager].currentUserUUID];
    PAUUser *meUser = (PAUUser *)[currentDataProvider.dataStore objectWithUUID:[PAUDataProviderManager sharedProviderManager].currentUserUUID];

    self.nameLabel.text = [NSString stringWithFormat:@"%@ %@", meUser.firstName,meUser.lastName];
    FBProfilePictureView *profilePictureView = [[FBProfilePictureView alloc] initWithProfileID:meUser.facebookID pictureCropping:FBProfilePictureCroppingSquare];
    profilePictureView.frame = CGRectMake(0,0, self.imageviewContainer.bounds.size.width, self.imageviewContainer.bounds.size.height);
    [self.imageviewContainer addSubview:profilePictureView];
    
    self.failedChallengeLabel.text = [NSString stringWithFormat:@"%d", meUser.failedChallenges];
    self.successChallengeLabel.text = [NSString stringWithFormat:@"%d", meUser.successChallenges];
    

    self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"slide_page_viewcontroller"];
    self.pageViewController.automaticallyAdjustsScrollViewInsets = NO;
    self.pageViewController.extendedLayoutIncludesOpaqueBars = YES;
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    [self.view bringSubviewToFront:self.pageControl];
    
    _allSlides = @[[self.storyboard instantiateViewControllerWithIdentifier:@"challenge_page0"],
                   [self.storyboard instantiateViewControllerWithIdentifier:@"challenge_page1"],
                   [self.storyboard instantiateViewControllerWithIdentifier:@"challenge_page2"]
                   ];
    [self.pageViewController setViewControllers:@[_allSlides[0]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    self.pageControl.currentPage = 0;
    self.pageControl.numberOfPages = 3;
    self.pageControl.pageIndicatorTintColor = [UIColor grayColor];
    self.pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
    
    PAUChallenge *tmpChallenge = [[PAUChallenge alloc] initWithUUID:@"com.current.challenge"];
    [currentDataProvider.dataStore addObject:tmpChallenge withLoadBehavior:kPAUStoreAdditionBehaviorDefault];

    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

//    self.friendsCollectionView.backgroundColor = [UIColor redColor];

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark == PAGE VIEW CONTROLLER DELEGATE ==
/* Going backward */
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger tmpIndex = [_allSlides indexOfObject:viewController];
    
    if( tmpIndex < 3 && tmpIndex > 0) {
        [((UIViewController *)(_allSlides[tmpIndex-1])).view setNeedsUpdateConstraints];
        return _allSlides[tmpIndex-1];
    } else {
        return nil;
    }
}

/* Going forward */
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger tmpIndex = [_allSlides indexOfObject:viewController];
    if( tmpIndex < 2 || tmpIndex == 0 ) {
        [((UIViewController *)(_allSlides[tmpIndex+1])).view setNeedsUpdateConstraints];
        //        [((UIViewController *)(_allSlides[tmpIndex+1])).view setNeedsLayout];
        return _allSlides[tmpIndex+1];
    } else {
        return nil;
    }
    
}

/* Set up the page control */
- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    self.pageControl.currentPage = [_allSlides indexOfObject:pendingViewControllers[0]];
}



@end
