/*
 *  PAUBaseObject.h
 *  Project : Pauser
 *
 *  Description : Every object (source, filter, collection, article) has 
 *  a base object with an UUID so one can manipulate object in the application
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2014/10/15
 *  Copyright (c) 2014 Symille. All rights reserved.
 *
 */

@import Foundation;

#import <sqlite3.h>

typedef enum {
    kPAUObjectTypeNone = 0x00000000,
    kPAUObjectTypeUser = 0x00000001,
    kPAUObjectTypeDevice = 0x00000002,
    kPAUObjectTypeError = 0x00000004,
    kPAUObjectTypeCollection = 0x00000008,
    kPAUObjectTypeServerMessage = 0x00000010,
    kPAUObjectTypeChallenge = 0x00000020,
} PAUObjectType;

typedef enum {
    kPAUObjectFlagNone = 0x00000000,
    
} PAUObjectFlags;


typedef void (^PAUParsingCollectionBlock)(NSString *rootObjectUUID, NSString *rootObjectProperty, NSArray *childrenFound);

@class  PAUDataProvider;
@class  PAUDataStore;
@class  PAUHTTPTask;


@interface PAUBaseObject : NSObject
{
    int _updateCount;
    NSMutableSet *_presentFields;
}

@property (nonatomic,strong) NSString *uuid;
@property (nonatomic,assign) PAUObjectType type;

/* Designated Initializer : if uuid is nil one will be generated */
- (id)initWithUUID:(NSString *)uuid;

/* To be subclassed but will not assert. Provide a UUID prefix so one can see what type of object is the uuid for. Please use FQDN based notation. Note that this will be used only when no UUID already exist */
+ (NSString *)uuidPrefix;

/* Will return the command to be executed when a storage DB needs to be created */
+ (char *)persistentSQLCreateStatement;

/* Will return the command to be executed,just after a storage DB created */
+ (char *)persistentSQLIndexStatement;

/* Will return the command to be executed to load all DAta */
+ (char *)loadAllSQLIndexStatement;

/* Class registration: to be called by subclasses */
+ (void) registerClass:(NSString *)className forType:(PAUObjectType)type JSONClassName:(NSString *)jsonClassName;

/* Class for a JSON api type (usually shorter) */
+ (NSString *)classNameForStringAPIType:(NSString *)stringAPIType;

/* Returns all class that can exists */
+ (NSArray *)objectClasseNames;

/* JSON type api for a class */
+ (NSString *)apiTypeFromClassName:(NSString *)className;

/* Class for a JSON api type (usually shorter) */
+ (NSString *)apiTypeForObjectType:(PAUObjectType)objectType;

/* Class for a JSON api type (usually shorter) */
+ (NSString *)classNameForObjectType:(PAUObjectType)objectType;


/* Entry point for JSON parsing and PAUObject instantiations */
+ (void) createPAUObjectsFromJSONResult:(id)jsonResult parsedTypes:(PAUObjectType *)parsedTypes contextProvider:(PAUDataProvider *)provider contextTask:(PAUHTTPTask*)task parsingCollectionBlock:(PAUParsingCollectionBlock)collectionBlock;

/* To be implemented by subclass */
- (id)initWithJSONContent:(id) JSONContent;

/* To be implemented by subclass */
- (void)updateWithJSONContent:(id) JSONContent;

/* Add one field */
- (void)addPresentField:(NSString *)field didUpdate:(BOOL *)updateStatus;

/* Retrieve present fields */
- (NSArray *)presentFields;

/* If we have a list of fields this method will return the list of fields that
 are really not here. Fields will be in the FQDN form e.g content.kind versus kind */
- (NSArray *)missingFieldsForDesiredFields:(NSSet *) desiredFields includeRelated:(BOOL)includeRelated;

/* Predefined fields set */
+ (NSArray *)fieldsForUsage:(NSString *) usageName;

/* Write to SQL Database */
- (BOOL)writeToDatabaseWithHandle:(sqlite3 *)dbHandle;

/* remove to SQL Database */
- (BOOL)removeFromDataBaseWithHandle:(sqlite3 *)dbHandle;

/* Create with init dictionary SQL Database */
- (id)initWithDatabaseInformation:(NSDictionary *)information provider:(PAUDataProvider *)provider dataStore:(PAUDataStore *)dataStore;

@end
