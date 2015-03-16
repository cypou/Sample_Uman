/*
 *  PAUDataProviderManager.h
 *  Project : Pauser
 *
 *  Description : the PAU data provider manager is a singleton. Basically it allows
 *  to deal with multiple data provider and in particular anonymous user
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2014/10/15
 *  Copyright (c) 2014 Symille. All rights reserved.
 *
 */

@import Foundation;
@import UIKit;

#import <FacebookSDK/FacebookSDK.h>

#import <arpa/inet.h>
#import <netinet/in.h>
#import <sys/utsname.h>
#import <sys/socket.h>

#import "PAUDataProvider.h"
#import "PAUDataProviderManager.h"
#import "PAUDataStore.h"
#import "PAUHTTPTask.h"
#import "PAULogger.h"
#import "PAUUtilities.h"
#import "PAUUser.h"

#define PAUDATAPROVIDERMANAGERLOG YES && PAUGLOBALLOGENABLED

NSString *const kPAUTemporaryUser = @"PAU.user.temporary";
NSString *const kPAUNobodyUser = @"PAU.user.nobody";
NSString *const kPAUAnonymousUser = @"PAU.user.anonymous";
NSString *const kPAULastUser = @"PAU.user.last";

NSString *const kPAURegistrationNotification = @"PAURegistrationNotification";
NSString *const kPAUSessionStartNotification = @"PAUSessionStartNotification";
NSString *const kPAUSessionStopNotification = @"PAUSessionStopNotification";

NSString *const kPAURegistrationStatusKey = @"PAUSessionRegistrationStatus";
NSString *const kPAURegistrationUserUUIDKey = @"PAURegistrationUserUUID";
NSString *const kPAURegistrationErrorUUIDKey = @"PAURegistrationErrorUUID";
NSString *const kPAUSessionStartStatusKey = @"PAUSessionStartStatus";
NSString *const kPAUSessionUserUUIDKey = @"PAUSessionUserUUID";
NSString *const kPAUSessionErrorUUIDKey = @"PAUSessionErrorUUIDKey";

NSString *const kPAURegisterFacebookTokenKey = @"PAURegisterFacebookTokenKey";
NSString *const kPAURegisterEmailKey = @"PAURegisterEmailKey";
NSString *const kPAURegisterPasswordKey = @"PAURegisterPasswordKey";
NSString *const kPAURegisterPasswordConfirmationKey = @"PAURegisterPasswordConfirmationKey";
NSString *const kPAURegisterParameterMissTestKey = @"kPAURegisterParameterMissTestKey";

NSString *const kPAUPreferenceLastUserKey = @"PAUPreferenceLastUser";
NSString *const kPAULastUserPersistentInformationMehod = @"PAULastUserPersistentInformationMehod";
NSString *const kPAULastUserPersistentInformationKey = @"PAULastUserPersistentInformationKey";
NSString *const kPAULastUserPersistentInformationSecret = @"PAULastUserPersistentInformationSecret";
NSString *const kPAULastUserPersistentInformationUUID = @"PAULastUserPersistentInformationUUID";
NSString *const kPAULastUserPersistentInformationToken = @"PAULastUserPersistentInformationToken";

NSString *const kPAUNetworkStateDidEnterOnLineMode = @"PAUNetworkStateDidEnterOnLineMode";
NSString *const kPAUNetworkStateDidEnterOffLineMode = @"PAUNetworkStateDidEnterOffLineMode";


/* Detection of online/offline change state */
static void PAUNetworkReachabilityCallBack(SCNetworkReachabilityRef	target,SCNetworkReachabilityFlags flags, void *info)
{
    PAUDataProviderManager *tmpManager = (__bridge PAUDataProviderManager *)info;
    BOOL wasOnline = tmpManager.isOnLine;
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
    
    tmpManager.networkFlags = flags;
    if(isReachable ) {
        tmpManager.isOnLine = (isReachable && !needsConnection);
    } else {
        tmpManager.isOnLine = NO;
    }
    if(wasOnline != tmpManager.isOnLine) {
        [[NSNotificationCenter defaultCenter] postNotificationName:(tmpManager.isOnLine)? kPAUNetworkStateDidEnterOnLineMode: kPAUNetworkStateDidEnterOffLineMode object:nil];
    }
}


@implementation PAUDataProviderManager

@synthesize currentUserUUID = _currentUserUUID;
@synthesize isOnLine = _isOnLine;
@synthesize networkFlags = _networkFlags;

#pragma mark == LIFE CYCLE ==

/* Returns the singleton for the provider manager */
+ (PAUDataProviderManager *)sharedProviderManager
{
    static dispatch_once_t pred = 0;
    __strong static PAUDataProviderManager *_sharedProviderManager = nil;
    dispatch_once(&pred, ^{
        _sharedProviderManager = [[PAUDataProviderManager alloc] init]; // or some other init method
    });
    return _sharedProviderManager;
}

/* Designated initializer */
- (id)init
{
    self = [super init];
    if(self) {
        PAULog(PAUDATAPROVIDERMANAGERLOG, @"[PAUDATAPROVIDERMANAGER] initializing data provider manager");
        _allDataProviders = [[NSMutableDictionary alloc] init];
        [self _initializeReachability];
    }
    return self;
}

/* Set up reachability on the main server */
- (BOOL)_initializeReachability
{
    BOOL result = YES;
    struct sockaddr_in zeroAddress;
    SCNetworkReachabilityFlags flags = 0;
    
    bzero(&zeroAddress, sizeof(zeroAddress));
    
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    _networkAccessReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityGetFlags(_networkAccessReachability, &flags);

    self.networkFlags = flags;
    BOOL isReachable = ((flags & kSCNetworkFlagsReachable) == kSCNetworkFlagsReachable);
    BOOL needsConnection = ((flags & kSCNetworkFlagsConnectionRequired) == kSCNetworkFlagsConnectionRequired);
    self.isOnLine = (isReachable ) ? (isReachable && !needsConnection) : NO;
    
    SCNetworkReachabilityContext tmpContext = {0, (__bridge void *)(self), NULL, NULL, NULL};
    SCNetworkReachabilitySetCallback(_networkAccessReachability,PAUNetworkReachabilityCallBack, &tmpContext);
    SCNetworkReachabilityScheduleWithRunLoop(_networkAccessReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    PAULog(PAUDATAPROVIDERMANAGERLOG, @" --> Reachability online is %d, flags %x", self.isOnLine, self.networkFlags);
    return result;
}


#pragma mark == SESSION MANAGEMENT ==
/* Will return all user that have been considered during the session */
- (NSArray *) userUUIDs
{
    return [_allDataProviders allKeys];
}


/* Session start for a given user */
- (BOOL) startSessionForUser:(NSString *)userID
{
    PAULog(PAUDATAPROVIDERMANAGERLOG, @"[PAUDATAPROVIDERMANAGER] Start session for user %@", userID);
    BOOL result = NO;

    if(_currentUserUUID) {
        PAULog(PAUDATAPROVIDERMANAGERLOG, @" --> Stopping for previous user %@", _currentUserUUID);
        [[self providerForUser:self.currentUserUUID] stopSession];
    }

    if(userID && [userID length] && [FBSession activeSession].state == FBSessionStateCreatedTokenLoaded) {
        self.currentUserUUID = userID; //if this fails this will go back to nil
        PAUDataProvider *tmpProvider = [self providerForUser:self.currentUserUUID];
        if(tmpProvider) {
            PAULog(PAUDATAPROVIDERMANAGERLOG, @" --> A provider for this user has been found");
            [tmpProvider startSession];
            self.currentUserUUID = tmpProvider.userUUID;
            result = YES;
        } else {
            PAULog(PAUDATAPROVIDERMANAGERLOG, @" --> No provider found for this user ");
            self.currentUserUUID = nil;
        }
    }
    return result;
}
    

#pragma mark == PROVIDER ACCESS ==
/* Will return the provider for a given user */
- (PAUDataProvider *)providerForUser:(NSString *)userUUID
{
//    PAULog(PAUDATAPROVIDERMANAGERLOG, @"[PAUDATAPROVIDERMANAGER] getting provider for user %@", userUUID);
    PAUDataProvider *result = nil;
    BOOL queryLastUser = NO;
    
    if([userUUID isEqualToString:kPAULastUser]) {
        queryLastUser = YES;
        NSDictionary *tmpDico = [self lastUserPersistentInformation];
        userUUID = tmpDico[kPAULastUserPersistentInformationUUID];
        PAULog(PAUDATAPROVIDERMANAGERLOG, @" --> last user so in fact %@", userUUID);
    }
    if(nil == userUUID) return result;
    
    result = _allDataProviders[userUUID];
    if(nil == result) {
        PAULog(PAUDATAPROVIDERMANAGERLOG, @" --> Provider will be created");
        result = [[PAUDataProvider alloc] initForUser:userUUID];
        [_allDataProviders setObject:result forKey:userUUID];
        if(queryLastUser) {
            PAULog(PAUDATAPROVIDERMANAGERLOG, @" --> This is for last user");
            NSDictionary *tmpDico = [self lastUserPersistentInformation];
            PAUUser *tmpUser = [[PAUUser alloc] initWithUUID:userUUID];
            if(kPAURegistrationMethodEmailPassword == [tmpDico[kPAULastUserPersistentInformationMehod] intValue]) {
                PAULog(PAUDATAPROVIDERMANAGERLOG, @" --> And it was registered with user/password");
                tmpUser.email  = tmpDico[kPAULastUserPersistentInformationKey];
                tmpUser.password  = tmpDico[kPAULastUserPersistentInformationSecret];
            } else if(kPAURegistrationMethodSingleToken == [tmpDico[kPAULastUserPersistentInformationMehod] intValue]) {
                PAULog(PAUDATAPROVIDERMANAGERLOG, @" --> And it was registered with one token");
                tmpUser.password  = tmpDico[kPAULastUserPersistentInformationSecret];
            } else if(kPAURegistrationMethodFacebook == [tmpDico[kPAULastUserPersistentInformationMehod] intValue]) {
                tmpUser.email  = tmpDico[kPAULastUserPersistentInformationKey];
                tmpUser.facebookToken  = tmpDico[kPAULastUserPersistentInformationSecret];
                tmpUser.facebookID = tmpUser.uuid;
                tmpUser.firstName = tmpDico[@"first_name"];
                tmpUser.lastName = tmpDico[@"last_name"];
                tmpUser.failedChallenges = 4+rand()%3;
                tmpUser.successChallenges = 6+rand()%14;
            }
            PAULog(PAUDATAPROVIDERMANAGERLOG, @" --> password is %@", tmpUser.password);
            [result.dataStore addObject:tmpUser withLoadBehavior:kPAUStoreAdditionBehaviorDefault];
        } else if ([userUUID isEqualToString:kPAUTemporaryUser]) {
            PAUUser *tmpUser = [[PAUUser alloc] initWithUUID:userUUID];
            [result.dataStore addObject:tmpUser withLoadBehavior:kPAUStoreAdditionBehaviorDefault];
        }
    }    
    return result;
}

/* Will return the provider for a given user */
- (PAUDataProvider *)providerWithDescriptor:(NSDictionary *)descriptor
{
    PAUDataProvider *result = nil;
    NSSet *matchingKey = [_allDataProviders keysOfEntriesPassingTest:^BOOL(id key, PAUDataProvider *provider, BOOL *stop) {
        __block BOOL providerMatch = YES;
        [descriptor enumerateKeysAndObjectsUsingBlock:^(NSString *keyPath, id value, BOOL *stop1) {
            if(NO == [[provider valueForKeyPath:keyPath] isEqualToString:value]) {
                providerMatch = NO;
                *stop1 = YES;
            }
        }];
        if(providerMatch) *stop = YES;
        return providerMatch;
    }];
    
    if([matchingKey count]) {
        result = _allDataProviders[[matchingKey allObjects][0]];
    } else {
        if(_allDataProviders[kPAUTemporaryUser]) {
            [_allDataProviders removeObjectForKey:kPAUTemporaryUser];
        }
        result = [self providerForUser:kPAUTemporaryUser];
        [descriptor enumerateKeysAndObjectsUsingBlock:^(NSString *keyPath, id value, BOOL *stop1) {
            [result setValue:value forKeyPath:keyPath];
        }];
    }
    return  result;
}


/* Will handle the major server name */
- (NSString *)serverNameForEnvironnment:(PAUEnvironnment) environnement
{
    switch(environnement) {
        case kPAUEnvironnmentNone:
            return nil;
        case kPAUEnvironnmentDevelopment:
            return nil;
        case kPAUEnvironnmentStaging:
            return @"api-staging.petitbambou.com";
        case kPAUEnvironnmentProduction:
            return nil;
        default:
            return nil;
    }
}

- (void) mutateUserFromUUID:(NSString *)previousUserUUID toUUID:(NSString *)newUserUUID
{
    if([previousUserUUID isEqualToString:kPAUTemporaryUser]) {
        _allDataProviders[newUserUUID] = _allDataProviders[kPAUTemporaryUser];
        [_allDataProviders removeObjectForKey:kPAUTemporaryUser];
        PAUDataProvider *tmpProvider = _allDataProviders[newUserUUID];
        tmpProvider.userUUID = newUserUUID;
    }
}

/* Will register a user : returns YES if teh register query has been send. But not about the result */
- (BOOL)registerUserWithMethod:(PAURegistrationMethod)method parameters:(NSDictionary *)parameterDictionary
{
    PAULog(PAUDATAPROVIDERMANAGERLOG, @"[PAUDATAPROVIDERMANAGER] Registring with method %d", method);

    BOOL result = NO;
    switch(method) {
        case kPAURegistrationMethodEmailPassword:
        {
            NSString *email = parameterDictionary[kPAURegisterEmailKey];
            NSString *password = parameterDictionary[kPAURegisterPasswordKey];
            
            if((nil == email) || (0 == [email length]) || (nil== password) || (0 == [password length])) {
                return result;
            }
            NSDictionary * allParameters = @{@"email":email, @"password":PAUSha1FromString(password)};
            
            PAUDataProvider *tmpProvider = [self providerForUser:email];
            tmpProvider.state= kPAUDataProviderStateNotRegistered;
            
            NSString *endPoint = [NSString stringWithFormat:@"/V1/User?fields=uuid,email,is_subscriber"];
            PAULog(PAUDATAPROVIDERMANAGERLOG, @"== Query to endPoint POST %@", endPoint);
            PAULog(PAUDATAPROVIDERMANAGERLOG, @"    --> Body %@",allParameters);

            [tmpProvider launchRequestToEndPointPath:endPoint andHTTPMethod:@"POST" useSecureConnection:NO inBackground:NO withBody:allParameters preparsingBlock:^(PAUHTTPTask *task, id JSONCoreRequestData) {

                if(task.statusCode < kCFErrorHTTPAuthenticationTypeUnsupported) {
                    tmpProvider.userUUID = JSONCoreRequestData[@"data"][@"uuid"];
                    _allDataProviders[tmpProvider.userUUID] = tmpProvider;
                    [_allDataProviders removeObjectForKey:JSONCoreRequestData[@"data"][@"email"]];
                }
                
            } completionBlock:^(PAUHTTPTask *task) {
                if(task.statusCode < kCFErrorHTTPAuthenticationTypeUnsupported) {
                    PAUUser *tmpUser = (PAUUser *)[tmpProvider.dataStore objectWithUUID:tmpProvider.userUUID];
                    tmpUser.email = email;
                    tmpUser.password = password;
                    tmpProvider.state = kPAUDataProviderStateNoSession;
                    NSDictionary *infoDictionary = @{kPAURegistrationStatusKey:@YES, kPAURegistrationUserUUIDKey:tmpProvider.userUUID};
                    [[NSNotificationCenter defaultCenter] postNotificationName:kPAURegistrationNotification object:nil userInfo:infoDictionary];
                } else {
                    tmpProvider.state = kPAUDataProviderStateNotRegistered;
                    PAUCollection *taskCollection = [tmpProvider.dataStore collectionWithDisplayIdentifier:task.uuid];
                    NSDictionary *infoDictionary = @{kPAURegistrationStatusKey:@NO, kPAURegistrationUserUUIDKey:tmpProvider.userUUID, kPAURegistrationErrorUUIDKey:[[taskCollection itemsInOrder:nil] objectAtIndex:0]};
                    [[NSNotificationCenter defaultCenter] postNotificationName:kPAURegistrationNotification object:nil userInfo:infoDictionary];
                    [_allDataProviders removeObjectForKey:tmpProvider.userUUID];
                }
            } collectionParsingBlock:nil];            
            break;
        }
        case kPAURegistrationMethodFacebook:
        {
            NSString *fbToken = parameterDictionary[kPAURegisterFacebookTokenKey];
            if((nil == fbToken) || (0 == [fbToken length])) {
                return result;
            }
            NSDictionary * allParameters = @{@"access_token":fbToken};
            PAUDataProvider *tmpProvider = [self providerForUser:fbToken];
            tmpProvider.state= kPAUDataProviderStateNotRegistered;
             NSString *endPoint = [NSString stringWithFormat:@"/V1/User/login-fb?fields=all"];
            [tmpProvider launchRequestToEndPointPath:endPoint andHTTPMethod:@"POST" useSecureConnection:NO inBackground:NO withBody:allParameters preparsingBlock:^(PAUHTTPTask *task, id JSONCoreRequestData) {
                if(task.statusCode < kCFErrorHTTPAuthenticationTypeUnsupported) {
                    tmpProvider.userUUID = JSONCoreRequestData[@"data"][@"uuid"];
                    _allDataProviders[tmpProvider.userUUID] = tmpProvider;
                    [_allDataProviders removeObjectForKey:JSONCoreRequestData[@"data"][@"access_token"]];
                }
            }
            completionBlock:^(PAUHTTPTask *task) {
                if(task.statusCode < kCFErrorHTTPAuthenticationTypeUnsupported) {
                    PAUUser *tmpUser = (PAUUser *)[tmpProvider.dataStore objectWithUUID:tmpProvider.userUUID];
                    [[PAUDataProviderManager sharedProviderManager] saveLastUserInformationAsPersistent:tmpUser];
                    self.currentUserUUID = tmpProvider.userUUID;
                    NSDictionary *tmpDictionary = @{kPAUSessionStartStatusKey:@YES, kPAUSessionUserUUIDKey:self.currentUserUUID};
                    [[NSNotificationCenter defaultCenter] postNotificationName:kPAUSessionStartNotification object:nil userInfo:tmpDictionary];
                } else {
                    NSDictionary *tmpDictionary = @{kPAUSessionStartStatusKey:@NO, kPAUSessionUserUUIDKey:self.currentUserUUID};
                     [[NSNotificationCenter defaultCenter] postNotificationName:kPAUSessionStartNotification object:nil userInfo:tmpDictionary];
                }
                
                
            }
            collectionParsingBlock:nil];
            break;
            
        }
        case kPAURegistrationMethodSingleToken:
        {
            PAUDataProvider *tmpProvider = [self providerForUser:kPAUAnonymousUser];
            tmpProvider.state= kPAUDataProviderStateNotRegistered;
            NSMutableDictionary * allParameters = [NSMutableDictionary dictionary];
            NSString *key = PAUAnonymousDeviceKey();
            NSString *pass = (nil != parameterDictionary[kPAURegisterPasswordKey]) ? parameterDictionary[kPAURegisterPasswordKey]:PAUAnonymousDevicePassword(key);
            NSString *passConfirmation =(nil != parameterDictionary[kPAURegisterPasswordConfirmationKey]) ? parameterDictionary[kPAURegisterPasswordConfirmationKey] : pass;
            
            [allParameters setObject:key forKey:@"user[unique_id]"];
            [allParameters setObject:pass forKey:@"user[password]"];
            if (NO == [parameterDictionary[kPAURegisterParameterMissTestKey] boolValue]){
                [allParameters setObject:passConfirmation  forKey:@"user[password_confirmation]"];
            }
            
            NSString *endPoint = [NSString stringWithFormat:@"/users.json"] ;
            PAULog(PAUDATAPROVIDERMANAGERLOG, @"== Query to endPoint POST %@", endPoint);
            PAULog(PAUDATAPROVIDERMANAGERLOG, @"    --> Body %@",PAUQueryStringFromDictionary(allParameters, NO, NO) );

            [tmpProvider launchRequestToEndPointPath:endPoint andHTTPMethod:@"POST" useSecureConnection:YES inBackground:NO withBody:allParameters preparsingBlock:^(PAUHTTPTask *task, id JSONCoreRequestData) {
                    if(task.statusCode < kCFErrorHTTPAuthenticationTypeUnsupported && [JSONCoreRequestData objectForKey:@"uuid"]) {
                        tmpProvider.userUUID = [JSONCoreRequestData objectForKey:@"uuid"];
                        _allDataProviders[[JSONCoreRequestData objectForKey:@"uuid"]] = tmpProvider;
                        [_allDataProviders removeObjectForKey:kPAUAnonymousUser];
                    }
            } completionBlock:^(PAUHTTPTask *task) {
                if(task.statusCode < 300) {
                    tmpProvider.state = kPAUDataProviderStateNoSession;
                    NSDictionary *infoDictionary = @{kPAURegistrationStatusKey:@YES, kPAURegistrationUserUUIDKey:tmpProvider.userUUID};
                    [[NSNotificationCenter defaultCenter] postNotificationName:kPAURegistrationNotification object:nil userInfo:infoDictionary];
                } else {
                    tmpProvider.state = kPAUDataProviderStateNotRegistered;
                    PAUCollection *taskCollection = [tmpProvider.dataStore collectionWithDisplayIdentifier:task.uuid];
                    NSDictionary *infoDictionary = @{kPAURegistrationStatusKey:@NO, kPAURegistrationUserUUIDKey:tmpProvider.userUUID, kPAURegistrationErrorUUIDKey:[[taskCollection itemsInOrder:nil] objectAtIndex:0]};
                    [[NSNotificationCenter defaultCenter] postNotificationName:kPAURegistrationNotification object:nil userInfo:infoDictionary];
                    [_allDataProviders removeObjectForKey:tmpProvider.userUUID];
                }
            } collectionParsingBlock:nil];
            break;
        }
        default:
            break;
    }
    return result;
}

#pragma mark == MANAGEMENT OF LAST USER INFORMATION ==
/* Save the last user information in a secure (or less secure place) */
- (void) saveLastUserInformationAsPersistent:(PAUUser *)tmpUser
{
    if(tmpUser.email && tmpUser.facebookID) {
        NSDictionary *tmpDictionary = @{kPAULastUserPersistentInformationMehod:@(kPAURegistrationMethodFacebook),
                                            kPAULastUserPersistentInformationKey:tmpUser.email,
                                        @"first_name":tmpUser.firstName,
                                        @"last_name":tmpUser.lastName,
                                        kPAULastUserPersistentInformationSecret:tmpUser.facebookID,
                                        kPAULastUserPersistentInformationUUID:tmpUser.uuid};
        [[NSUserDefaults standardUserDefaults] setObject:tmpDictionary forKey:kPAUPreferenceLastUserKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
//    } else if( tmpUser.email && tmpUser.facebookToken && tmpUser.facebookID ) {
//        NSDictionary *tmpDictionary = @{kPAULastUserPersistentInformationMehod:@(kPAURegistrationMethodFacebook),
//                                        kPAULastUserPersistentInformationKey:tmpUser.email,
//                                        kPAULastUserPersistentInformationSecret:tmpUser.facebookToken,
//                                        kPAULastUserPersistentInformationUUID:tmpUser.uuid};
//        [[NSUserDefaults standardUserDefaults] setObject:tmpDictionary forKey:kPAUPreferenceLastUserKey];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//
//    }
//    } else if(tmpUser.uniqueID) {
//        NSDictionary *tmpDictionary = @{kPAULastUserPersistentInformationMehod:@(kPAURegistrationMethodSingleToken),
//                                        kPAULastUserPersistentInformationKey:tmpUser.uniqueID,
//                                        kPAULastUserPersistentInformationSecret:tmpUser.password,
//                                        kPAULastUserPersistentInformationUUID:tmpUser.uuid,
//                                        kPAULastUserPersistentInformationToken:tmpUser.accessToken};
//        [[NSUserDefaults standardUserDefaults] setObject:tmpDictionary forKey:kPAUPreferenceLastUserKey];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//    }
}

/* Read back last user information */
- (NSDictionary *)lastUserPersistentInformation
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kPAUPreferenceLastUserKey];
}

/* Read back last user information */
- (void)eraseLastUserPersistentInformation
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPAUPreferenceLastUserKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

}


@end
