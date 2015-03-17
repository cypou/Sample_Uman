//
//  PAUChallengeGoViewController.h
//  Pauser
//
//  Created by Laurent Cerveau on 10/30/14.
//  Copyright (c) 2014 fevbri. All rights reserved.
//

#import "PAUBaseViewController.h"

@interface PAUChallengeGoViewController : PAUBaseViewController

@property (nonatomic, strong) IBOutlet UICollectionView *friendsList;
@property (nonatomic, strong) IBOutlet UITextField *shareText;
@property (nonatomic, strong) IBOutlet UIButton *fbButton;
@property (nonatomic, strong) IBOutlet UIButton *liButton;
@property (nonatomic, strong) IBOutlet UIButton *twButton;
@property (nonatomic, strong) IBOutlet UIButton *viadButton;

- (IBAction)doActivateShareText:(id)sender;

@end
