//
//  PAUChallengeSetUpDurationViewController.m
//  Pauser
//
//  Created by Laurent Cerveau on 10/30/14.
//  Copyright (c) 2014 fevbri. All rights reserved.
//

#import "PAUChallengeSetUpDurationViewController.h"
#import "PAUBackend.h"

@interface PAUChallengeSetUpDurationViewController ()

@end

@implementation PAUChallengeSetUpDurationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.textView.text = @"";
    self.textView.layer.borderWidth = 1.0;
    self.textView.layer.borderColor = [UIColor blackColor].CGColor;
    
    _pickerData = @[ @[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", @"12"],
                     @[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", @"12", @"13", @"14", @"15", @"16", @"17", @"18", @"19", @"20", @"21", @"22", @"23", @"24", @"25",@"26", @"27", @"28", @"29", @"30", @"31", @"32", @"33", @"34", @"35", @"36", @"37", @"38",@"39", @"40", @"41", @"42", @"43", @"44", @"45", @"46", @"47", @"48", @"49", @"50", @"51",@"52", @"53", @"54", @"55", @"56", @"57", @"58", @"59", @"60"]];
    
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (int)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [_pickerData[component] count];
}


- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return _pickerData[component][row];
}


- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if(component == 0) {
        _hours = [_pickerData[0][row] floatValue];
    } else  if(component == 1) {
        _minutes = [_pickerData[1][row] floatValue];
    }

    PAUDataProvider *currentDataProvider = [[PAUDataProviderManager sharedProviderManager] providerForUser:[PAUDataProviderManager sharedProviderManager].currentUserUUID];
    
    PAUChallenge *tmpChallenge = (PAUChallenge *)[currentDataProvider.dataStore objectWithUUID:@"com.current.challenge"];
    
    tmpChallenge.durationInSeconds = _hours*3600+_minutes*60;
        
}

- (BOOL) textView: (UITextView*) textView shouldChangeTextInRange: (NSRange) range replacementText: (NSString*) text
{
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

-(void) _keyboardWillShow:(NSNotification *)notification
{
    NSNumber *tmpDuration =[notification userInfo][UIKeyboardAnimationDurationUserInfoKey];
    CGRect tmpRect = self.parentViewController.parentViewController.view.frame;
    tmpRect.origin.y =  -240;
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

- (void)textViewDidChange:(UITextView *)textView
{
    PAUDataProvider *currentDataProvider = [[PAUDataProviderManager sharedProviderManager] providerForUser:[PAUDataProviderManager sharedProviderManager].currentUserUUID];
    
    PAUChallenge *tmpChallenge = (PAUChallenge *)[currentDataProvider.dataStore objectWithUUID:@"com.current.challenge"];

    tmpChallenge.challengeDescription =textView.text;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{

    return YES;
}

- (void)_doTapBehindKeyboard:(id)sender
{
    if([self.textView isFirstResponder]) [self.textView resignFirstResponder];
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
