//
//  PAUChallengeGoViewController.m
//  Pauser
//
//  Created by Laurent Cerveau on 10/30/14.
//  Copyright (c) 2014 fevbri. All rights reserved.
//

@import QuartzCore;

#import "PAUChallengeGoViewController.h"
#import "PAUCounterViewController.h"
#import "PAUMainViewController.h"
#import "PAUBackend.h"

@interface PAUChallengeGoViewController ()

@end

@implementation PAUChallengeGoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.fbButton.layer.borderColor = [UIColor blackColor].CGColor;
    self.fbButton.layer.borderWidth = 1.0;
    self.fbButton.layer.cornerRadius = 2.0;
    self.liButton.layer.borderColor = [UIColor blackColor].CGColor;
    self.liButton.layer.borderWidth = 1.0;
    self.liButton.layer.cornerRadius = 2.0;
    self.twButton.layer.borderColor = [UIColor blackColor].CGColor;
    self.twButton.layer.borderWidth = 1.0;
    self.twButton.layer.cornerRadius= 1.0;
    self.viadButton.layer.borderColor = [UIColor blackColor].CGColor;
    self.viadButton.layer.borderWidth = 1.0;
    self.viadButton.layer.cornerRadius = 1.0;
    
    self.friendsList.backgroundColor = [UIColor clearColor];
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewWillAppear:(BOOL)animated
{
    PAUDataProvider *currentDataProvider = [[PAUDataProviderManager sharedProviderManager] providerForUser:[PAUDataProviderManager sharedProviderManager].currentUserUUID];
    PAUChallenge *tmpChallenge = (PAUChallenge *)[currentDataProvider.dataStore objectWithUUID:@"com.current.challenge"];

    if(tmpChallenge.inviteesUUIDs.count ) {
        [super viewWillAppear:animated];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        [self.friendsList reloadData];
    } else {
        UIPageViewController *tmpPageController = ((UIPageViewController *) self.parentViewController);
        PAUMainViewController *tmpController = (PAUMainViewController *) (tmpPageController.parentViewController);
        [tmpPageController setViewControllers: @[tmpController.allSlides[0]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
        tmpController.pageControl.currentPage = 0;
    }
    
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(void) _keyboardWillShow:(NSNotification *)notification
{
    NSNumber *tmpDuration =[notification userInfo][UIKeyboardAnimationDurationUserInfoKey];
    CGRect tmpRect = self.parentViewController.parentViewController.view.frame;
    tmpRect.origin.y =  -200;
    [UIView animateWithDuration:[tmpDuration floatValue] animations:^{
        self.parentViewController.parentViewController.view.frame = tmpRect;
    }];
    
    UIGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_doTapBehindKeyboard:)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

/* Keyboard will hide : move the part down */
-(void) _keyboardWillHide:(NSNotification *)notification
{
    NSNumber *tmpDuration =[notification userInfo][UIKeyboardAnimationDurationUserInfoKey];
    CGRect tmpRect = self.parentViewController.parentViewController.view.frame;
    tmpRect.origin.y =  0;
    
    [UIView animateWithDuration:[tmpDuration floatValue] animations:^{
        self.parentViewController.parentViewController.view.frame = tmpRect;
    }];
    
    [[[self.view gestureRecognizers] copy] enumerateObjectsUsingBlock:^(UIGestureRecognizer * obj, NSUInteger idx, BOOL *stop) {
        [self.view removeGestureRecognizer:obj];
    }];
    
}


-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    PAUDataProvider *currentDataProvider = [[PAUDataProviderManager sharedProviderManager] providerForUser:[PAUDataProviderManager sharedProviderManager].currentUserUUID];
    PAUChallenge *tmpChallenge = (PAUChallenge *)[currentDataProvider.dataStore objectWithUUID:@"com.current.challenge"];
    return [tmpChallenge.inviteesUUIDs count];
    
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cvCell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    PAUDataProvider *currentDataProvider = [[PAUDataProviderManager sharedProviderManager] providerForUser:[PAUDataProviderManager sharedProviderManager].currentUserUUID];
    PAUChallenge *tmpChallenge = (PAUChallenge *)[currentDataProvider.dataStore objectWithUUID:@"com.current.challenge"];

    
    PAUUser *tmpUser = (PAUUser *)[currentDataProvider.dataStore objectWithUUID:tmpChallenge.inviteesUUIDs[indexPath.row]];
    [(UIImageView *)[cell viewWithTag:100] removeFromSuperview];
    [[PAUImageCache defaultCache] imageForURL:[NSURL URLWithString:tmpUser.avatarURLString] size:CGSizeMake(50, 50) mode:UIViewContentModeCenter availableBlock:^(UIImage *image) {
        UIImageView *tmpImageView = [[UIImageView alloc] initWithImage:image];
        tmpImageView.frame = CGRectMake(0, 0, 50, 50);
        tmpImageView.contentMode = UIViewContentModeScaleToFill;
        tmpImageView.tag = 100;
        [cell.contentView addSubview:tmpImageView];
    }];
        
    
    //    cell.backgroundColor = (indexPath.row %2 )? [UIColor blueColor]: [UIColor greenColor];
    return cell;
    
}

- (IBAction)doActivateShareText:(id)sender
{
    self.shareText.enabled = ((UISwitch *)sender).isOn;
}

- (void)_doTapBehindKeyboard:(id)sender
{
    if([self.shareText isFirstResponder]) [self.shareText resignFirstResponder];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}



@end
