/*
 *  PAUSocialFacebookEngine.h
 *  Project : Pauser
 *
 *  Description : A object dealing with the integration of Facebook
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2014/10/15
 *  Copyright (c) 2014 Symille. All rights reserved.
 *
 */

@import Foundation;

#import <FacebookSDK/FacebookSDK.h>
#import "PAUSocialEngine.h"

@interface PAUSocialFacebookEngine : PAUSocialEngine
{
    FBSession *_session;
}

/* Access to singleton : maybe move to a factory kind of things */
+ (PAUSocialFacebookEngine*)commonEngine;


/* Will start a login session */
- (void)logThroughEngine;
@end
