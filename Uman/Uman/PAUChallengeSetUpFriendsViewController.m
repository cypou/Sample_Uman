//
//  PAUChallengeSetUpFriendsViewController.m
//  Pauser
//
//  Created by Laurent Cerveau on 10/30/14.
//  Copyright (c) 2014 fevbri. All rights reserved.
//

@import QuartzCore;

#import "PAUChallengeSetUpFriendsViewController.h"

#import "PAUBackend.h"

@interface PAUChallengeSetUpFriendsViewController ()

@end

@implementation PAUChallengeSetUpFriendsViewController

- (void)viewDidLoad
{
    PAUDataProvider *currentDataProvider = [[PAUDataProviderManager sharedProviderManager] providerForUser:[PAUDataProviderManager sharedProviderManager].currentUserUUID];
    PAUUser *meUser = (PAUUser *)[currentDataProvider.dataStore objectWithUUID:[PAUDataProviderManager sharedProviderManager].currentUserUUID];
    self.friendsCollectionView.allowsMultipleSelection = YES;

    if([FBSession activeSession].state == FBSessionStateOpen) {
        FBRequest* friendsRequest = [FBRequest requestForGraphPath:@"/me/taggable_friends"];
        [friendsRequest startWithCompletionHandler: ^(FBRequestConnection *connection,
                                                      NSDictionary* result,
                                                      NSError *error) {
            PAUCollection *tmpCollection = [[PAUCollection alloc] initWithDisplayIdentifier:@"me.friends"];
            [currentDataProvider.dataStore addObject:tmpCollection withLoadBehavior:kPAUStoreAdditionBehaviorDefault];
            NSMutableArray *allFriends = [NSMutableArray array];
            
            [result[@"data"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                PAUUser *tmpUser = [[PAUUser alloc] initWithUUID:obj[@"id"]];
                NSArray *components = [obj[@"name"] componentsSeparatedByString:@" "];
                if([components count] > 1) {
                    tmpUser.firstName = [[components subarrayWithRange:NSMakeRange(0, [components count]-1)] componentsJoinedByString:@" "];
                    tmpUser.lastName = [components lastObject];
                } else {
                    tmpUser.firstName = obj[@"name"];
                    tmpUser.lastName = @"";
                }
                tmpUser.avatarURLString = obj[@"picture"][@"data"][@"url"];
                [allFriends addObject:tmpUser.uuid];
                [currentDataProvider.dataStore addObject:tmpUser withLoadBehavior:kPAUStoreAdditionBehaviorDefault];
                
            }];
            [tmpCollection addItems:allFriends forRange:NSMakeRange(0, [allFriends count]) inOrder:nil withReplaceAll:NO];
            [self.friendsCollectionView reloadData];
            
        }];
        
    } else {
        [[FBSession activeSession] openWithCompletionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            FBRequest* friendsRequest = [FBRequest requestForGraphPath:@"/me/taggable_friends"];
            [friendsRequest startWithCompletionHandler: ^(FBRequestConnection *connection,
                                                          NSDictionary* result,
                                                          NSError *error) {
                PAUCollection *tmpCollection = [[PAUCollection alloc] initWithDisplayIdentifier:@"me.friends"];
                [currentDataProvider.dataStore addObject:tmpCollection withLoadBehavior:kPAUStoreAdditionBehaviorDefault];
                NSMutableArray *allFriends = [NSMutableArray array];
                
                [result[@"data"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    PAUUser *tmpUser = [[PAUUser alloc] initWithUUID:obj[@"id"]];
                    NSArray *components = [obj[@"name"] componentsSeparatedByString:@" "];
                    if([components count] > 1) {
                        tmpUser.firstName = [[components subarrayWithRange:NSMakeRange(0, [components count]-1)] componentsJoinedByString:@" "];
                        tmpUser.lastName = [components lastObject];
                    } else {
                        tmpUser.firstName = obj[@"name"];
                        tmpUser.lastName = @"";
                    }
                    tmpUser.avatarURLString = obj[@"picture"][@"data"][@"url"];
                    [allFriends addObject:tmpUser.uuid];
                    [currentDataProvider.dataStore addObject:tmpUser withLoadBehavior:kPAUStoreAdditionBehaviorDefault];
                    
                }];
                [tmpCollection addItems:allFriends forRange:NSMakeRange(0, [allFriends count]) inOrder:nil withReplaceAll:NO];
                [self.friendsCollectionView reloadData];

                
            }];
        }];
    }
    

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//   [self.friendsCollectionView reloadData];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    PAUDataProvider *currentDataProvider = [[PAUDataProviderManager sharedProviderManager] providerForUser:[PAUDataProviderManager sharedProviderManager].currentUserUUID];
    PAUCollection *tmpCollection = [currentDataProvider.dataStore collectionWithDisplayIdentifier:@"me.friends"];
    return [[tmpCollection itemsInOrder:nil] count];
    
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cvCell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    PAUDataProvider *currentDataProvider = [[PAUDataProviderManager sharedProviderManager] providerForUser:[PAUDataProviderManager sharedProviderManager].currentUserUUID];
    PAUCollection *tmpCollection = [currentDataProvider.dataStore collectionWithDisplayIdentifier:@"me.friends"];
    PAUUser *tmpUser = (PAUUser *)[currentDataProvider.dataStore objectWithUUID:[tmpCollection itemsInOrder:nil][indexPath.row]];
    [(UIImageView *)[cell viewWithTag:100] removeFromSuperview];
    [[PAUImageCache defaultCache] imageForURL:[NSURL URLWithString:tmpUser.avatarURLString] size:CGSizeMake(50, 50) mode:UIViewContentModeCenter availableBlock:^(UIImage *image) {
        UIImageView *tmpImageView = [[UIImageView alloc] initWithImage:image];
        tmpImageView.frame = CGRectMake(0, 0, 50, 50);
        tmpImageView.contentMode = UIViewContentModeScaleToFill;
        tmpImageView.tag = 100;
        [cell.contentView addSubview:tmpImageView];
    }];
    
    PAUChallenge *tmpChallenge = (PAUChallenge *)[currentDataProvider.dataStore objectWithUUID:@"com.current.challenge"];
    
    [[collectionView cellForItemAtIndexPath:indexPath] contentView].layer.borderColor = [UIColor clearColor].CGColor;
    [[collectionView cellForItemAtIndexPath:indexPath] contentView].layer.borderWidth = 0.0;

    if([tmpChallenge.inviteesUUIDs containsObject:tmpUser.uuid]) {
        [[collectionView cellForItemAtIndexPath:indexPath] contentView].layer.borderColor = [UIColor blueColor].CGColor;
        [[collectionView cellForItemAtIndexPath:indexPath] contentView].layer.borderWidth = 3.0;
    } else {
        [[collectionView cellForItemAtIndexPath:indexPath] contentView].layer.borderColor = [UIColor clearColor].CGColor;
        [[collectionView cellForItemAtIndexPath:indexPath] contentView].layer.borderWidth = 0.0;
    }

    
    //    cell.backgroundColor = (indexPath.row %2 )? [UIColor blueColor]: [UIColor greenColor];
    return cell;
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PAUDataProvider *currentDataProvider = [[PAUDataProviderManager sharedProviderManager] providerForUser:[PAUDataProviderManager sharedProviderManager].currentUserUUID];

    PAUChallenge *tmpChallenge = (PAUChallenge *)[currentDataProvider.dataStore objectWithUUID:@"com.current.challenge"];
    PAUCollection *tmpCollection = [currentDataProvider.dataStore collectionWithDisplayIdentifier:@"me.friends"];
    PAUUser *tmpUser = (PAUUser *)[currentDataProvider.dataStore objectWithUUID:[tmpCollection itemsInOrder:nil][indexPath.row]];
    [tmpChallenge.inviteesUUIDs addObject:tmpUser.uuid];
    [[collectionView cellForItemAtIndexPath:indexPath] contentView].layer.borderColor = [UIColor blueColor].CGColor;
    [[collectionView cellForItemAtIndexPath:indexPath] contentView].layer.borderWidth = 3.0;
    
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PAUDataProvider *currentDataProvider = [[PAUDataProviderManager sharedProviderManager] providerForUser:[PAUDataProviderManager sharedProviderManager].currentUserUUID];

    PAUChallenge *tmpChallenge = (PAUChallenge *)[currentDataProvider.dataStore objectWithUUID:@"com.current.challenge"];
    PAUCollection *tmpCollection = [currentDataProvider.dataStore collectionWithDisplayIdentifier:@"me.friends"];
    PAUUser *tmpUser = (PAUUser *)[currentDataProvider.dataStore objectWithUUID:[tmpCollection itemsInOrder:nil][indexPath.row]];
    [tmpChallenge.inviteesUUIDs removeObject:tmpUser.uuid];
    
    [[collectionView cellForItemAtIndexPath:indexPath] contentView].layer.borderColor = [UIColor clearColor].CGColor;
    [[collectionView cellForItemAtIndexPath:indexPath] contentView].layer.borderWidth = 0.0;
    

}


@end
