/*
 *  PAUChallenge.m
 *  Project : Pauser
 *
 *  Description : A media on the Petit Bambou platorm
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2014/06/21
 *  Copyright (c) 2014 Symille. All rights reserved.
 *
 */

@import Foundation;

#import "PAUChallenge.h"


@implementation PAUChallenge

#pragma mark == LIFE CYCLE ==
/* Register towards to the base class */
+ (void)load
{
    [PAUBaseObject registerClass:NSStringFromClass([self class]) forType:kPAUObjectTypeChallenge JSONClassName:@"challenge"];
}

/* Prefix for when compensating UUID */
+ (NSString *)uuidPrefix
{
    return @"challenge";
}

#pragma mark == SQL SERIALIZATION == 
/* Will return the comment to be executed when a storage DB needs to be created */
+ (char *)persistentSQLCreateStatement
{
    char *sqlStatement = "CREATE TABLE IF NOT EXISTS CHALLENGE("  \
    "UUID TEXT PRIMARY KEY     NOT NULL," \
    "TITLE         TEXT    NOT NULL," \
    "DESCRIPTION         TEXT    NOT NULL," \
    "INVITEES         TEXT    NOT NULL);";
    return sqlStatement;
}


/* Will return the comment to be executed when a just after a storage DB created */
+ (char *)persistentSQLIndexStatement
{
    char *sqlStatement = "CREATE UNIQUE INDEX media_idx ON CHALLENGE(UUID);";
    return sqlStatement;
}

+ (char *)loadAllSQLIndexStatement
{
    return "SELECT * FROM CHALLENGE";
}


/* Write to SQL Database */
- (BOOL)writeToDatabaseWithHandle:(sqlite3 *)dbHandle
{
    BOOL result = NO;
    if (!dbHandle) return result;
    
    char * sqlStatement  = sqlite3_mprintf("INSERT OR REPLACE INTO CHALLENGE (UUID, TITLE, DESCRIPTION, INVITEES) values ( '%q', '%q', '%q', '%q');",
                                           [self.uuid UTF8String],
                                           [self.title length] ? [self.title UTF8String] : "--",
                                           [self.description length]? [self.description UTF8String]: "--",
                                           [self.inviteesUUIDs count]? [[self.inviteesUUIDs componentsJoinedByString:@","] UTF8String]: "--");
    
    char *errMessage = NULL;
    int dbResult = sqlite3_exec(dbHandle, sqlStatement, nil, 0, &errMessage);
    if (SQLITE_OK != dbResult){
        NSLog(@"[ERROR] PAUChallenge save to database %s", errMessage);
        sqlite3_free(errMessage);
    } else {
        result = YES;
    }
    
    return result;
    
}

/* remove to SQL Database */
- (BOOL)removeFromDataBaseWithHandle:(sqlite3 *)dbHandle
{
    BOOL result = NO;
    char *errBlockMessage = nil;
    char *sqlBlockStatement = sqlite3_mprintf("DELETE FROM MEDIA WHERE UUID IS '%q';",[self.uuid UTF8String]);
    int dbBlockResult = sqlite3_exec(dbHandle, sqlBlockStatement, NULL , NULL, &errBlockMessage);
    if ( SQLITE_OK != dbBlockResult){
        sqlite3_free(errBlockMessage);
    } else {
        result = YES;
    }
    
    return result;
}


/* Create with init dictionary SQL Database */
- (id)initWithDatabaseInformation:(NSDictionary *)information provider:(PAUDataProvider *)provider dataStore:(PAUDataStore *)dataStore
{
    self = [super initWithUUID:information[@"UUID"]];

    
    
    return self;
    
}



#pragma mark == JSON SERIALIZATION ==
- (id) initWithUUID:(NSString *)uuid
{
    self = [super initWithUUID:uuid];
    self.inviteesUUIDs = [NSMutableArray array];
    
    return self;
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
    
    tmpObj = JSONContent[@"title"];
    if(tmpObj && [tmpObj isKindOfClass:[NSString class]]) {
        self.title = tmpObj;
    }

    tmpObj = JSONContent[@"description"];
    if(tmpObj && [tmpObj isKindOfClass:[NSString class]]) {
        self.challengeDescription = tmpObj;
    }


}



@end
