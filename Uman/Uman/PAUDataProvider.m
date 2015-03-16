/*
 *  PAUDataProvider.m
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

#import "PAUBaseObject.h"
#import "PAUDataStore.h"
#import "PAUDataProvider.h"
#import "PAUDataProviderManager.h"
#import "PAUError.h"
#import "PAUHTTPTask.h"
#import "PAULogger.h"
#import "PAUChallenge.h"
#import "PAUUtilities.h"
#import "PAUUser.h"

#define PAUDATAPROVIDERLOGENABLED YES && PAUGLOBALLOGENABLED

@interface PAUDataProvider()

/* Will create the session and all that is associated, if needed */
- (void)_ensureSessionEnvironment;

@end



@implementation PAUDataProvider

@synthesize userUUID = _userUUID;
@synthesize dataStore = _dataStore;
@synthesize state = _state;
@dynamic  user;

#pragma mark == LIFE CYCLE ==
/* Designated initializer */
- (id)initForUser:(NSString *)user
{
    self = [super init];
    if(self) {
        self.userUUID = user;
        self.state = kPAUDataProviderStateUnknown;
        PAUEnsureDirectoryAtPath([[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:self.userUUID]);
        self.dataStore = [[PAUDataStore alloc] initWithProvider:self];
        [self addObserver:self forKeyPath:@"userUUID" options:NSKeyValueObservingOptionNew context:@"provider_self"];

    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<PAUDataProvider:%p - %@>", self, self.userUUID];
}
#pragma mark == KVO ==

#pragma mark == KVO ==
/* KVO is used when the provider is started with a lastuser in this case we create the cache directory*/
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"userUUID"]) {
        @try {
            NSString * tmpPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:[NSString stringWithFormat:@"data/%@",self.userUUID]];
            if ( PAUEnsureDirectoryAtPath(tmpPath)) {
                PAUEnsurePersistentSQLDatabaseAtDirectory(tmpPath, 1, [PAUDataStore serialiazibleSQLClassName]);
                self.dataStore.documentDataPath = tmpPath;
            }
            
            [self removeObserver:self forKeyPath:@"userUUID" context:@"provider_self" ];
        }
        @catch (NSException *exception) { }
    }
}



- (PAUUser *)user
{
    return (PAUUser*)[self.dataStore objectWithUUID:self.userUUID];
}



#pragma mark == SESSION MANAGEMENT ==
/* Will create the session and all that is associated */
- (void)_ensureSessionEnvironment
{
    if(nil == _foregroundSession) {
        PAULog(PAUDATAPROVIDERLOGENABLED, @"[PAUDATAPROVIDER] Ensuring session environment");
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        sessionConfiguration.HTTPShouldUsePipelining = YES;
        sessionConfiguration.timeoutIntervalForRequest = 30.0;
        _sessionDelegateQueue = [[NSOperationQueue alloc] init];
        self.foregroundSession = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:_sessionDelegateQueue];
        
        sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[[NSBundle mainBundle] bundleIdentifier]];
        self.backgroundSession = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:_sessionDelegateQueue];
        
        _runningTasks = [[NSMutableDictionary alloc] init];
    }
}

/* Will start a session in the app */
- (void)startSession
{
    PAULog(PAUDATAPROVIDERLOGENABLED, @"[PAUDATAPROVIDER] Starting Session");
    [self _ensureSessionEnvironment];
    
    NSString *endPoint = nil;
    PAUUser *providerUser = (PAUUser *)[self.dataStore objectWithUUID:self.userUUID];

    NSDictionary * allParameters = nil;
    
        //in offline we make no call we know effectively that we have started already once otherwise we would nto be at this point
    if(NO == [PAUDataProviderManager sharedProviderManager].isOnLine) {
        NSDictionary *tmpDictionary = @{kPAUSessionStartStatusKey:@YES, kPAUSessionUserUUIDKey:self.userUUID};
        [[NSNotificationCenter defaultCenter] postNotificationName:kPAUSessionStartNotification object:nil userInfo:tmpDictionary];
        return;
    }
        //tmp to start
    if(providerUser.facebookID) {
        NSDictionary *tmpDictionary = @{kPAUSessionStartStatusKey:@YES, kPAUSessionUserUUIDKey:self.userUUID};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kPAUSessionStartNotification object:nil userInfo:tmpDictionary];
        return;
    }
    
    if(providerUser.password) {
        endPoint = [NSString stringWithFormat:@"/V1/User/login?fields=uuid,email,is_subscriber,firstname,lastname"];
        allParameters = @{@"email":providerUser.email, @"password":PAUSha1FromString(providerUser.password)};
    } else if(providerUser.facebookToken) {
        endPoint = [NSString stringWithFormat:@"/V1/User/login-fb?fields=all"];
        allParameters = @{@"access_token":providerUser.facebookToken};
    } else {
        NSLog(@"Error in startSession no providerUser valid");
        return;
    }

    
    [self launchRequestToEndPointPath:endPoint andHTTPMethod:@"POST" useSecureConnection:NO inBackground:NO withBody:allParameters preparsingBlock:^(PAUHTTPTask *task, id JSONData) {
            if(task.statusCode < 300) {
                if([self.userUUID isEqualToString:kPAUTemporaryUser]) {                    
                    PAUUser *tmpUser = (PAUUser *)[self.dataStore objectWithUUID:kPAUTemporaryUser];
                    self.userUUID = JSONData[@"data"][@"uuid"];
                    JSONData[@"data"][@"password"] = tmpUser.password;
                    [self.dataStore removeObjectWithUUID:kPAUTemporaryUser];
                    [[PAUDataProviderManager sharedProviderManager] mutateUserFromUUID:kPAUTemporaryUser toUUID:self.userUUID];
                }
            }
        }
        completionBlock:^(PAUHTTPTask *task) {
            if(task.statusCode < kCFErrorHTTPAuthenticationTypeUnsupported && task.statusCode > 0) {
                
                PAUUser *tmpUser = (PAUUser *)[self.dataStore objectWithUUID:self.userUUID];
                [[PAUDataProviderManager sharedProviderManager] saveLastUserInformationAsPersistent:tmpUser];
                [PAUDataProviderManager sharedProviderManager].currentUserUUID = self.userUUID;
                
                NSDictionary *tmpDictionary = @{kPAUSessionStartStatusKey:@YES, kPAUSessionUserUUIDKey:self.userUUID};
                                                
                [[NSNotificationCenter defaultCenter] postNotificationName:kPAUSessionStartNotification object:nil userInfo:tmpDictionary];
            } else {
                [PAUDataProviderManager sharedProviderManager].currentUserUUID = self.userUUID;

                    //TODO MAke the condition less drastic error 500 should not erase data for example
                if(task.statusCode > 0) { //network errors should not erase last user information
                    [[PAUDataProviderManager sharedProviderManager] eraseLastUserPersistentInformation];
                }
                NSMutableDictionary *tmpDictionary = [NSMutableDictionary dictionaryWithDictionary: @{kPAUSessionStartStatusKey:@NO, kPAUSessionUserUUIDKey:self.userUUID}];
                if(0 != [[[self.dataStore collectionWithDisplayIdentifier:task.uuid] itemsInOrder:nil] count]) {
                    tmpDictionary[kPAUSessionErrorUUIDKey] = [[self.dataStore collectionWithDisplayIdentifier:task.uuid] itemsInOrder:nil][0];
                } else {
                    PAUError *tmpError = [[PAUError alloc] initWithUUID:nil];
                    tmpError.domain = kHTTPErrorDomain;
                    tmpError.code = task.statusCode;
                    tmpError.message = [task.task.originalRequest.URL absoluteString];
                    [self.dataStore addObject:tmpError withLoadBehavior:kPAUStoreAdditionBehaviorDefault];
                    tmpDictionary[kPAUSessionErrorUUIDKey] = tmpError.uuid;
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:kPAUSessionStartNotification object:nil userInfo:tmpDictionary];
            }
    } collectionParsingBlock:nil];
}

/* Will start a session in the app */
- (void)stopSession
{
    NSDictionary *tmpDictionary =  @{kPAUSessionUserUUIDKey:self.userUUID};
    [PAUDataProviderManager sharedProviderManager].currentUserUUID = nil;
    [[PAUDataProviderManager sharedProviderManager] eraseLastUserPersistentInformation];
    [[NSNotificationCenter defaultCenter] postNotificationName:kPAUSessionStopNotification object:nil userInfo:tmpDictionary];
}

/* Get all programs */
- (void)fetchBaseDataWithCompletionBlock:(PAUProviderBaseFetchCompletionBlock)completionBlock
{
    PAULog(PAUDATAPROVIDERLOGENABLED, @"[PAUDATAPROVIDER] Fetch Base Data");
    //here we get the filters and sources (feed)
    __block int queryCount = 0;
    int NQuery = 1;
   
    PAUUser *meUser = (PAUUser *)[self.dataStore objectWithUUID:self.userUUID];
    completionBlock(YES);
}


/* Main interface to do queries and all */
- (NSString *)launchRequestToEndPointPath:(NSString *)endPointPath andHTTPMethod:(NSString *)HTTPMethod useSecureConnection:(BOOL)isSecure inBackground:(BOOL)background withBody:(NSDictionary *)body preparsingBlock:(PAUPreparseBlock)preparsingBlock completionBlock:(PAUCompletionBlock)completionBlock collectionParsingBlock:(PAUParsingCollectionBlock)collectionParsingBlock
{
        //make sure we have a session
    [self _ensureSessionEnvironment];
    
    BOOL isMediaSending = [HTTPMethod isEqualToString:@"POST"] && [endPointPath hasPrefix:@"/V1/Media"] && (nil != body[@"file_to_send"]);
//    NSString *mediaName = body[@"file_to_send"];
    
    
        //Get all parameters from the query string to be able to URL encode them
    NSMutableDictionary *allParameters = [NSMutableDictionary dictionary];
    NSRange queryStringRange = [endPointPath rangeOfString:@"?"];
    if(queryStringRange.location != NSNotFound) {
        NSArray *parameters = [[endPointPath substringFromIndex:queryStringRange.location+1] componentsSeparatedByString:@"&"];
        [parameters enumerateObjectsUsingBlock:^(NSString *oneParameter, NSUInteger idx, BOOL *stop) {
            NSRange tmpRange =  [oneParameter rangeOfString:@"="];
            if(tmpRange.location != NSNotFound) {
                [allParameters setObject:[oneParameter substringFromIndex:tmpRange.location+1] forKey:[oneParameter substringToIndex:tmpRange.location]];
            }
        }];
        endPointPath = PAUEndPointUniqueEndPath([endPointPath substringToIndex:queryStringRange.location]);
    }
    
    
        //Beginning of URL
    NSMutableString *fullURLString =  [NSMutableString string];
    [fullURLString appendString:isSecure ? @"https://":@"http://"];
    [fullURLString appendString:[[PAUDataProviderManager sharedProviderManager] serverNameForEnvironnment:kPAUEnvironnmentStaging]];
    if(NO == [endPointPath hasPrefix:@"/"]) {
        [fullURLString appendString:@"/"];
    }
    [fullURLString appendString:endPointPath];
    
//    if(isMediaSending) fullURLString = @"http://api-staging.webid.fr/test.php";
    
    if([allParameters count]) {
        [fullURLString appendString:@"?"];
        NSMutableArray *tmpArray = [NSMutableArray array];
        [allParameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [tmpArray addObject:[NSString stringWithFormat:@"%@=%@",[key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]],[obj stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]];
        }];
        
        [fullURLString appendString:[tmpArray componentsJoinedByString:@"&"]];
    }
    
    PAULog(PAUDATAPROVIDERLOGENABLED, @"[PAUDATAPROVIDER] Sending Request");
    PAULog(PAUDATAPROVIDERLOGENABLED, @" --> URL:%@", fullURLString);
    NSMutableURLRequest *tmpRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:fullURLString]];
    [tmpRequest setHTTPMethod:HTTPMethod];
    
    PAULog(PAUDATAPROVIDERLOGENABLED, @" --> Method:%@", HTTPMethod);
    
    if(body) {
        if(NO == isMediaSending) {
            PAULog(PAUDATAPROVIDERLOGENABLED, @" --> Body:%@", body);
            NSData *tmpData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
            if(tmpData) {
                [tmpRequest setHTTPBody:tmpData];
            }
        } else {
            NSData *tmpData = PAUPostMediaData(body[@"file_to_send"]);
            if(tmpData) {
                [tmpRequest setHTTPBody:tmpData];
                [tmpRequest addValue:[NSString stringWithFormat:@"%ld",(unsigned long)[tmpData length]] forHTTPHeaderField:@"Content-Length"];
            }
        }
    }
    
    PAUUser *meUser = (PAUUser *)[self.dataStore objectWithUUID:self.userUUID];
    if(0 != [meUser.authToken length]) {
        [tmpRequest addValue:meUser.uuid forHTTPHeaderField:@"http-auth-user"];
        [tmpRequest addValue:meUser.authToken forHTTPHeaderField:@"http-auth-pw"];
    }
    
    if(isMediaSending) {
        [tmpRequest addValue:@"multipart/form-data; boundary=----------------------------3869230abe44" forHTTPHeaderField:@"Content-Type"];
    }

        //by default we create a collection with the task UUID
    PAUHTTPTask *httpTask = [[PAUHTTPTask alloc] initWithPreparsingBlock:preparsingBlock completionBlock:completionBlock];
    PAULog(PAUDATAPROVIDERLOGENABLED, @" --> Task ID:%@", httpTask.uuid);
    PAUCollection *requestCollection = [[PAUCollection alloc] initWithDisplayIdentifier:httpTask.uuid];
    [self.dataStore addObject:requestCollection withLoadBehavior:kPAUStoreAdditionBehaviorDefault];
    
    NSURLSession *tmpSession = (YES == background) ? _backgroundSession: _foregroundSession;
    
    NSDate *startingDate = [NSDate date];
    httpTask.task = [tmpSession dataTaskWithRequest:tmpRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        PAULog(PAUDATAPROVIDERLOGENABLED, @"[PAUDATAPROVIDER] Receiving Request");
        if(response) {
            httpTask.statusCode = ((NSHTTPURLResponse *)response).statusCode;
        } else if(error){
            httpTask.statusCode = error.code;
        }
        PAULog(PAUDATAPROVIDERLOGENABLED, @" --> URL:%@", httpTask.task.originalRequest.URL.absoluteString);
        PAULog(PAUDATAPROVIDERLOGENABLED, @" --> Task:%@", httpTask.uuid);
        PAULog(PAUDATAPROVIDERLOGENABLED, @" --> StatusCode:%d", httpTask.statusCode);
//        PAULog(PAUDATAPROVIDERLOGENABLED, @" --> Raw Data:%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        id tmpJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves|NSJSONReadingMutableContainers error:nil];
        
            //maybe we could use simply dispatch queue
        [httpTask performSelectorOnMainThread:@selector(preparsingMainThreadMethod:) withObject:tmpJSON waitUntilDone:YES];
//        PAULog(PAUDATAPROVIDERLOGENABLED, @" --> Modified JSON:%@", tmpJSON);
        if(tmpJSON) {
            PAUObjectType tmpbjectTypes = kPAUObjectTypeNone;
            [PAUBaseObject createPAUObjectsFromJSONResult:tmpJSON parsedTypes:&tmpbjectTypes contextProvider:self contextTask:httpTask
                                   parsingCollectionBlock:nil];
            PAUCollection *tmpCollection = [self.dataStore collectionWithDisplayIdentifier:httpTask.uuid];
            __block NSString *messageUUID = nil;
            [[tmpCollection itemsInOrder:nil] enumerateObjectsUsingBlock:^(NSString *objectUUID, NSUInteger idx, BOOL *stop) {
                if([objectUUID hasPrefix:@"message_"]) {
                    messageUUID = objectUUID;
                    *stop = YES;
                }
            }];
        
//            PAUServerMessage *tmpMessage = (PAUServerMessage *)[self.dataStore objectWithUUID:messageUUID];
            [[PAULogger defaultLogger] logAtomWithData:
             @{kPAULogAtomTypeKey:kPAULogAtomTypeHTTPValue,
               kPAULogAtomStartDateKey:startingDate,
               kPAULogAtomMethodKey:HTTPMethod,
               kPAULogAtomEndPointKey:httpTask.task.originalRequest.URL.absoluteString,
               kPAULogAtomParametersKey:((nil!= body) ? body: @"--"),
               kPAULogAtomAppStateKey:@([UIApplication sharedApplication].applicationState),
               kPAULogAtomStatusKey:@(httpTask.statusCode),
               kPAULogAtomDurationKey:@([[NSDate date] timeIntervalSinceDate:startingDate]),
               kPAULogAtomServerDurationKey:@(0),
               kPAULogAtomServerMessageKey:@"FIXME"}
                forUUID:httpTask.uuid];
        }
        
        [httpTask performSelectorOnMainThread:@selector(completionMainThreadMethod) withObject:nil waitUntilDone:YES];

    }];

    [httpTask.task  resume];
    return httpTask.uuid;
}


/* Execution on main threa of preparsing block : first add UUID if neded */
- (void)_preparsingMainThreadMethod:(PAUHTTPTask *)task data:(id)JSONData
{
    if(task.httpPreparsingBlock) {
        task.httpPreparsingBlock(task, JSONData);
    }
}

/* Execution on main threa of completion block */
- (void)_completionMainThreadMethod:(PAUHTTPTask *)task
{
    if(task.httpCompletionBlock) {
       task.httpCompletionBlock(task);
    }
}

#pragma mark == URL SESSION DELEGATE ==
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    NSLog(@"%@",response);
//    NSLog(@"Dispostion %d", disposition);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    NSLog(@"%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    NSLog(@"%@", task.response);
}


@end
