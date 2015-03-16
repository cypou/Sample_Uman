/*
 *  PAUError.m
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
#import "PAUError.h"

NSString *const kPAUErrorDomain = @"PAUErrorDomain";
NSString *const kHTTPErrorDomain = @"HTTPErrorDomain";

@implementation PAUError

@synthesize domain = _domain;
@synthesize code = _code;
@synthesize message= _message;
@synthesize moreInfo = _moreInfo;

#pragma mark == LIFE CYCLE ==
/* Register towards to the base class */
+ (void)load
{
    [PAUBaseObject registerClass:NSStringFromClass([self class]) forType:kPAUObjectTypeError JSONClassName:@"error"];
}

/* Prefix for when compensating UUID */
+ (NSString *)uuidPrefix
{
    return @"error";
}

/* JSON object initialization : first time */
- (id)initWithJSONContent:(NSDictionary *)contentObject
{
    assert(nil != contentObject[@"uuid"]);
    self = [super initWithUUID:contentObject[@"uuid"]];
	if (self != nil) {
		[self updateWithJSONContent:contentObject];
    }
	return self;
}

/* this will efeectively fill the data */
- (void)updateWithJSONContent:(id) JSONContent
{
    id tmpObj = nil;
    
    [super updateWithJSONContent:JSONContent];
    
    tmpObj = [JSONContent objectForKey:@"code"];
    if(tmpObj && ([tmpObj isKindOfClass:[NSString class]] ||[tmpObj isKindOfClass:[NSNumber class]])) {
        self.code = [tmpObj integerValue];
    }
    
    tmpObj = [JSONContent objectForKey:@"status"];
    if(tmpObj && ([tmpObj isKindOfClass:[NSString class]] ||[tmpObj isKindOfClass:[NSNumber class]])) {
        NSInteger tmpStatus = [tmpObj integerValue];
        if(tmpStatus < 600 && (tmpStatus!= 400)) { //400 is too generic and comes with a complement
            self.domain = kHTTPErrorDomain;
            self.code = tmpStatus;
        } else if(400 == tmpStatus) {
            self.domain = kPAUErrorDomain;
            self.code = [JSONContent[@"code"] intValue];
        } else {
            self.domain = kPAUErrorDomain;
            self.code = tmpStatus;
        }
    }
    
    tmpObj = [JSONContent objectForKey:@"more_info"];
    if(tmpObj && [tmpObj isKindOfClass:[NSString class]]) {
        self.moreInfo = tmpObj;
    }

    tmpObj = [JSONContent objectForKey:@"message"];
    if(tmpObj && [tmpObj isKindOfClass:[NSString class]]) {
        self.message = tmpObj;
    }

}

/* Synthetize an NSError from a error */
- (NSError *)nativeError
{
    return [NSError errorWithDomain:self.domain code:self.code userInfo:@{NSLocalizedDescriptionKey:self.message, NSLocalizedFailureReasonErrorKey:self.moreInfo}];
}

@end
