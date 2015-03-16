/*
 *  PAUError.h
 *  Project : Pauser
 *
 *  Description : An error received on the WebIdea platorm
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2014/10/15
 *  Copyright (c) 2014 Symille. All rights reserved.
 *
 */

@import Foundation;

#import "PAUBaseObject.h"

extern NSString *const kPAUErrorDomain;
extern NSString *const kHTTPErrorDomain;

@interface PAUError : PAUBaseObject

@property (nonatomic, strong) NSString *domain;
@property (nonatomic, assign) NSInteger code;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *moreInfo;

/* Returns the NSError that can work */
- (NSError *)nativeError;
@end
