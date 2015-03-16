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

#import "PAUDataProviderManager.h"
#import "PAUSocialEngine.h"
#import "PAUSocialFacebookEngine.h"
#import "PAUSessionTokenCachingStrategy.h"

static PAUSocialFacebookEngine *_commonEngine = nil;

// 1391773371077662

//a69461e5a34d8a2898cbf20874fcfb35

@implementation PAUSocialFacebookEngine


/* Access to singleton */
+ (PAUSocialFacebookEngine*)commonEngine
{
	@synchronized (self) {
		if (_commonEngine == nil) {
			_commonEngine = [[PAUSocialFacebookEngine alloc] init];
		}
	}
    return _commonEngine;
}

/* Init : make sure we can get all data */
- (id) init {
	self = [super init];
    if(self) {
        _session = nil;
    }
    return self;
}

/* Will start a login session */
- (void)logThroughEngine
{
    if ((nil == _session) || (NO == _session.isOpen))
    {
        _session =[[FBSession alloc] initWithAppID:nil
                                       permissions:@[@"email"]
                                   urlSchemeSuffix:nil
                                tokenCacheStrategy:[[PAUSessionTokenCachingStrategy alloc] init] ];
        
        
          FBSessionLoginBehavior behavior = FBSessionLoginBehaviorUseSystemAccountIfPresent;
//        FBSessionLoginBehavior behavior = FBSessionLoginBehaviorWithFallbackToWebView;
        [_session openWithBehavior:behavior
                 completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                     [[PAUDataProviderManager sharedProviderManager] registerUserWithMethod:kPAURegistrationMethodFacebook
                                                                                 parameters:@{kPAURegisterFacebookTokenKey:session.accessTokenData.accessToken}];
                 }];
    }
}

@end
