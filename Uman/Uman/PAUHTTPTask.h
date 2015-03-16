/*
 *  PAUHTTPTask.h
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

#import "PAUDataProvider.h"
#import "PAUCollection.h"

@interface PAUHTTPTask : NSObject
{
    PAUPreparseBlock _httpPreparsingBlock;
    PAUCompletionBlock _httpCompletionBlock;
    NSURLSessionDataTask *_task;
    NSString *_uuid;
    NSUInteger _statusCode;
}

@property (nonatomic, copy) PAUPreparseBlock httpPreparsingBlock;
@property (nonatomic, copy) PAUCompletionBlock httpCompletionBlock;
@property (nonatomic, retain) NSURLSessionDataTask *task;
//@property (nonatomic, retain, readonly) NSString *uniqueEndPath; //this is the path minus offset, limit or (if it comes) fields and parameters sorted in alphabetical order
@property (nonatomic, retain) NSString *uuid;
@property (nonatomic, assign) NSUInteger statusCode;

/* Designated initializer */
-(id) initWithPreparsingBlock:(PAUPreparseBlock)preparsingnBlock completionBlock:(PAUCompletionBlock)completionBlock;

/* Execution on main threa of preparsing block */
- (void)preparsingMainThreadMethod:(id)JSONData;

/* Execution on main threa of completion block */
- (void)completionMainThreadMethod;




@end
