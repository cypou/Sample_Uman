//
//  PAUChallengeSetUpDurationViewController.h
//  Pauser
//
//  Created by Laurent Cerveau on 10/30/14.
//  Copyright (c) 2014 fevbri. All rights reserved.
//

#import "PAUBaseViewController.h"

@interface PAUChallengeSetUpDurationViewController : PAUBaseViewController
{
    NSArray *_pickerData;
    CGFloat _hours;
    CGFloat _minutes;
}

@property(nonatomic,strong) IBOutlet UIPickerView *picker;
@property(nonatomic,strong) IBOutlet UITextView *textView;
@end
