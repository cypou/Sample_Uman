/*
 *  PAUDataProviderManager.h
 *  Project : Pauser
 *
 *  Description : the PAU data provider manager is a singleton. Basically it allows
 *  to deal with multiple data provider, each one being associated with one user. However
 *  in this first version only one user can eb active at one time. That implies that starting session
 *  will stop the one of previous user (switch possible but not conccurent sessions)
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2014/10/15
 *  Copyright (c) 2014 Symille. All rights reserved.
 *
 */

@import Foundation;
@import SystemConfiguration;

extern NSString *const kPAUTemporaryUser;
extern NSString *const kPAUNobodyUser;      //when a manager is needed for an operation like recovery of password
extern NSString *const kPAUAnonymousUser;
extern NSString *const kPAULastUser;

extern NSString *const kPAURegistrationNotification;
extern NSString *const kPAURegistrationStatusKey;
extern NSString *const kPAURegistrationUserUUIDKey;
extern NSString *const kPAURegistrationErrorUUIDKey;

extern NSString *const kPAUSessionStartNotification;
extern NSString *const kPAUSessionStopNotification;
extern NSString *const kPAUSessionStartStatusKey;
extern NSString *const kPAUSessionUserUUIDKey;
extern NSString *const kPAUSessionErrorUUIDKey;

extern NSString *const kPAURegisterFacebookTokenKey;
extern NSString *const kPAURegisterEmailKey;
extern NSString *const kPAURegisterPasswordKey;
extern NSString *const kPAURegisterPasswordConfirmationKey;     //Used for test
extern NSString *const kPAURegisterParameterMissTestKey;        //Used for test

extern NSString *const kPAUPreferenceLastUserKey;
extern NSString *const kPAULastUserPersistentInformationMehod;
extern NSString *const kPAULastUserPersistentInformationKey;        //key could be a unique ID or anything
extern NSString *const kPAULastUserPersistentInformationSecret;     //secret could be a password or a token
extern NSString *const kPAULastUserPersistentInformationUUID;

extern NSString *const kPAUNetworkStateDidEnterOnLineMode;
extern NSString *const kPAUNetworkStateDidEnterOffLineMode;

typedef NS_ENUM(NSInteger, PAUEnvironnment) {
    kPAUEnvironnmentNone = 0,
    kPAUEnvironnmentDevelopment,
    kPAUEnvironnmentStaging,
    kPAUEnvironnmentProduction,
};


typedef NS_ENUM(NSInteger, PAURegistrationMethod) {
    kPAURegistrationMethodNone = 0,
    kPAURegistrationMethodEmailPassword,
    kPAURegistrationMethodSingleToken,
    kPAURegistrationMethodFacebook,
    kPAURegistrationMethodGooglePlus
};


@class PAUDataProvider;
@class PAUUser;

@interface PAUDataProviderManager : NSObject
{
    SCNetworkReachabilityRef _networkAccessReachability;
    SCNetworkReachabilityFlags _networkFlags;
    NSMutableDictionary *_allDataProviders;
    NSString *_currentUserUUID;
}

@property (nonatomic,strong) NSString *currentUserUUID;
@property (nonatomic, assign) BOOL isOnLine;
@property (nonatomic, assign) SCNetworkReachabilityFlags networkFlags;

/* returns the singleton for the provider manager */
+ (PAUDataProviderManager *)sharedProviderManager;

/* Session start for a given user */
- (BOOL)startSessionForUser:(NSString *)userID;

/* Will return the provider for a given user */
- (PAUDataProvider *)providerForUser:(NSString *)userUUID;

/* Will return the provider for a given user */
- (PAUDataProvider *)providerWithDescriptor:(NSDictionary *)descriptor;

/* Will return all user that have been considered during the session */
- (NSArray *) userUUIDs;

/* Works only for  temporary user */
- (void) mutateUserFromUUID:(NSString *)previousUserUUID toUUID:(NSString *)newUserUUID;

/* Will handle the major server name */
- (NSString *)serverNameForEnvironnment:(PAUEnvironnment) environnement;

/* Will register a user : returns YES if teh register query has been send. But this will not mean the registration has succeed
   A notification will be sent with success or failure of the operation. If successful a provider for the user is created, if 
   not no provider fr the user is guarantee to exist past _AFTER_ the sending and receiving of registration status notification. 
   However the fact that it is GUARANTEED to exists during any method listing to the registration notification allows to query any
   error object */
- (BOOL) registerUserWithMethod:(PAURegistrationMethod)method parameters:(NSDictionary *)parameterDictionary;

/* Save the last user information in a secure (or less secure place) */
- (void) saveLastUserInformationAsPersistent:(PAUUser *)tmpUser;

/* Read back last user information */
- (NSDictionary *)lastUserPersistentInformation;

/* Read back last user information */
- (void)eraseLastUserPersistentInformation;


@end
