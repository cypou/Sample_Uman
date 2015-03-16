/*
 *  PAUSessionTokenCachingStrategy.m
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

#import "PAUSessionTokenCachingStrategy.h"
#import "PAULogger.h"

#define PAUSESSIONTOKENCACHINGSTRATEGYLOGENABLED YES && PAUGLOBALLOGENABLED

@implementation PAUSessionTokenCachingStrategy

/* Asked to cache a request result. Send back to the engine */
- (void)cacheTokenInformation:(NSDictionary*)tokenInformation
{
    PAULog(PAUSESSIONTOKENCACHINGSTRATEGYLOGENABLED, @"[PAUSessionTokenCachingStrategy] cacheTokenInformation with info %@", tokenInformation);
}

/* Retrieving of cached information */
- (NSDictionary*)fetchTokenInformation
{
    PAULog(PAUSESSIONTOKENCACHINGSTRATEGYLOGENABLED, @"[PAUSessionTokenCachingStrategy] fetchTokenInformation");
    return [NSDictionary dictionary];
}

/* Remove informaiton form the server */
- (void)clearToken
{
    PAULog(PAUSESSIONTOKENCACHINGSTRATEGYLOGENABLED, @"[PAUSessionTokenCachingStrategy] fetchTokenInformation");
}



@end
