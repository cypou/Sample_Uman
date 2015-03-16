/*
 *  PAUSessionTokenCachingStrategy.h
 *  Project : Pauser
 *
 *  Description : A token cache strategy for Facebook.This will allow to use the server
 *  and not the pref at storage
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2014/10/15
 *  Copyright (c) 2014 Symille. All rights reserved.
 *
 */

@import Foundation;

#import <FacebookSDK/FacebookSDK.h>
#import <FacebookSDK/FBSessionTokenCachingStrategy.h>


@interface PAUSessionTokenCachingStrategy : FBSessionTokenCachingStrategy

@end
