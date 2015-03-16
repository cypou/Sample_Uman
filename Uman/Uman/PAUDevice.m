/*
 *  PAUDevice.m
 *  Project : Pauser
 *
 *  Description : A user device
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2013/10/08
 *  Copyright (c) 2014 Symille. All rights reserved.
 *
 */

@import Foundation;

#import "PAUBaseObject.h"
#import "PAUDevice.h"

#define PAUDEVICELOG YES && PAUGLOBALLOGENABLED

@implementation PAUDevice

#pragma mark == LIFE CYCLE ==
/* Register towards to the base class */
+ (void)load
{
    [PAUBaseObject registerClass:NSStringFromClass([self class]) forType:kPAUObjectTypeDevice JSONClassName:@"Device"];
    [PAUBaseObject registerClass:NSStringFromClass([self class]) forType:kPAUObjectTypeDevice JSONClassName:@"device"];
    
}

/* Prefix for when compensating UUID */
+ (NSString *)uuidPrefix
{
    return @"device";
}

#pragma mark == SQL SERIALIZATION ==
/* Will return the comment to be executed when a storage DB needs to be created */
+ (char *)persistentSQLCreateStatement
{
    char *sqlStatement = "CREATE TABLE IF NOT EXISTS  DEVICE("  \
    "UUID TEXT PRIMARY KEY     NOT NULL," \
    "UDID         TEXT    NOT NULL," \
    "USER_UUID      TEXT    NOT NULL," \
    "OPERATING_SYSTEM     TEXT     NOT NULL," \
    "DEVICE_TYPE     TEXT     NOT NULL," \
    "PHONE_NUMBER      TEXT     NOT NULL," \
    "APPLE_TOKEN     TEXT     NOT NULL," \
    "ANDROID_TOKEN     TEXT     NOT NULL," \
    "BUILD_VERSION    INTEGER     NOT NULL);";
    return sqlStatement;
}

/* Will return the comment to be executed when a just after a storage DB created */
+ (char *)persistentSQLIndexStatement
{
    char *sqlStatement = "CREATE UNIQUE INDEX device_idx ON DEVICE(UUID);";
    return sqlStatement;
}

/* Called when the data is loaded from disk */
+ (char *)loadAllSQLIndexStatement
{
    return "SELECT * FROM DEVICE";
    
}

/* Write to SQL Database */
- (BOOL)writeToDatabaseWithHandle:(sqlite3 *)dbHandle
{
    BOOL result = NO;
    if (!dbHandle) return result;
    
    char * sqlStatement  = sqlite3_mprintf("INSERT OR REPLACE INTO DEVICE (UUID, UDID, USER_UUID, OPERATING_SYSTEM, DEVICE_TYPE, PHONE_NUMBER, ANDROID_TOKEN, BUILD_VERSION ) values ( '%q', '%q', '%q', '%q', '%q', '%q', '%q', '%d');",
                                           [self.uuid UTF8String],
                                           [self.udid length] ? [self.udid UTF8String] : "--",
                                           [self.userUUID length]? [self.userUUID UTF8String]: "--",
                                           [self.deviceType length]? [self.deviceType UTF8String]: "--",
                                           [self.phoneNumber length]? [self.phoneNumber UTF8String]: "--",
                                           [self.appleToken length]? [self.appleToken UTF8String]: "--",
                                           [self.androidToken length]? [self.androidToken UTF8String]: "--",
                                           self.buildVersion);
    
    char *errMessage = NULL;
    int dbResult = sqlite3_exec(dbHandle, sqlStatement, nil, 0, &errMessage);
    if (SQLITE_OK != dbResult){
        NSLog(@"[ERROR] PAUDevice save to database %s", errMessage);
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
    char *sqlBlockStatement = sqlite3_mprintf("DELETE FROM DEVICE WHERE UUID IS '%q';",[self.uuid UTF8String]);
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
    

    NSString *tmpString = information[@"UDID"];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { self.udid = tmpString; }
    
    tmpString = information[@"USER_UUID"];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { self.userUUID = tmpString; }
    
    tmpString = information[@"OPERATING_SYSTEM"];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { self.operatingSystem = tmpString ; }
    
    tmpString = information[@"DEVICE_TYPE"];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { self.deviceType= tmpString; }

    tmpString = information[@"PHONE_NUMBER"];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { self.phoneNumber= tmpString; }

    tmpString = information[@"APPLE_TOKEN"];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { self.appleToken= tmpString; }

    tmpString = information[@"ANDROID_TOKEN"];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { self.androidToken= tmpString; }

    tmpString = information[@"BUILD_VERSION"];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { self.buildVersion= [tmpString intValue]; }
    
    return self;
    
}


#pragma mark == JSON SERIALIZATION ==
/* this will efeectively fill the data */
- (void)updateWithJSONContent:(id) JSONContent
{
    id tmpObj = nil;
    
    [super updateWithJSONContent:JSONContent];
    
    tmpObj = JSONContent[@"os"];
    if(tmpObj && [tmpObj isKindOfClass:[NSString class]]) {
        self.operatingSystem = tmpObj;
    }
    
    tmpObj = JSONContent[@"device_type"];
    if(tmpObj && [tmpObj isKindOfClass:[NSString class]]) {
        self.deviceType = tmpObj;
    }
    
    tmpObj = JSONContent[@"udid"];
    if(tmpObj && [tmpObj isKindOfClass:[NSString class]]) {
        self.udid = tmpObj;
    }

    tmpObj = JSONContent[@"build_version"];
    if(tmpObj && [tmpObj respondsToSelector:@selector(intValue)]) {
        self.buildVersion = [tmpObj intValue];
    }

    tmpObj = JSONContent[@"phone_number"];
    if(tmpObj && [tmpObj isKindOfClass:[NSString class]]) {
        self.phoneNumber = tmpObj;
    }

    tmpObj = JSONContent[@"push_token"];
    if(tmpObj && [tmpObj isKindOfClass:[NSString class]]) {
        self.appleToken = tmpObj;
    }

    tmpObj = JSONContent[@"android_token"];
    if(tmpObj && [tmpObj isKindOfClass:[NSString class]]) {
        self.androidToken = tmpObj;
    }

    tmpObj = JSONContent[@"user_uuid"];
    if(tmpObj && [tmpObj isKindOfClass:[NSString class]]) {
        self.userUUID = tmpObj;
    }
}

@end
