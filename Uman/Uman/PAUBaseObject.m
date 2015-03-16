/*
 *  PAUBaseObject.m
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

#import "PAUBaseObject.h"
#import "PAUCollection.h"
#import "PAUDataProvider.h"
#import "PAUDataStore.h"
#import "PAUHTTPTask.h"
#import "PAUUtilities.h"

#define PAUBASEOBJECTLOG YES && PAUGLOBALLOGENABLED

/* Help function  : transform a Cocoa object JSON inspired representation into a real object. createdObjects must be preallocated*/
PAUObjectType _ParseAPIObjectWithExecutionBlock(id inputObj, PAUDataProvider *provider,  PAUHTTPTask *task, PAUParsingCollectionBlock block, NSString *parentUUID, NSString *parentKey) {
    __block PAUObjectType result = kPAUObjectTypeNone;
    
    if([inputObj isKindOfClass:[NSArray class]]) {
        NSArray *tmpArray = (NSArray *)inputObj;
        NSMutableArray *uuidArray = [NSMutableArray array];
        [tmpArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            if([obj isKindOfClass:[NSDictionary class]] && obj[@"uuid"]) {
                [uuidArray addObject:obj[@"uuid"]];
            }
        }];
        if([uuidArray count] && block) {
            block(parentUUID, parentKey, uuidArray);
        }
        [tmpArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            PAUObjectType tmpObjectType = _ParseAPIObjectWithExecutionBlock(obj, provider, task, block, parentUUID, parentKey);
            result |= tmpObjectType;
        }];
        
            //add them to the endpoint collection if we have received
        if(nil == parentUUID || [parentUUID hasPrefix:@"dictionnary"]) {
            NSString *uniqueEndPath = PAUEndPointUniqueEndPath(task.task.originalRequest.URL.absoluteString);
            PAUCollection *endPointCollection = [provider.dataStore collectionWithDisplayIdentifier:uniqueEndPath];
            if(nil == endPointCollection) {
                endPointCollection = [[PAUCollection alloc] initWithDisplayIdentifier:uniqueEndPath];
                [provider.dataStore addObject:endPointCollection withLoadBehavior:kPAUStoreAdditionBehaviorDefault];

           }
            NSUInteger startPoint = [[endPointCollection itemsInOrder:nil] count];
            [endPointCollection addItems:uuidArray forRange:NSMakeRange(startPoint, [uuidArray count]) inOrder:nil withReplaceAll:NO];
        }
    } else if([inputObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *tmpDictionary = (NSDictionary *)inputObj;
        NSString *objectAPIType = tmpDictionary[@"__class_name"];
        NSString *objectUUID = tmpDictionary[@"uuid"] ;

        if(objectUUID && (NO == [objectAPIType isEqualToString:@"dictionnary"])) {
            PAUBaseObject *tmpObject = [provider.dataStore objectWithUUID :objectUUID];
            if(tmpObject) {
                [tmpObject updateWithJSONContent:tmpDictionary];
                result |= tmpObject.type;
            } else {
                if(nil == objectAPIType) return result;
                NSString *objectClass = [PAUBaseObject classNameForStringAPIType:objectAPIType];
                if(nil == objectClass) return result;
                tmpObject = [[NSClassFromString(objectClass) alloc] initWithJSONContent:tmpDictionary];
                result |= tmpObject.type;
                [provider.dataStore addObject:tmpObject withLoadBehavior:kPAUStoreAdditionBehaviorDefault];
            }
            [[provider.dataStore collectionWithDisplayIdentifier:task.uuid] addItems:@[tmpObject.uuid] forRange:NSMakeRange(0, 1) inOrder:nil withReplaceAll:NO];
            
            [tmpDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if([obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDictionary class]]) {
                    PAUObjectType tmpObjectType = _ParseAPIObjectWithExecutionBlock(obj,provider, task, block, objectUUID, key); //we keep only object at the first level here
                    result |= tmpObjectType;
                }
            }];
        } else {
                //gather the model oriented data
            if([tmpDictionary objectForKey:@"data"]){
                _ParseAPIObjectWithExecutionBlock([tmpDictionary objectForKey:@"data"],provider, task, block, objectUUID, nil);
            }
                //gather the server measurement part            
            if([tmpDictionary objectForKey:@"server"]){
                _ParseAPIObjectWithExecutionBlock([tmpDictionary objectForKey:@"server"],provider, task, block, objectUUID, nil);
            }
            
            if([tmpDictionary objectForKey:@"data_set"]){
                _ParseAPIObjectWithExecutionBlock([tmpDictionary objectForKey:@"data_set"],provider, task, block, objectUUID, nil);
            }
        }
    }
    return result;
}




/* This will maintain all class information */
static NSMutableDictionary *_allObjectClasses = nil;
static NSMutableDictionary *_jsonClassToObjectClass = nil;

@implementation PAUBaseObject

@synthesize uuid = _uuid;
@synthesize type = _type;

#pragma mark == LIFE CYCLE ==
/* Designated initializer : if uuid is nil one will be generated */
- (id)initWithUUID:(NSString *)uuid
{
    self = [super init];
    if(self) {
        NSString *tmpClassString = NSStringFromClass([self class]);
        //set up the UUID or create one if not present
        if((nil == uuid) || (0 == [uuid length])) {
            self.uuid = [NSString stringWithFormat:@"%@:%@", [[self class] uuidPrefix], [[NSUUID UUID] UUIDString]];
        } else {
            self.uuid = uuid;
        }
        self.type = [_allObjectClasses[tmpClassString] unsignedShortValue];
    }
    return self;
}

/* Not per se a life cycle but around the idea of subclassing */
- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@:%p - %@>", NSStringFromClass(self.class), self, self.uuid];
}
#pragma mark == CLASS METHOD FOR SUBCLASS ==
/* To be subclassed but will not assert. Provide a UUID prefix so one can see what type of object is the uuid for. Please use FQDN based notation */
+ (NSString *)uuidPrefix
{
    return @"PAU.baseobject";
}

/* Class registration: to be called by subclasses */
+ (void) registerClass:(NSString *)className forType:(PAUObjectType)type JSONClassName:(NSString *)jsonClassName
{
    if(nil == _allObjectClasses) _allObjectClasses = [[NSMutableDictionary alloc] init];
    if(nil == _jsonClassToObjectClass) _jsonClassToObjectClass = [[NSMutableDictionary alloc] init];

    @autoreleasepool {
        [_allObjectClasses setObject:[NSNumber numberWithUnsignedInteger:type] forKey:className];
        [_jsonClassToObjectClass setObject:className forKey:jsonClassName];
    }
}


/* Class for a JSON api type (usually shorter) */
+ (NSString *)classNameForStringAPIType:(NSString *) stringAPIType
{
    return _jsonClassToObjectClass[stringAPIType];
}

/* JSON type api for a class */
+ (NSString *)apiTypeFromClassName:(NSString *)className
{
    return [_jsonClassToObjectClass allKeysForObject:className][0];
}

/* Class for a JSON api type (usually shorter) */
+ (NSString *)apiTypeForObjectType:(PAUObjectType)objectType
{
    return [self apiTypeFromClassName:[_allObjectClasses allKeysForObject:@(objectType)][0]];
}

/* Class for a JSON api type (usually shorter) */
+ (NSString *)classNameForObjectType:(PAUObjectType)objectType
{
    return ([_allObjectClasses allKeysForObject:@(objectType)][0]);
}


/* Returns all class that can exists */
+ (NSArray *)objectClasseNames
{
    return [_allObjectClasses allKeys];
}


#pragma mark == DATA CREATION FROM PARSING ==
/* Entry point for JSON parsing and PAUObject instantiations */
+ (void) createPAUObjectsFromJSONResult:(id)jsonResult parsedTypes:(PAUObjectType *)parsedTypes contextProvider:(PAUDataProvider *)provider contextTask:(PAUHTTPTask*)task parsingCollectionBlock:(PAUParsingCollectionBlock)collectionBlock
{
    PAUObjectType allParsedType = _ParseAPIObjectWithExecutionBlock(jsonResult, provider, task, collectionBlock, nil, nil);
    if(parsedTypes)
        *parsedTypes = allParsedType;
    return ;
}

/* To be implemented by subclass */
- (id)initWithJSONContent:(id) JSONContent
{
    assert(nil != JSONContent[@"uuid"]);
    self = [self initWithUUID:JSONContent[@"uuid"]];
	if (self != nil) {
		[self updateWithJSONContent:JSONContent];
    }
	return self;
}

/* Mainly to be implemented by subclass : base version counts the time it has been updated */
- (void)updateWithJSONContent:(id) JSONContent
{
    _updateCount++;
}


/* Predefined fields set */
+ (NSArray *)fieldsForUsage:(NSString *) usageName
{
    return [NSArray array];
}


/* Add one field */
- (void)addPresentField:(NSString *)field didUpdate:(BOOL *)updateStatus
{
    if(nil == field || 0 == [field length]) return;
    NSUInteger beforeCount = [_presentFields count];
    [_presentFields addObject:field];
    NSUInteger afterCount =  [_presentFields count];
    if (updateStatus) {
        *updateStatus = (beforeCount != afterCount);
    }
}


/* Add a serie of fields */
- (NSArray *)presentFields
{
    return [_presentFields allObjects];
}

/* If we have a list of fields this method will return the list of fields that
 are reall not here */
- (NSArray *)missingFieldsForDesiredFields:(NSSet *) desiredFields includeRelated:(BOOL)includeRelated
{
    NSMutableSet *tmpSet = [NSMutableSet setWithSet:desiredFields];
    NSMutableSet *presentFields = [NSMutableSet setWithSet:_presentFields];
    [tmpSet minusSet:presentFields];
    
    if(0!= [tmpSet count]) {
        [tmpSet addObject:@"uuid"];
    }
    return ([tmpSet allObjects]);
}

#pragma mark == SQL LITE SUPPORT ==
/* Will return the command to be executed when a storage DB needs to be created */
+ (char *)persistentSQLCreateStatement
{
    return NULL;
}

/* Will return the command to be executed,just after a storage DB created */
+ (char *)persistentSQLIndexStatement
{
    return NULL;
}

/* Will return the command to be executed to load all DAta */
+ (char *)loadAllSQLIndexStatement
{
    return NULL;    
}

/* Write to SQL Database */
- (BOOL)writeToDatabaseWithHandle:(sqlite3 *)dbHandle
{
    return NO;
}

/* remove to SQL Database */
- (BOOL)removeFromDataBaseWithHandle:(sqlite3 *)dbHandle
{
    return NO;
}

/* Create with init dictionary SQL Database */
- (id)initWithDatabaseInformation:(NSDictionary *)information provider:(PAUDataProvider *)provider dataStore:(PAUDataStore *)dataStore
{
    return [self initWithUUID:nil];
}



@end
