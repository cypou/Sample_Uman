/*
 *  PAUDataProvider.h
 *  Project : Pauser
 *
 *  Description : a PAU data provider will provide the main point for the UI
 *  to get data for a user. The Data provider contains a storage where every object 
 *  is stored. 
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2014/10/15
 *  Copyright (c) 2014 Symille. All rights reserved.
 *
 */

@import Foundation;

#define PAUDATAPROVIDERLOG YES && PAUGLOBALLOGENABLED

#import "PAUBaseObject.h"

@class PAUDataStore;
@class PAUHTTPTask;
@class PAUUser;

typedef void (^PAUPreparseBlock)(PAUHTTPTask *task, id JSONCoreRequestData);
typedef void (^PAUCompletionBlock)(PAUHTTPTask *task);
typedef void (^PAUProviderBaseFetchCompletionBlock)(BOOL success);

typedef NS_ENUM(NSInteger, PAUDataProviderState) {
    kPAUDataProviderStateUnknown = 0,
    kPAUDataProviderStateNotRegistered,
    kPAUDataProviderStatePendingRegistrationApproval,
    kPAUDataProviderStateInSession,
    kPAUDataProviderStateNoSession
};


@interface PAUDataProvider : NSObject<NSURLSessionDelegate>
{
    NSString *_userUUID;

    PAUDataStore *_dataStore;
    PAUDataProviderState _state;
    
    NSString *_serverName;
    NSURLSession *_foregroundSession;         //Maybe we need to create a second session for background task
    NSOperationQueue *_sessionDelegateQueue;
    NSMutableDictionary *_runningTasks;
}

@property (nonatomic, strong) NSString *userUUID;
@property (nonatomic, strong, readonly) PAUUser *user;        //for KVO compatibility
@property (nonatomic, strong) PAUDataStore *dataStore;
@property (nonatomic, assign) PAUDataProviderState state;
@property (nonatomic, strong) NSURLSession* foregroundSession;
@property (nonatomic, strong) NSURLSession* backgroundSession;

/* Initialization. Usually not called directly but only through the Data Provider managemer */
- (id)initForUser:(NSString *)user;

/* Will start a session in the app: do not use directly call the data provider startSessionForUser */
- (void)startSession;

/* Will start a session in the app: do not use directly call the data provider startSessionForUser to stop the previous */ 
- (void)stopSession;

/* This will do the basic fetch taking in account the fact that there may be cached data */
- (void) fetchBaseDataWithCompletionBlock:(PAUProviderBaseFetchCompletionBlock)completionBlock;

/* Main interface to do queries and all */
- (NSString *)launchRequestToEndPointPath:(NSString *)endPointPath andHTTPMethod:(NSString *)HTTPMethod useSecureConnection:(BOOL)isSecure inBackground:(BOOL)background withBody:(NSDictionary *)body preparsingBlock:(PAUPreparseBlock)preparsingBlock completionBlock:(PAUCompletionBlock)completionBlock collectionParsingBlock:(PAUParsingCollectionBlock)collectionParsingBlock;

@end
