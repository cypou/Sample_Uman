/*
 *  PAULogger.h
 *  Project : Pauser
 *
 *  Description : Log utilities
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2014/10/15
 *  Copyright (c) 2014 Symille. All rights reserved.
 *
 */

@import Foundation;

enum {
	kPAULogOptionsNone   = 0x00000000,
	kPAULogOptionsRunLog = 0x00000001, 	//If this option is used , log will be written to a file in addition to the console
    kPAULogOptionsSendToTestFlight = 0x00000002
};


extern NSString *const kPAULogAtomTypeKey;      //@"HTTP", @"NOTI", @"APPL"
extern NSString *const kPAULogAtomTypeHTTPValue;
extern NSString *const kPAULogAtomTypeNotificationValue;
extern NSString *const kPAULogAtomTypeApplicationValue;
extern NSString *const kPAULogAtomStartDateKey;
extern NSString *const kPAULogAtomMethodKey;
extern NSString *const kPAULogAtomEndPointKey;
extern NSString *const kPAULogAtomMessageKey;       //Used instead of Message in APPL and NOTI
extern NSString *const kPAULogAtomParametersKey;
extern NSString *const kPAULogAtomAppStateKey;
extern NSString *const kPAULogAtomStatusKey;
extern NSString *const kPAULogAtomDurationKey;
extern NSString *const kPAULogAtomServerDurationKey;
extern NSString *const kPAULogAtomServerMessageKey;



#define PAULog(doLog, ...) PAULogInternal(doLog, __FILE__, __LINE__, 0, __VA_ARGS__)


__BEGIN_DECLS
/* Create the log system: simple encapsulation of direct call to PAULogger object */
void PAULogInitializeReporter(uint32_t options);

/* Main log function usually called through a macro*/
void PAULogInternal(BOOL doLog, const char * filename, unsigned int line, int dumpStack, NSString * format, ...);
__END_DECLS


/* Logger reporter interface */
@interface  PAULogger: NSObject
{
    NSString *_identifier;
	NSString *_deviceModel;
	NSString *_deviceOS;
	
	uint32_t _options;
	
	NSString *_pathToRunLogFolder;
	NSString *_currentLogName;
	
    dispatch_queue_t _dataWriteQueue; //not used for now but move later to use async file writing
    NSMutableDictionary *_logAtoms;
}

@property(assign) uint32_t          options;
@property(nonatomic,strong) NSString         *pathToRunLogFolder;
@property(nonatomic,strong) NSString         *currentLogName;

/* Singleton access to log reporter */
+ (PAULogger *)defaultLogger;

/* Provides back a list of saved logs : that is the one saved when kPAULogOptionsRunLog is there */
- (NSArray *)savedLogNames;

/* Will remove all logs from the log folder */
- (void)deleteLogs;

/* Provides back the full content of a log */
- (NSString *)contentOfLogWithName:(NSString *)logName;

/* Get back all the log atoms */
- (void)logAtomWithData:(NSDictionary *)data forUUID:(NSString *)logUUID;

/* Get back all the log atoms */
- (NSArray *)allLogAtoms;

/* Send back an string contaning an HTML <table>  */
- (NSString *) allAtomsHTMLRepresentation;
@end



