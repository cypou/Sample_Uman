/*
 *  PAUHTTPTask.m
 *  Project : Pauser
 *
 *  Description : a PAU data HTTP Task is a task for communicationw with the server
 *  It is fully integrated with NSURLSession
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2014/10/15
 *  Copyright (c) 2014 Symille. All rights reserved.
 *
 */

@import Foundation;

#import "PAUBaseObject.h"
#import "PAUHTTPTask.h"
#import "PAULogger.h"

#define PAUAPPHTTPTASKLOG YES && PAUGLOBALLOGENABLED


/* Simple helper that will help restorng UUIDs */
static void fixUUIDForDictionary(NSMutableDictionary *missingUUIDDictionary);

static void fixUUIDForDictionary(NSMutableDictionary *missingUUIDDictionary)
{
    if([missingUUIDDictionary isKindOfClass:[NSDictionary class]]) {
        NSString *objectUUID = missingUUIDDictionary[@"uuid"];
        NSString *className = missingUUIDDictionary[@"__class_name"];
        if(((nil == objectUUID) || ([objectUUID isKindOfClass:[NSNull class]])) && (nil != className)) {
            NSString *newUUID = [NSString stringWithFormat:@"%@_%@",
                                 [NSClassFromString([PAUBaseObject classNameForStringAPIType:className]) uuidPrefix], ((NSUUID *)[NSUUID UUID]).UUIDString];
            missingUUIDDictionary[@"uuid"] = newUUID;
        }
        
        [missingUUIDDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
            if([obj isKindOfClass:[NSDictionary class]]) {
                fixUUIDForDictionary((NSMutableDictionary *)obj);
            }
        }];
    }
}



@implementation PAUHTTPTask

@synthesize httpPreparsingBlock = _httpPreparsingBlock;
@synthesize httpCompletionBlock = _httpCompletionBlock;
@synthesize task = _task;
@synthesize statusCode = _statusCode;
//@dynamic uniqueEndPath;

/* Designated initializer : store all blocks and assign a UUID */
-(id) initWithPreparsingBlock:(PAUPreparseBlock)preparsingBlock completionBlock:(PAUCompletionBlock)completionBlock
{
    self = [super init];
    if(self) {
        self.httpCompletionBlock = completionBlock;
        self.httpPreparsingBlock = preparsingBlock;
        self.uuid = [NSString stringWithFormat:@"task:%@", [[NSUUID UUID] UUIDString]];
    }
    return self;
}

/* Execution on main thread of preparsing block : first add UUID to objects if needed */
- (void)preparsingMainThreadMethod:(id)JSONData
{    
    fixUUIDForDictionary(JSONData);
    if(self.httpPreparsingBlock) {
        self.httpPreparsingBlock(self, JSONData);
    }
}

/* Execution on main thread of completion block */
- (void)completionMainThreadMethod
{
    if(self.httpCompletionBlock) {
        self.httpCompletionBlock(self);
    }
}


@end
