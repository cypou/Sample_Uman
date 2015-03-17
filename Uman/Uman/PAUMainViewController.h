//
//  PAUMainViewController.h
//  Pauser
//
//  Created by Laurent Cerveau on 10/16/14.
//  Copyright (c) 2014 fevbri. All rights reserved.
//

#import "PAUBaseViewController.h"

@interface PAUMainViewController : PAUBaseViewController<UIPageViewControllerDataSource, UIPageViewControllerDelegate>
{
    NSArray *_allSlides;
}

@property (nonatomic, strong) IBOutlet UIView *imageviewContainer;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *successChallengeLabel;
@property (nonatomic, strong) IBOutlet UILabel *failedChallengeLabel;
@property (nonatomic, strong) IBOutlet UICollectionView *friendsCollectionView;
@property (nonatomic, strong) NSArray *allSlides;

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;


@end
