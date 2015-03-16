/*
 *  PAUUser.h
 *  Project : Pauser
 *
 *  Description : A user on the Petit Bambou platorm
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2014/10/15
 *  Copyright (c) 2014 Symille. All rights reserved.
 *
 */

@import Foundation;

#import "PAUBaseObject.h"

typedef NS_ENUM(NSInteger, PAUUserRole) {
    kPAUUserRoleUnknown = 0,
    kPAUUserRoleUser = 100
};


extern NSString *const kPAUUserRegistrationFieldUsage;

@interface PAUUser : PAUBaseObject
{
    NSMutableArray *_deviceUUIDs;
    NSMutableArray *_mediaUUIDs;
    NSMutableArray *_openProgramUUIDs;
    NSMutableArray *_extraProgramUUIDs;
    NSMutableArray *_disabledProgramUUIDs;
}

@property (nonatomic,assign) BOOL fbPublish;
@property (nonatomic,strong) NSString *email;
@property (nonatomic,strong) NSString *lastName;
@property (nonatomic,strong) NSString *firstName;
@property (nonatomic,strong) NSString *avatarURLString;
@property (nonatomic,strong) NSString *password;
@property (nonatomic,strong) NSString *facebookID;
@property (nonatomic,strong) NSString *facebookToken;
@property (nonatomic,assign) PAUUserRole role;
@property (nonatomic,assign) BOOL hasSubscribed;
@property (nonatomic,strong) NSString *authToken;
@property (nonatomic,assign) int successChallenges;
@property (nonatomic,assign) int failedChallenges;
@property (nonatomic,strong) NSString *refreshToken;
@property (nonatomic,strong) NSDictionary *metricsStats;
@property (nonatomic,strong, readonly) NSArray *deviceUUIDs;
@property (nonatomic,strong, readonly) NSArray *mediaUUIDs;
@property (nonatomic,strong, readonly) NSArray *extraProgramUUIDs;
@property (nonatomic,strong, readonly) NSArray *openProgramUUIDs;
@property (nonatomic,strong, readonly) NSArray *disabledProgramUUIDs;


/* Add a device to the array of devices */
- (void)addDeviceWithUUID:(NSString *)deviceUUID;

/* Add a device to the array of devices */
- (void)addMediaWithUUID:(NSString *)mediaUUID;

@end
