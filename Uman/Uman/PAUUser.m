/*
 *  PAUUser.h
 *  Project : Pauser
 *
 *  Description : A user on the WebIdea platorm
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2014/10/15
 *  Copyright (c) 2014 Symille. All rights reserved.
 *
 */

@import Foundation;

#import "PAUBaseObject.h"
#import "PAUUser.h"

NSString *const kPAUUserRegistrationFieldUsage = @"PAUUserRegistrationFieldUsage";

@implementation PAUUser

@synthesize email = _email;
@synthesize fbPublish = _fbPublish;
@synthesize password = _password;
@synthesize role = _role;
@synthesize authToken = _authToken;
@synthesize refreshToken = _refreshToken;
@synthesize lastName = _lastName;
@synthesize firstName = _firstName;
@synthesize deviceUUIDs  = _deviceUUIDs;
@synthesize mediaUUIDs  = _mediaUUIDs;
@synthesize facebookID = _facebookID;
@synthesize facebookToken = _facebookToken;


@synthesize openProgramUUIDs = _openProgramUUIDs;
@synthesize disabledProgramUUIDs = _disabledProgramUUIDs;
@synthesize extraProgramUUIDs = _extraProgramUUIDs;


#pragma mark == LIFE CYCLE ==
/* Register towards to the base class */
+ (void)load
{
    [PAUBaseObject registerClass:NSStringFromClass([self class]) forType:kPAUObjectTypeUser JSONClassName:@"User"];
    [PAUBaseObject registerClass:NSStringFromClass([self class]) forType:kPAUObjectTypeUser JSONClassName:@"user"];    
}

/* Prefix for when compensating UUID */
+ (NSString *)uuidPrefix
{
    return @"user";
}

#pragma mark == SQL SERIALIZATION ==
/* Will return the comment to be executed when a storage DB needs to be created */
+ (char *)persistentSQLCreateStatement
{
    char *sqlStatement = "CREATE TABLE IF NOT EXISTS  USER("  \
    "UUID TEXT PRIMARY KEY     NOT NULL," \
    "LOGIN_EMAIL         TEXT    NOT NULL," \
    "LOGIN_PASSWORD      TEXT    NOT NULL," \
    "FIRST_NAME      TEXT    NOT NULL," \
    "LAST_NAME      TEXT    NOT NULL," \
    "FB_ID      TEXT     NOT NULL," \
    "FB_TOKEN      TEXT     NOT NULL," \
    "AUTH_TOKEN     TEXT     NOT NULL," \
    "REFRESH_TOKEN     TEXT     NOT NULL," \
    "DEVICE_UUIDS     TEXT     NOT NULL," \
    "MEDIA_UUIDS     TEXT     NOT NULL," \
    "OPEN_PROGRAM_UUIDS     TEXT     NOT NULL," \
    "DISABLED_PROGRAM_UUIDS     TEXT     NOT NULL," \
    "ROLE    INTEGER     NOT NULL," \
    "FB_PUBLISH    INTEGER     NOT NULL);";
    return sqlStatement;
}

/* Called when data is loaded from disk */
+ (char *)loadAllSQLIndexStatement
{
    return "SELECT * FROM USER";
}


/* Will return the comment to be executed when a just after a storage DB created */
+ (char *)persistentSQLIndexStatement
{
    char *sqlStatement = "CREATE UNIQUE INDEX user_idx ON USER(UUID);";
    return sqlStatement;
}


/* Write to SQL Database */
- (BOOL)writeToDatabaseWithHandle:(sqlite3 *)dbHandle
{
    BOOL result = NO;
    if (!dbHandle) return result;
    if([self.uuid isEqualToString:@"PAU.user.temporary"]) return result;

    NSString *deviceString = [_deviceUUIDs componentsJoinedByString:@","];
    if (0 == [deviceString length]) deviceString = @"--";
    
    NSString *mediaString = [_mediaUUIDs componentsJoinedByString:@","];
    if (0 == [mediaString length]) mediaString = @"--";

    NSString *openProgramString = [_openProgramUUIDs componentsJoinedByString:@","];
    if (0 == [openProgramString length]) openProgramString = @"--";

    NSString *disabledProgramString = [_disabledProgramUUIDs componentsJoinedByString:@","];
    if (0 == [disabledProgramString length]) disabledProgramString = @"--";
    
    
    char * sqlStatement  = sqlite3_mprintf("INSERT OR REPLACE INTO USER (UUID, LOGIN_EMAIL, LOGIN_PASSWORD, FIRST_NAME, LAST_NAME, FB_ID, FB_TOKEN, AUTH_TOKEN, REFRESH_TOKEN, DEVICE_UUIDS,  MEDIA_UUIDS, OPEN_PROGRAM_UUIDS, DISABLED_PROGRAM_UUIDS, ROLE, FB_PUBLISH) values ( '%q', '%q', '%q', '%q', '%q', '%q', '%q', '%q', '%q', '%q', '%q', '%q', '%q', '%d', '%d');",
                                           [self.uuid UTF8String],
                                           [self.email length] ? [self.email UTF8String] : "--",
                                           [self.password length]? [self.password UTF8String]: "--",
                                           [self.firstName length]? [self.firstName UTF8String]: "--",
                                           [self.lastName length]? [self.lastName UTF8String]: "--",
                                           [self.facebookID length]? [self.facebookID UTF8String]: "--",
                                           [self.facebookToken length]? [self.facebookToken UTF8String]: "--",
                                           [self.authToken length]? [self.authToken UTF8String]: "--",
                                           [self.refreshToken length]? [self.refreshToken UTF8String]: "--",
                                           [deviceString UTF8String],
                                           [mediaString UTF8String],
                                           [openProgramString UTF8String],
                                           [disabledProgramString UTF8String],
                                           self.role,
                                           self.fbPublish);
    
    char *errMessage = NULL;
    int dbResult = sqlite3_exec(dbHandle, sqlStatement, nil, 0, &errMessage);
    if (SQLITE_OK != dbResult){
        NSLog(@"[ERROR] PAUUser save to database %s", errMessage);                
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
    char *sqlBlockStatement = sqlite3_mprintf("DELETE FROM USER WHERE UUID IS '%q';",[self.uuid UTF8String]);
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
    

    NSString *tmpString = information[@"LOGIN_EMAIL"];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { self.email = tmpString; }
    
    tmpString = information[@"LOGIN_PASSWORD"];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { self.password = tmpString; }
    
    tmpString = information[@"FIRST_NAME"];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { self.firstName = tmpString ; }
    
    tmpString = information[@"LAST_NAME"];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { self.lastName= tmpString; }
    
    tmpString = information[@"FB_ID"];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { self.facebookID= tmpString; }
    
    tmpString = information[@"FB_TOKEN"];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { self.facebookToken= tmpString; }
    
    tmpString = information[@"AUTH_TOKEN"];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { self.authToken= tmpString; }
    
    tmpString = information[@"REFRESH_TOKEN"];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { self.refreshToken= tmpString; }
    
    tmpString = information[@"DEVICE_UUIDS"];
    if (!_deviceUUIDs) _deviceUUIDs = [[NSMutableArray alloc] init];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { [_deviceUUIDs addObjectsFromArray:[tmpString componentsSeparatedByString:@","]]; }

    tmpString = information[@"MEDIA_UUIDS"];
    if (!_mediaUUIDs) _mediaUUIDs = [[NSMutableArray alloc] init];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { [_mediaUUIDs addObjectsFromArray:[tmpString componentsSeparatedByString:@","]]; }

    tmpString = information[@"OPEN_PROGRAM_UUIDS"];
    if (!_openProgramUUIDs) _openProgramUUIDs = [[NSMutableArray alloc] init];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { [_openProgramUUIDs addObjectsFromArray:[tmpString componentsSeparatedByString:@","]]; }

    tmpString = information[@"DISABLED_PROGRAM_UUIDS"];
    if (!_disabledProgramUUIDs) _disabledProgramUUIDs = [[NSMutableArray alloc] init];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { [_disabledProgramUUIDs addObjectsFromArray:[tmpString componentsSeparatedByString:@","]]; }
    
    tmpString = information[@"ROLE"];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { self.role= [tmpString intValue]; }

    tmpString = information[@"FB_PUBLISH"];
    if (tmpString && ![tmpString isEqualToString:@"--"]) { self.fbPublish= [tmpString boolValue]; }
    
    return self;
    
}



#pragma mark == JSON SERIALIZATION == 
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

    tmpObj = JSONContent[@"email"];
    if(tmpObj && [tmpObj isKindOfClass:[NSString class]]) {
        self.email = tmpObj;
    }

    tmpObj = JSONContent[@"password"];
    if(tmpObj && [tmpObj isKindOfClass:[NSString class]] && (NO == [tmpObj isEqualToString:@"password cannot be asked"])) {
        self.password = tmpObj;
    }

    tmpObj = JSONContent[@"role"];
    if(tmpObj && [tmpObj isKindOfClass:[NSString class]]) {
        if([tmpObj isEqualToString:@"ROLE_USER"]) {
            self.role = kPAUUserRoleUser;
        }
    }
    
    tmpObj = JSONContent[@"fbid"];
    if(tmpObj && [tmpObj isKindOfClass:[NSString class]]) {
        self.facebookID = tmpObj;
    }
    
    tmpObj = JSONContent[@"access_token"];
    if(tmpObj && [tmpObj isKindOfClass:[NSString class]]) {
        self.facebookToken = tmpObj;
    }
    
    tmpObj = JSONContent[@"firstname"];
    if(tmpObj && [tmpObj isKindOfClass:[NSString class]]) {
        self.firstName = tmpObj;
    }

    tmpObj = JSONContent[@"lastname"];
    if(tmpObj && [tmpObj isKindOfClass:[NSString class]]) {
        self.lastName = tmpObj;
    }

    tmpObj = JSONContent[@"devices"];
    if(tmpObj && [tmpObj isKindOfClass:[NSArray class]]) {
        if(nil == _deviceUUIDs) _deviceUUIDs = [[NSMutableArray alloc] init];
        [tmpObj enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if([obj isKindOfClass:[NSDictionary class]] && (nil != obj[@"uuid"])) {
                [_deviceUUIDs addObject:obj[@"uuid"]];
            }
        }];
    }

    tmpObj = JSONContent[@"auth_token"];
    if(tmpObj && [tmpObj isKindOfClass:[NSString class]]) {
        self.authToken = tmpObj;
    }
    
    tmpObj = JSONContent[@"disabled_programs"];
    if(tmpObj &&[tmpObj isKindOfClass:[NSArray class]]) {
        if(nil == _disabledProgramUUIDs) _disabledProgramUUIDs = [[NSMutableArray alloc] init];
        if(nil == _extraProgramUUIDs) _extraProgramUUIDs = [[NSMutableArray alloc] init];
        [tmpObj enumerateObjectsUsingBlock:^(NSDictionary *aProgram, NSUInteger idx, BOOL *stop) {
            BOOL isExtra = [aProgram[@"is_extra"] boolValue];
            if(isExtra) {
                if(NO == [_extraProgramUUIDs containsObject:aProgram[@"uuid"]]) {
                    [_extraProgramUUIDs addObject:aProgram[@"uuid"]];
                }
            } else {
                if(NO == [_disabledProgramUUIDs containsObject:aProgram[@"uuid"]]) {
                    [_disabledProgramUUIDs addObject:aProgram[@"uuid"]];
                }
            }
        }];
    }
    
    tmpObj = JSONContent[@"open_programs"];
    if(tmpObj &&[tmpObj isKindOfClass:[NSArray class]]) {
        if(nil == _openProgramUUIDs) _openProgramUUIDs = [[NSMutableArray alloc] init];
        if(nil == _extraProgramUUIDs) _extraProgramUUIDs = [[NSMutableArray alloc] init];        
        [tmpObj enumerateObjectsUsingBlock:^(NSDictionary *aProgram, NSUInteger idx, BOOL *stop) {
            BOOL isExtra = [aProgram[@"is_extra"] boolValue];
            if(isExtra) {
                if(NO == [_extraProgramUUIDs containsObject:aProgram[@"uuid"]]) {
                    [_extraProgramUUIDs addObject:aProgram[@"uuid"]];
                }
            } else {
                if(NO == [_openProgramUUIDs containsObject:aProgram[@"uuid"]]) {
                    [_openProgramUUIDs addObject:aProgram[@"uuid"]];
                }
            }
        }];
    }
    
    tmpObj = JSONContent[@"medias"];
    if(tmpObj &&[tmpObj isKindOfClass:[NSArray class]]) {
        if(nil == _mediaUUIDs) _mediaUUIDs = [[NSMutableArray alloc] init];
        NSMutableSet *tmpSet = [NSMutableSet set];
        [tmpObj enumerateObjectsUsingBlock:^(NSDictionary *aMedia, NSUInteger idx, BOOL *stop) {
            NSString *mediaUUID = aMedia[@"uuid"];
            NSString *mediaRole = aMedia[@"role"];
            if(NO ==[tmpSet containsObject:mediaRole]) {
                if(NO == [_mediaUUIDs containsObject:mediaUUID]) {
                    [_mediaUUIDs addObject:mediaUUID];
                    [tmpSet addObject:mediaRole];
                }
            }
        }];
    }
    
    tmpObj = JSONContent[@"fb_publish"];
    if(tmpObj && [tmpObj respondsToSelector:@selector(boolValue)]) {
        self.fbPublish = [tmpObj boolValue];
    }
    
    tmpObj = JSONContent[@"is_subscriber"];
    if(tmpObj && [tmpObj respondsToSelector:@selector(boolValue)]) {
        self.hasSubscribed = [tmpObj boolValue];
    }
    
    tmpObj = JSONContent[@"metrics"];
    if(tmpObj &&[tmpObj isKindOfClass:[NSDictionary class]]) {
        self.metricsStats = JSONContent[@"metrics"][@"stats"];
    }
}

/* Add a device to the array of devices */
- (void)addDeviceWithUUID:(NSString *)deviceUUID
{
    if(0 != [deviceUUID length]) {
        if(nil == _deviceUUIDs) _deviceUUIDs = [[NSMutableArray alloc] init];
        [_deviceUUIDs addObject:deviceUUID];
    }
}

/* Add a device to the array of devices */
- (void)addMediaWithUUID:(NSString *)mediaUUID
{
    if(0  != [mediaUUID length]) {
        if(nil == _mediaUUIDs) _mediaUUIDs = [[NSMutableArray alloc] init];
        [_mediaUUIDs addObject:mediaUUID];
    }
}


/* Predefined fields set */
+ (NSArray *)fieldsForUsage:(NSString *) usageName
{
    NSArray *result = nil;
    if([usageName isEqualToString:kPAUUserRegistrationFieldUsage]) {
        result = @[@"uuid", @"email",@"devices",@"firstname", @"lastname",@"medias"];
    } else {
        result = [NSArray array];
    }
    return result;
}


@end
