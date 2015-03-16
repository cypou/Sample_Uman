/*
 *  PAUDataStore.m
 *  Project : Pauser
 *
 *  Description : A data store stores all its elements with a UUID. At this point
 *  we do not talk about serialization (needed for offline reading and stuff like CoreData)
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2014/10/15
 *  Copyright (c) 2014 Symille. All rights reserved.
 *
 */

@import Foundation;

#import <objc/runtime.h>
#import <sqlite3.h>

#import "PAUBaseObject.h"
#import "PAUCollection.h"
#import "PAUDataStore.h"
#import "PAUDataProvider.h"
#import "PAUDataProviderManager.h"
#import "PAULogger.h"
#import "PAUUtilities.h"


#define PAUDATASTORELOG YES && PAUGLOBALLOGENABLED

enum{
    kPAUDataStoreSaveToNowhere = 0,
    kPAUDataStoreSaveToSQL = 2
};


@interface PAUDataStore()

/* grab cash content : top level method */
- (void)_loadDiskDocumentDataContent;

/* Add an object to cache */
- (BOOL)_flushObjectToDocumentData:(PAUBaseObject*)object;

/* Decide if an item goes into the cache */
- (int)_shouldAddObjectToDocumentData:(PAUBaseObject*)object;

/* Callback to receiv an SQL object */
- (void)_receiveObjectFromSQLStorage:(NSDictionary *)objectDescriptor;

@end

/* THe SQLLite store read callback */
static int sqlLiteCallback(void *objectReference, int argc, char **argv, char **azColName){
    int i;
    NSMutableDictionary *tmpObjectDescription = [NSMutableDictionary dictionary];
    for(i=0; i<argc; i++){
        if(@(argv[i])) {
            tmpObjectDescription[@(azColName[i])] = @(argv[i]);
        }
    }
    PAUDataStore *tmpStore = (__bridge PAUDataStore *) objectReference;
    [tmpStore _receiveObjectFromSQLStorage:tmpObjectDescription];
    return 0;
}



@implementation PAUDataStore

@synthesize provider = _provider;
@synthesize documentDataPath = _documentDataPath;

#pragma mark == LIFE CYCLE ==
/* Create a storage in the context of a provider */
- (id)initWithProvider:(PAUDataProvider *)provider
{
    self = [super init];
    if(self) {
        _allObjects = [[NSMutableDictionary alloc] init];
        _objectsForClass = [[NSMutableDictionary alloc] init];
        _documentPersistentCollectionIdentifiers = [[NSMutableSet alloc] init];
        self.provider = provider;
        [self addObserver:self forKeyPath:@"documentDataPath" options:NSKeyValueObservingOptionNew context:@"self_datastore"];
        if (![self.provider.userUUID isEqualToString:kPAUAnonymousUser] && ![self.provider.userUUID isEqualToString:kPAUTemporaryUser]) {
            
            NSString *tmpPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:[NSString stringWithFormat:@"data/%@",self.provider.userUUID]];
            PAUEnsureDirectoryAtPath(tmpPath);
            
            self.documentDataPath = tmpPath;
            PAUEnsurePersistentSQLDatabaseAtDirectory(self.documentDataPath, 1, [PAUDataStore serialiazibleSQLClassName]);
        }
    }
    return self;
}

/* Will return all classes that should be saved into a storage */
+ (NSArray *)serialiazibleSQLClassName
{
    return @[@"PAUUser", @"PAUDevice", @"PAUMedia", @"PAUMediaEmbed", @"PAULesson", @"PAUAuthor", @"PAUProgram"];
}

#pragma mark == STORE MANIPULATION ==
/* Will retrieve an object from the data store */
- (PAUBaseObject *)objectWithUUID:(NSString *)objectUUID
{
    PAUBaseObject *result = nil;
    if(nil != objectUUID) {
        result = _allObjects[objectUUID];
    }
    return result;
}

/* Will retrieve an object from the data store */
- (BOOL)containsObjectWithUUID:(NSString *)objectUUID inScope:(PAUStoreScope)scope
{
    __block BOOL result = NO;
    
    if (kPAUStoreScopeMemory == (scope & kPAUStoreScopeMemory)) {
        result = (nil != _allObjects[objectUUID]);
    }
    if (!result && (kPAUStoreScopeDisk == (scope & kPAUStoreScopeDisk))) {
        //Make a select
    }
    return result;
}




/* Add an object with replace or not option*/
- (void)addObject:(PAUBaseObject *)object withLoadBehavior:(PAUStoreAdditionBehavior)addBehavior
{
    @synchronized(self) {
        if(nil == object) return;
        if(nil == object.uuid) return;
        NSString *apiType = [PAUBaseObject apiTypeForObjectType:object.type];
        BOOL firstTime = YES;

        if (!_allObjects[object.uuid]) {
            _allObjects[object.uuid] = object;
            NSString *objectClass = NSStringFromClass([object class]);
            NSMutableSet *allObjectsForClass = [_objectsForClass objectForKey:objectClass];
            if(nil == allObjectsForClass) {
                allObjectsForClass = [NSMutableSet set];
                [_objectsForClass setObject:allObjectsForClass forKey:objectClass];
            }
            [allObjectsForClass addObject:object.uuid];
        }  else {
            firstTime = NO;
        }
        //Add it to the cache if necessary and update cache content if needed
        int shouldAddToDocumentData = kPAUDataStoreSaveToNowhere;
        
        switch (addBehavior) {
            case kPAUStoreAdditionBehaviorDefault: { shouldAddToDocumentData = [self _shouldAddObjectToDocumentData:object];break;}
            case kPAUStoreAdditionBehaviorMemoryOnly:{ shouldAddToDocumentData = kPAUDataStoreSaveToNowhere; break;}
            case kPAUStoreAdditionBehaviorForceDiskWrite:{ shouldAddToDocumentData = kPAUDataStoreSaveToSQL; break;}
            default: break;
        }

        if (kPAUDataStoreSaveToSQL == shouldAddToDocumentData) {
            NSString *persistentStoragePath = [self.documentDataPath stringByAppendingPathComponent:@"storage.sqllite"];
            sqlite3 *dbHandle;
            int dbResult =sqlite3_open([persistentStoragePath UTF8String], &dbHandle);
            if (SQLITE_OK != dbResult) {
                sqlite3_close(dbHandle);
            }
            BOOL tmpResult = [object writeToDatabaseWithHandle:dbHandle];
            if (NO == tmpResult) {
                PAULog(PAUDATASTORELOG, @" --> Error un writing object %@ to DB", object);
            }
            sqlite3_close(dbHandle);
        }

        NSString *postAdditionSelectorName = [NSString stringWithFormat:@"_%@PostAdditionProcessing:firstTime:", apiType];
        if ([self respondsToSelector:NSSelectorFromString(postAdditionSelectorName)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:NSSelectorFromString(postAdditionSelectorName) withObject:object withObject:@(firstTime)];
#pragma clang diagnostic pop
        }

    }
}

/* Remove object */
- (void)removeObjectWithUUID:(NSString *)objectUUID
{
    if(nil == objectUUID) return;
    PAUBaseObject *tmpObj = [_allObjects objectForKey:objectUUID];
    if(nil == tmpObj) return;
    
    [[_objectsForClass objectForKey:NSStringFromClass([tmpObj class])] removeObject:objectUUID];
    [_allObjects removeObjectForKey:objectUUID];    
}

/* Getting access to more than one object in one shot. Comparator not used for now. This returns UUIDs */
- (NSArray *) objectsForClass:(NSString *)className withComparator:(NSComparator)comparator
{
    if(nil == comparator) {
        return ([_objectsForClass[className] allObjects]);
    } else {
        NSArray *tmpArray = [_objectsForClass[className] allObjects];
        return ([tmpArray sortedArrayUsingComparator:comparator]);
    }
}

/* Class method to get collections : may return a subclass of it*/
/* FIXME this does not work with more than ne level of subclass */
- (PAUCollection *) collectionWithDisplayIdentifier:(NSString *)displayIdentifier
{
    __block PAUCollection *result  = nil;
    [[PAUBaseObject objectClasseNames] enumerateObjectsUsingBlock:^(NSString *className, NSUInteger idx, BOOL *stopIdx) {
        
        if([className isEqualToString:@"PAUCollection"] || [NSStringFromClass(class_getSuperclass(NSClassFromString(className))) isEqualToString:@"PAUCollection"]) {
            __block BOOL shouldStop = NO;
            [[_objectsForClass[className] allObjects] enumerateObjectsUsingBlock:^(NSString *objUUID, NSUInteger jdx, BOOL *stopJdx) {
                if([((PAUCollection *)_allObjects[objUUID]).displayIdentifier isEqualToString:displayIdentifier]) {
                    result = _allObjects[objUUID];
                    *stopJdx = YES;
                    shouldStop = YES;
                }
            }];
            *stopIdx = shouldStop;
        }
    }];
    return result;
}


/*  Used to assign the ID of a user after registration */
- (PAUUser *) userWithDescriptor:(NSDictionary *)descriptor
{
    PAUUser *result = nil;
    return result;
}

#pragma mark == KEY/VALUE OBSERVER ==
/* KVO main method */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"documentDataPath"]) {
        PAULog(PAUDATASTORELOG, @"[PAUDATASTORE] cache path value is set, let's load storage");
        [self _loadDiskDocumentDataContent];
        
        @try {
            [self removeObserver:self forKeyPath:@"documentDataPath" context:@"self_datastore"];
        }
        @catch (NSException *exception) {}
    } else if ([keyPath isEqualToString:@"items"] && [object isKindOfClass:[PAUCollection class]]) {
        if ([_documentPersistentCollectionIdentifiers containsObject:[(PAUCollection *)object displayIdentifier]]) {
            [self _flushObjectToDocumentData:object];
        }
        
    }
}


#pragma mark == ON DISK BEHAVIOR ==
/* grab cash content */
- (void) _loadDiskDocumentDataContent
{
    PAULog(PAUDATASTORELOG, @"[PAUDataStore] Cache data loading");
    
    NSString *cacheStoragePath = [self.documentDataPath stringByAppendingPathComponent:@"storage.sqllite"];
    PAUEnsurePersistentSQLDatabaseAtDirectory(self.documentDataPath, 1, [PAUDataStore serialiazibleSQLClassName]);
    sqlite3 *dbHandle;
    int dbResult =sqlite3_open([cacheStoragePath UTF8String], &dbHandle);
    if (SQLITE_OK != dbResult) {
        sqlite3_close(dbHandle);
        dbHandle = NULL;
    }
    if (!dbHandle) return;
    
    [[PAUDataStore serialiazibleSQLClassName] enumerateObjectsUsingBlock:^(NSString *className, NSUInteger idx, BOOL *stop) {
        char *sqlStatement = [NSClassFromString(className) loadAllSQLIndexStatement];
        self.currentSQLEntity = className;
        char *errMessage = nil;
        int dbResult = sqlite3_exec(dbHandle, sqlStatement, sqlLiteCallback, (__bridge void *)(self), &errMessage);
        if (SQLITE_OK != dbResult){
            NSLog(@"[ERROR] PAUDataStore database error %s", errMessage);
            sqlite3_free(errMessage);
            char *sqlStatement = [NSClassFromString(className) persistentSQLCreateStatement];
            dbResult = sqlite3_exec(dbHandle, sqlStatement, NULL, 0, &errMessage);
            if (SQLITE_OK != dbResult){
                NSLog(@"[ERROR] PAUDataStore database error %s", errMessage);
                sqlite3_free(errMessage);
            }
        }
    }];
    
    sqlite3_close(dbHandle);
    
}

/* Decide if an item goes into the persistent storage */
- (int)_shouldAddObjectToDocumentData:(PAUBaseObject *)object
{
    int result = kPAUDataStoreSaveToNowhere;
    switch (object.type) {
        case kPAUObjectTypeCollection:
        {
            PAUCollection *tmpCollection = (PAUCollection *)object;
            result = [_documentPersistentCollectionIdentifiers containsObject:tmpCollection.displayIdentifier] ? kPAUDataStoreSaveToSQL :kPAUDataStoreSaveToNowhere;
            break;
        }
        case kPAUObjectTypeUser:
            result = (NO == [object.uuid isEqualToString:kPAUTemporaryUser]);
            break;
        case kPAUObjectTypeDevice:
        case kPAUObjectTypeChallenge:
            result = kPAUDataStoreSaveToSQL;
            break;
        default:
            result = kPAUDataStoreSaveToNowhere;
            break;
    }
    return result;
}

/* Used at database loading time */
- (void)_receiveObjectFromSQLStorage:(NSDictionary *)objectDescriptor
{
    PAUBaseObject *tmpObject = [[NSClassFromString(self.currentSQLEntity) alloc] initWithDatabaseInformation:objectDescriptor provider:self.provider dataStore:self];
    [self addObject:tmpObject withLoadBehavior:kPAUStoreAdditionBehaviorMemoryOnly];
    if ([tmpObject isKindOfClass:[PAUCollection class]]) {
//        NSString *displayIdentifier = [tmpObject performSelector:@selector(displayIdentifier)];
//        if ([displayIdentifier hasPrefix:@"/account/filters.json?user_credentials"]) {
//            [_documentPersistentCollectionIdentifiers addObject:displayIdentifier];
    }
}

/* Add an object to cache */
- (BOOL)_flushObjectToDocumentData:(PAUBaseObject*)object
{
    BOOL result = NO;
    int shouldAdd = [self _shouldAddObjectToDocumentData:object];
    
    if (kPAUDataStoreSaveToSQL == shouldAdd) {
        NSString *storagePath = [self.documentDataPath stringByAppendingPathComponent:@"storage.sqllite"];
        sqlite3 *dbHandle;
        int dbResult =sqlite3_open([storagePath UTF8String], &dbHandle);
        if (SQLITE_OK != dbResult) {
            sqlite3_close(dbHandle);
        }
        result = [object writeToDatabaseWithHandle:dbHandle];
        if (!result) {
            PAULog(PAUDATASTORELOG, @" --> Adding %@ with result to cache %d", object, result);
        }
        sqlite3_close(dbHandle);
    }
    return result;
}


#pragma mark == APPLICATION LIFE CYCLE ==

/* To be called when the app moves to the back */
- (void)moveToBackground
{
    
}

/* To be called when the app moves to the back */
- (void)moveToForeground
{
    
}


@end
