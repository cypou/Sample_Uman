/*
 *  PAUMedia.h
 *  Project : Pauser
 *
 *  Description : A media on the Petit Bambou platorm
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2014/06/21
 *  Copyright (c) 2014 Symille. All rights reserved.
 *
 */

@import Foundation;

#import "PAUBaseObject.h"

@interface PAUChallenge : PAUBaseObject
{
    NSMutableArray *_inviteesUUIDs;
}
@property (nonatomic,strong) NSString *title;
@property (nonatomic,strong) NSString *challengeDescription;
@property (nonatomic,strong) NSMutableArray *inviteesUUIDs;
@property (nonatomic, assign) CGFloat durationInSeconds;
@property (nonatomic, assign) CGFloat remainingDuration;
@property (nonatomic,assign) int status;
@property (nonatomic,assign) BOOL started;

@end
