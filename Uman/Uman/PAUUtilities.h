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

/* Make sure a folder exists at a given path. Returns NO when creation error or something similar */
BOOL PAUEnsureDirectoryAtPath(NSString *cachePath);

/* Simple encoding utility : e.g used to generate password for anonymous */
NSString *PAUSha1FromString(NSString *input);

/* Get a MD5 from a string */
NSString *PAUMD5FromString(NSString *input);

/* Simple encoding utility data version : e.g used to generate password for anonymous */
NSString *PAUSha1FromData(NSData *data);

/* Will generate the key for anonymous usage */
NSString *PAUAnonymousDeviceKey();

/* Will generate the password for anonymous usage */
NSString *PAUAnonymousDevicePassword(NSString *key);

/* Will return a NSString from a set of Key values */
NSString *PAUQueryStringFromDictionary(NSDictionary *inputDictionary, BOOL doURLEncodeKey, BOOL doURLEncodeValue);

/* UniqueEndPath */
NSString *PAUEndPointUniqueEndPath(NSString *fullURLString);

/* Data for mime part */
NSData *PAUPostMediaData(NSString *filePath);

/* Create an SQL lite storage with proper tables */
BOOL PAUEnsurePersistentSQLDatabaseAtDirectory(NSString *path, int version, NSArray *classesArray);

/* Useful for upgrade scenario */
int PAUUtilityConvertMarketingVersionTo3Digit(NSString *version);