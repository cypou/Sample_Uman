/*
 *  PAUUtilities.h
 *  Project : Pauser
 *
 *  Description : Some C based utilities like folder manipulation
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2014/10/15
 *  Copyright (c) 2014 Symille. All rights reserved.
 *
 */

@import Foundation;
@import UIKit;

#import <CommonCrypto/CommonHMAC.h>
#import <sqlite3.h>

#import "PAULogger.h"
#import "PAUBaseObject.h"
#import "PAUUtilities.h"


#define PAUUTILITYLOGENABLED YES && PAUGLOBALLOGENABLED


/* Directory creation : check there is no file with the same name, if yes remove it, create create directory if not present */
BOOL PAUEnsureDirectoryAtPath(NSString *dirPath)
{
    BOOL result = NO;
	NSError	*error = nil;
	BOOL	isDirectory = NO;
	BOOL	cacheExists = NO;
	
	cacheExists = [[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDirectory];
	if ((cacheExists == YES) && (isDirectory == NO)){
		/* It is not a directory. Remove it. */
		if ([[NSFileManager defaultManager] removeItemAtPath:dirPath error:&error] == NO) {
            NSLog(@" --> can not remove file that is here instead of directory ");
            return result;
        } else {
            cacheExists = NO;
        }
	}
	/* Now we can safely create the cache directory if needed. */
	if (cacheExists == NO){
		if ([[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error] == NO) {
            NSLog(@" --> Could not create directory %@ ", dirPath);
        } else {
            result = YES;
        }
	}

    return result;
}

/* Simple encoding utility : e.g used to generate password for anonymous */
NSString *PAUSha1FromString(NSString *input)
{
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    return PAUSha1FromData(data);
}

/* Simple encoding utility data version : e.g used to generate password for anonymous */
NSString *PAUSha1FromData(NSData *data)
{
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, (CC_LONG)(data.length), digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}


/* Will generate the key for anonymous usage */
NSString *PAUAnonymousDeviceKey()
{
//    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    return [[NSUUID UUID] UUIDString];
}

/* Will generate the password for anonymous usage */
NSString *PAUAnonymousDevicePassword(NSString *string)
{
    if(nil == string) string =[[[UIDevice currentDevice] identifierForVendor] UUIDString];
    return PAUSha1FromString([string capitalizedString]);
}


/* Will return a NSString from a set of Key values */
NSString *PAUQueryStringFromDictionary(NSDictionary *inputDictionary, BOOL doURLEncodeKey, BOOL doURLEncodeValue)
{
    NSMutableArray *joinArray = [NSMutableArray array];
    NSMutableDictionary *tmpDictionary = [inputDictionary mutableCopy];
    NSCharacterSet *URLQueryCharacterSet =[NSCharacterSet URLQueryAllowedCharacterSet];
    [tmpDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if(doURLEncodeKey) {
            if(doURLEncodeValue) {
                [joinArray addObject:[NSString stringWithFormat:@"%@=%@", [key stringByAddingPercentEncodingWithAllowedCharacters:URLQueryCharacterSet], [obj stringByAddingPercentEncodingWithAllowedCharacters:URLQueryCharacterSet]]];
            } else {
                [joinArray addObject:[NSString stringWithFormat:@"%@=%@", [key stringByAddingPercentEncodingWithAllowedCharacters:URLQueryCharacterSet], obj]];
            }
        } else {
            if(doURLEncodeValue) {
                [joinArray addObject:[NSString stringWithFormat:@"%@=%@", key, [obj stringByAddingPercentEncodingWithAllowedCharacters:URLQueryCharacterSet]]];
            } else {
                [joinArray addObject:[NSString stringWithFormat:@"%@=%@", key, obj]];
            }
        }
    }];
    return [joinArray componentsJoinedByString:@"&"];
}

/* UniqueEndPath */
NSString *PAUEndPointUniqueEndPath(NSString *fullURLString)
{
    NSMutableString *result = nil;
    NSURL *tmpURL = [NSURL URLWithString:fullURLString];
    
    NSString *path = [tmpURL path];
    NSString *queryString = [[tmpURL query] stringByRemovingPercentEncoding];
    
    NSMutableArray *simplifiedQueryArray = [NSMutableArray array];
    
    /* we store the query parameters if they're not 'fields', 'offset', or 'limit' */
    [[queryString componentsSeparatedByString:@"&"] enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
        NSString *queryParameter = (NSString *)obj;
        if (![queryParameter hasPrefix:@"fields="] && ![queryParameter hasPrefix:@"offset="] && ![queryParameter hasPrefix:@"limit="] && ![queryParameter hasPrefix:@"page="]) {
            [simplifiedQueryArray addObject:obj];
        }
    }];
    
    [simplifiedQueryArray sortUsingSelector:@selector(compare:)];
    
    result = [NSMutableString string];
    if(NO == [path hasPrefix:@"/"]) {
        [result appendString:@"/"];
    }
    [result appendString:path];
    if([simplifiedQueryArray count]) {
        [result appendFormat:@"?%@", [simplifiedQueryArray componentsJoinedByString:@"&"]];
    }
    
    
    
    return result;
}

/* Get a MD5 from a string */
NSString *PAUMD5FromString(NSString *input)
{
    // usefull for debugging caching
    // keep it !
    
    //    NSString *result = [input stringByReplacingOccurrencesOfString:@":" withString:@"-"];
    //    result = [result stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    //    return [NSString stringWithFormat:@"%@.png", result];
    
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, (CC_LONG) (strlen(cStr)), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
}

/* Data for mime part */
NSData *PAUPostMediaData(NSString *filePath)
{
    NSMutableData *result = [NSMutableData data];
    NSString *boundary = @"------------------------------3869230abe44";
    
//    [result appendData:[@"Content-Type: multipart/form-data; boundary=------------------------------3869230abe44" dataUsingEncoding:NSUTF8StringEncoding]];

#if 0
    [result appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [result appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\nContent-Type: image/jpeg\r\n\r\n", [filePath lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [result appendData:[NSData dataWithContentsOfFile:filePath]];
    [result appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
#else
//    NSString *boundary = @"------------------------------3869230abe44";
    
    [result appendData:[[NSString stringWithFormat:@"%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [result appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\nContent-Type: image/jpeg\r\n\r\n", [filePath lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [result appendData:[NSData dataWithContentsOfFile:filePath]];
    [result appendData:[[NSString stringWithFormat:@"\r\n%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
#endif
    return result;
}



/* Get displayable elapsed time from Date */
BOOL PAUEnsurePersistentSQLDatabaseAtDirectory(NSString *path, int version, NSArray *classesArray)
{
    BOOL result = NO;
    BOOL tmpBool;
    
    NSString *dbPath = [path stringByAppendingPathComponent:@"storage.sqllite"];
    BOOL dbExist = [[NSFileManager defaultManager] fileExistsAtPath:dbPath isDirectory:&tmpBool];
    if (dbExist) {
        PAULog(PAUUTILITYLOGENABLED, @"Database already present") ;
        return result;
    }
    
    sqlite3 *dbHandle;
    //Then the cache. Do we really need it in upgrade? No, better remove all and start again this will fill up naturally
    int dbResult =sqlite3_open([dbPath UTF8String], &dbHandle);
    if ( SQLITE_OK != dbResult) {
        PAULog(PAUUTILITYLOGENABLED, @"Failed to open database %s\n\r",sqlite3_errmsg(dbHandle)) ;
        sqlite3_close(dbHandle);
        return result;
    }
    
    //set the version on the DB
    char *errMessage = nil;
    int current3DigitVersion = PAUUtilityConvertMarketingVersionTo3Digit([[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"]);
    char *sqlStatement = sqlite3_mprintf("PRAGMA USER_VERSION=%d", current3DigitVersion);
    dbResult = sqlite3_exec(dbHandle, sqlStatement, NULL, NULL, &errMessage);
    if ( SQLITE_OK != dbResult) {
        PAULog(PAUUTILITYLOGENABLED, @"Failed to set user_verssion %s",errMessage) ;
        sqlite3_free(errMessage);
    }
    
    [classesArray enumerateObjectsUsingBlock:^(NSString *aClassString, NSUInteger idx, BOOL *stop) {
        char *errMessage = nil;
        Class tmpClass = NSClassFromString(aClassString);
        char *sqlStatement = [tmpClass persistentSQLCreateStatement];
        int dbResult = sqlite3_exec(dbHandle, sqlStatement, NULL, 0, &errMessage);
        if ( SQLITE_OK != dbResult) {
            PAULog(PAUUTILITYLOGENABLED, @"SQL error: %s", errMessage);
            sqlite3_free(errMessage);
        }
        
        sqlStatement = [tmpClass persistentSQLIndexStatement];
        dbResult = sqlite3_exec(dbHandle, sqlStatement, NULL, 0, &errMessage);
        if ( SQLITE_OK != dbResult) {
            PAULog(PAUUTILITYLOGENABLED, @"SQL error: %s", errMessage);
            sqlite3_free(errMessage);
        }
    }];
    
    sqlite3_close(dbHandle);
    
    result = YES;
    return result;
}

/* Convert 1.0.3 to 103 and 1.0 to 100 */
int PAUUtilityConvertMarketingVersionTo3Digit(NSString *version)
{
    NSMutableArray *componentArray = [NSMutableArray arrayWithArray:[version componentsSeparatedByString:@"."]];
    for(NSUInteger idx = [componentArray count]; idx < 3; idx++) {
        [componentArray addObject:@0];
    }
    __block int result = 0;
    [componentArray enumerateObjectsUsingBlock:^(NSString *aComponent, NSUInteger idx, BOOL *stop) {
        result = 10*result+[aComponent intValue];
    }];
    return result;
}
