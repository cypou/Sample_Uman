/*
 *  PAUDataStore.h
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

#import "PAUBaseObject.h"

@class PAUDataProvider;
@class PAUBaseObject;
@class PAUCollection;
@class PAUUser;

typedef enum {
    kPAUStoreScopeNone = 0x00000000,
    kPAUStoreScopeMemory = 0x00000001,
    kPAUStoreScopeDisk = 0x00000002
} PAUStoreScope;

/* When we add something to the cache we can define where we add it */
typedef enum {
    kPAUStoreAdditionBehaviorDefault = 100,
    kPAUStoreAdditionBehaviorMemoryOnly = 101,
    kPAUStoreAdditionBehaviorForceDiskWrite = 102
} PAUStoreAdditionBehavior;


@interface PAUDataStore : NSObject
{
    NSMutableDictionary *_allObjects;
    NSMutableDictionary *_objectsForClass;
    
    NSString *_documentDataPath;
    NSMutableSet *_documentPersistentCollectionIdentifiers;
    
    NSString *_currentSQLEntity; //for data loading could be private. Really a convenience
}

@property (nonatomic, weak) PAUDataProvider *provider;
@property (nonatomic, strong) NSString *documentDataPath;
@property (nonatomic, strong) NSString *currentSQLEntity;

/* Returns all class that should be saved to the DB */
+ (NSArray *)serialiazibleSQLClassName;

/* Create a storage in the context of a provider */
- (id)initWithProvider:(PAUDataProvider *)provider;

/* Will retrieve an object from the data store */
- (PAUBaseObject *)objectWithUUID:(NSString *)objectUUID;

/* Will retrieve an object from the data store */
- (BOOL)containsObjectWithUUID:(NSString *)objectUUID inScope:(PAUStoreScope)scope;

/* Add an object with replace or not option */
- (void)addObject:(PAUBaseObject *)object withLoadBehavior:(PAUStoreAdditionBehavior)addBehavior;

/* Remove object */
- (void)removeObjectWithUUID:(NSString *)objectUUID;

/* Getting access to more than one object in one shot. Comparator is like array one. This returns UUIDs */
- (NSArray *) objectsForClass:(NSString *)className withComparator:(NSComparator)comparator;

/* Method to get collections : may return a subclass of it*/
- (PAUCollection *) collectionWithDisplayIdentifier:(NSString *)displayIdentifier;

/* Method to get user */
- (PAUUser *) userWithDescriptor:(NSDictionary *)descriptor;

/* To be called when the app moves to the back */
- (void)moveToBackground;

/* To be called when the app moves to the back */
- (void)moveToForeground;



@end
