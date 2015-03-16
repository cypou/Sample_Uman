/*
 *  PAUDevice.m
 *  Project : Pauser
 *
 *  Description : A user device
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2014/10/15
 *  Copyright (c) 2014 Symille. All rights reserved.
 *
 */

@import Foundation;

#import "PAUBaseObject.h"

@interface PAUDevice : PAUBaseObject

@property (nonatomic, strong) NSString *udid;
@property (nonatomic, strong) NSString *userUUID;
@property (nonatomic, strong) NSString *operatingSystem;
@property (nonatomic, strong) NSString *deviceType;
@property (nonatomic, assign) int buildVersion;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSString *appleToken;
@property (nonatomic, strong) NSString *androidToken;


@end
