/*
 *  PAULogger.m
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
@import UIKit;

#import "PAULogger.h"

#import "TestFlight.h"


NSString *const kPAULogAtomTypeKey = @"PAULogAtomTypeKey";
NSString *const kPAULogAtomTypeHTTPValue = @"HTTP";
NSString *const kPAULogAtomTypeNotificationValue = @"NOTI";
NSString *const kPAULogAtomTypeApplicationValue  = @"APPL";
NSString *const kPAULogAtomStartDateKey = @"PAULogAtomStartDateKey";
NSString *const kPAULogAtomMethodKey = @"PAULogAtomMethodKey";
NSString *const kPAULogAtomEndPointKey = @"PAULogAtomEndPointKey";
NSString *const kPAULogAtomMessageKey = @"PAULogAtomMessageKey";
NSString *const kPAULogAtomParametersKey = @"PAULogAtomParametersKey";
NSString *const kPAULogAtomAppStateKey = @"PAULogAtomAppStateKey";
NSString *const kPAULogAtomStatusKey = @"PAULogAtomStatusKey";
NSString *const kPAULogAtomDurationKey = @"PAULogAtomDurationKey";
NSString *const kPAULogAtomServerDurationKey = @"PAULogAtomServerDurationKey";
NSString *const kPAULogAtomServerMessageKey = @"PAULogAtomServerMessageKey";



#define kPAURunLogFolderName @"Logs/RunLogs"

#include <execinfo.h>
#import <libgen.h>
#import <signal.h>
#import <sys/time.h>
#import <time.h>
#include <unistd.h>


#pragma mark ==  MAIN LOG FUNCTIONS ==
/* Main log function. Write to stderr */
void PAULogInternal(BOOL doLog, const char *filename, unsigned int line, int dumpStack, NSString * format, ...)
{
    if(NO == doLog) return;
    
	va_list argp;
	NSString * str;
	char * filenameCopy = NULL;
	char * lastPathComponent = NULL;
	struct timeval tv;
	struct tm tm_value;
    
    if(nil == format) return;
    
    @autoreleasepool {
        va_start(argp, format);
        str = [[NSString alloc] initWithFormat:format arguments:argp];
        va_end(argp);
        
        if(kPAULogOptionsSendToTestFlight == ([PAULogger defaultLogger].options & kPAULogOptionsSendToTestFlight)) {
//            TFLog(@"%@", str);
        }
        
        //going through a FILE* allows later to indicate an other file than stderr
        static FILE * stderrFileStream = NULL;
        static FILE * logFileStream = NULL;
        if ( NULL == stderrFileStream )
            stderrFileStream = stderr;
        
        gettimeofday(&tv, NULL);
        localtime_r(&tv.tv_sec, &tm_value);
        if(filename && line) {
            fprintf(stderrFileStream, "%04u-%02u-%02u %02u:%02u:%02u.%03u ", tm_value.tm_year + 1900, tm_value.tm_mon + 1, tm_value.tm_mday, tm_value.tm_hour, tm_value.tm_min, tm_value.tm_sec, tv.tv_usec / 1000);
            fprintf(stderrFileStream, "[%s:%u] ", [[[NSProcessInfo processInfo] processName] UTF8String], [[NSProcessInfo processInfo] processIdentifier]);
            filenameCopy = strdup(filename);
            lastPathComponent = basename(filenameCopy);
            fprintf(stderrFileStream, "(%s:%u) ", lastPathComponent, line);
        }
        fprintf(stderrFileStream, "%s\n", [str UTF8String]);
        
        
        if (dumpStack) {
            void * frame[128];
            int frameCount;
            int i;
            
            frameCount = backtrace(frame, 128);
            for(i = 0 ; i < frameCount ; i ++) {
                fprintf(stderrFileStream, "  %p\n", frame[i]);
            }
        }
        
        uint32_t currentOptions = [PAULogger defaultLogger].options;
        if((currentOptions & kPAULogOptionsRunLog) == kPAULogOptionsRunLog) {
            if ( NULL == logFileStream ) {
                NSString *fullPath =[[PAULogger defaultLogger].pathToRunLogFolder stringByAppendingPathComponent:[PAULogger defaultLogger].currentLogName];
                logFileStream =fopen([fullPath UTF8String], "a");
                fprintf(logFileStream, "[%s:%u] ", [[[NSProcessInfo processInfo] processName] UTF8String], [[NSProcessInfo processInfo] processIdentifier]);
                fprintf(logFileStream, "%04u-%02u-%02u\n", tm_value.tm_year + 1900, tm_value.tm_mon + 1, tm_value.tm_mday);
                fprintf(logFileStream, "---------------------------------------\n");
            }
            if(logFileStream) {
                if(filename && line) {
                    fprintf(logFileStream, "[%02u:%02u:%02u.%03u]", tm_value.tm_hour, tm_value.tm_min, tm_value.tm_sec, tv.tv_usec / 1000);
                    fprintf(logFileStream, "[%s:%u]\n  ", lastPathComponent, line);
                }
                fprintf(logFileStream, "%s\n", [str UTF8String]);
                fflush(logFileStream);
            }
        }
        free(filenameCopy);
    }
}


/* Facility to initialize the crash reporter*/
void PAULogInitializeReporter(uint32_t options)
{
	[PAULogger defaultLogger].options = options;
    if(kPAULogOptionsSendToTestFlight == (options & kPAULogOptionsSendToTestFlight)) {
//        [TestFlight setOptions:@{ TFOptionLogToConsole : @NO }];
//        [TestFlight setOptions:@{ TFOptionLogToSTDERR : @NO }];
    }
}


#pragma mark == CRASH LOG REPORTER ==

@implementation PAULogger

@synthesize pathToRunLogFolder      = _pathToRunLogFolder;
@synthesize options                 = _options;
@synthesize currentLogName          = _currentLogName;


/* Singleton accessor. Use in general, although one can be created with a different identifier, but really this is not advised for now */
+ (PAULogger *) defaultLogger
{
    static dispatch_once_t pred = 0;
    __strong static PAULogger *_logger = nil;
    dispatch_once(&pred, ^{
        _logger = [[PAULogger alloc] init];
    });
	return _logger;
}

/* Init method will create folders if needed and gather info */
- (id) init
{
	self = [super init];
	if(self) {
		BOOL tmpBool;
        @autoreleasepool {
            _identifier = [[[NSBundle mainBundle] bundleIdentifier] copy];
            _deviceModel = [[[UIDevice currentDevice] model] copy];
            _deviceOS  = [[NSString alloc] initWithFormat:@"%@ %@", [[UIDevice currentDevice] systemName],  [[UIDevice currentDevice] systemVersion]];
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
            NSString *logDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:kPAURunLogFolderName];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:logDirectory isDirectory:&tmpBool]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:logDirectory withIntermediateDirectories:YES attributes:nil error:nil];
            }
            _pathToRunLogFolder = [logDirectory copy];
            
            NSDate *nowTime = [NSDate date];
            _currentLogName = [[NSString alloc] initWithFormat:@"Run-%@-%@.log", [[[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"] stringByReplacingOccurrencesOfString:@" " withString:@"-"],
                               [[[[nowTime description]  stringByReplacingOccurrencesOfString:@":" withString:@"-"] stringByReplacingOccurrencesOfString:@" " withString:@"-"] substringToIndex:[[nowTime description] length] -6]];
            
            _logAtoms = [[NSMutableDictionary alloc] init];
        }
	}
	return self;
}


/* Provides back a list of saved logs : that is the one saved when kPAULogOptionsRunLog is there */
- (NSArray *)savedLogNames
{
    NSError *tmpError;
    NSMutableArray *result = nil;
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_pathToRunLogFolder error:&tmpError];
    if(tmpError) return result;
    
    result = [NSMutableArray array];
    [dirContents enumerateObjectsUsingBlock:^(NSString *afileName, NSUInteger idx, BOOL *stop) {
        if ([afileName hasPrefix:@"Run-"]) {
            [result addObject:afileName];
        }
    }];
    return result;
}

/* Will remove all logs from the log folder (but keep the current one otherwise it woudl cause issues) */
- (void)deleteLogs
{
    NSError *tmpError;
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_pathToRunLogFolder error:&tmpError];
    if(tmpError) return;
    
    [dirContents enumerateObjectsUsingBlock:^(NSString *afileName, NSUInteger idx, BOOL *stop) {
        if ([afileName hasPrefix:@"Run-"] && (NO == [afileName isEqualToString:_currentLogName])) {
            NSError *anError;
            [[NSFileManager defaultManager] removeItemAtPath:[_pathToRunLogFolder stringByAppendingPathComponent:afileName] error:&anError];
        }
    }];
}

/* Provides back the full content of a log */
- (NSString *)contentOfLogWithName:(NSString *)logName
{
    NSError *tmpError;
    NSString *fullPath =[_pathToRunLogFolder stringByAppendingPathComponent:logName];
    return [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:&tmpError];
}


#pragma mark == LOG ATOMS == 
/* Get back all the log atoms */
- (void)logAtomWithData:(NSDictionary *)data forUUID:(NSString *)logUUID
{
    if(data[kPAULogAtomTypeKey]) {
        if (nil == logUUID) logUUID =[[NSUUID UUID] UUIDString];        
        _logAtoms[logUUID] = data;
    }
}


/* Will return all Logs for HTTP queries recorded in reverse  */
- (NSArray *)allLogAtoms
{
    NSArray *tmpArrayUUID= [_logAtoms keysSortedByValueUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        return [obj1[kPAULogAtomStartDateKey] compare:obj2[kPAULogAtomStartDateKey]];
    }];
    NSMutableArray *result = [NSMutableArray array];
    [tmpArrayUUID enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [result addObject:[_logAtoms objectForKey:obj]];
    }];
    return result;
}

/* Send back an string contaning an HTML  */
- (NSString *) allAtomsHTMLRepresentation
{
    NSMutableString *emailBody = [NSMutableString string];
    
    
    NSArray *allLogs = [self allLogAtoms];
    
    [emailBody appendString:@"<table cellspacing=\"0\" border=\"1\" style=\"table-layout:fixed;\">"];
    [emailBody appendString:@"<col id=\"date\"/>"];
    [emailBody appendString:@"<col id=\"method\"/>"];
    [emailBody appendString:@"<col id=\"endpoint\"/>"];
    [emailBody appendString:@"<col id=\"parameters\"/>"];
    [emailBody appendString:@"<col id=\"appstate\"/>"];
    [emailBody appendString:@"<col id=\"status\"/>"];
    [emailBody appendString:@"<col id=\"duration\"/>"];
    [emailBody appendString:@"<col id=\"server time\"/>"];
    [emailBody appendString:@"<col id=\"server message\"/>"];
    [emailBody appendString:@"<thead style=\"word-wrap: break-word;\">"];
    [emailBody appendString:@"<tr style=\"background-color:black;color:white;\">"];
    [emailBody appendString:@"<th scope=\"col\" style=\"PAUth:80px\">Date</th>"];
    [emailBody appendString:@"<th scope=\"col\" style=\"PAUth:80px\">Method</th>"];
    [emailBody appendString:@"<th scope=\"col\" style=\"PAUth:220px;text-align:left;\">EndPoint</th>"];
    [emailBody appendString:@"<th scope=\"col\" style=\"PAUth:220px;text-align:left;\">Parameters</th>"];
    [emailBody appendString:@"<th scope=\"col\" style=\"PAUth:80px;text-align:left;\">AppState</th>"];
    [emailBody appendString:@"<th scope=\"col\" style=\"PAUth:80px;text-align:center;\">Status</th>"];
    [emailBody appendString:@"<th scope=\"col\" style=\"PAUth:80px;text-align:center;\">Duration</th>"];
    [emailBody appendString:@"<th scope=\"col\" style=\"PAUth:80px;text-align:center;\">Server Time</th>"];
    [emailBody appendString:@"<th scope=\"col\" style=\"PAUth:120px;text-align:center;\">Server Message</th>"];
    
    [emailBody appendString:@"</tr>"];
    [emailBody appendString:@"</thead>"];
    [emailBody appendString:@"<tbody style=\"word-wrap: break-word;\">"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    
    for(NSDictionary *aLog in allLogs) {
        float requestTimeSecond = ((float)[[aLog objectForKey:kPAULogAtomDurationKey] floatValue])/1000.0;
        
        if([aLog[kPAULogAtomTypeKey] isEqualToString:kPAULogAtomTypeHTTPValue]) {
            if([[aLog objectForKey:kPAULogAtomStatusKey] integerValue] >= 300) {
                [emailBody appendString:@"<tr style=\"background-color:#ff0000\">"];
            } else {
                if (requestTimeSecond < 0.5) {
                    [emailBody appendString:@"<tr style=\"background-color:#a8cc46\">"];
                } else if (requestTimeSecond < 1) {
                    [emailBody appendString:@"<tr style=\"background-color:#577600\">"];
                } else if (requestTimeSecond < 1.5) {
                    [emailBody appendString:@"<tr style=\"background-color:#79a402\">"];
                } else if (requestTimeSecond < 5) {
                    [emailBody appendString:@"<tr style=\"background-color:#33420a\">"];
                } else {
                    [emailBody appendString:@"<tr style=\"background-color:#23261b\">"];
                }
            }
        } else if([aLog[kPAULogAtomTypeKey] isEqualToString:kPAULogAtomTypeApplicationValue]) {
            [emailBody appendString:@"<tr style=\"background-color:#F781F3\">"];
        } else if([aLog[kPAULogAtomTypeKey] isEqualToString:kPAULogAtomTypeNotificationValue]) {
            [emailBody appendString:@"<tr style=\"background-color:#6699FF\">"];
        }

        
        NSString *subTitle = [NSString stringWithFormat:@"<td style=\"text-align:center;PAUth:80px;\" >%@</td> <td style=\"text-align:center;PAUth:80px;\">%@</td> <td style=\"text-align:left;PAUth:300px;\">%@</td> <td style=\"text-align:left;PAUth:300px;\">%@</td> <td style=\"text-align:left;PAUth:300px;\">%@</td> <td style=\"text-align:center;\">%@</td> <td style=\"text-align:center;\">%0.4f</td><td style=\"text-align:center;\">%0.4f</td><td style=\"text-align:center;\">%@</td>",
                              [dateFormatter stringFromDate:[aLog objectForKey:kPAULogAtomStartDateKey]],
                              [aLog objectForKey:kPAULogAtomMethodKey] ? [aLog objectForKey:kPAULogAtomMethodKey] : [aLog objectForKey:kPAULogAtomTypeKey],
                              [aLog objectForKey:kPAULogAtomEndPointKey] ? [aLog objectForKey:kPAULogAtomEndPointKey] : [aLog objectForKey:kPAULogAtomMessageKey],
                              [aLog objectForKey:kPAULogAtomParametersKey] ? [aLog objectForKey:kPAULogAtomParametersKey] :@"--",
                              [aLog objectForKey:kPAULogAtomAppStateKey],
                              [aLog objectForKey:kPAULogAtomStatusKey] ? [aLog objectForKey:kPAULogAtomStatusKey] : @"--",
                              [aLog objectForKey:kPAULogAtomDurationKey] ? [[aLog objectForKey:kPAULogAtomDurationKey] floatValue] : 0.0,
                              [[aLog objectForKey:kPAULogAtomServerDurationKey] floatValue],
                              [aLog objectForKey:kPAULogAtomServerMessageKey]];
        [emailBody appendString:subTitle];
        [emailBody appendString:@"</tr>"];
    }
    
    [emailBody appendString:@"</tbody></table>"];
    return  emailBody;

}


#if 0
/* Write data to the log folder based on identifier : TODO USE LATER*/
- (BOOL)writeLogData:(NSData *) data withIdentifier:(NSString *)identifier asynchronous:(BOOL)asynchronous
{
    BOOL result = NO;
    if(nil == _identifier) return result;
    if(0 == [identifier length]) return result;
    
    NSString *dataPath = [_pathToRunLogFolder stringByAppendingPathComponent:identifier];
    if(!asynchronous) {
        result = [data writeToFile:dataPath atomically:YES];
    } else {
        if(!_dataWriteQueue) {
            _dataWriteQueue = dispatch_queue_create("PAUDataWriteQueue", NULL);
        }
        
        if(![[NSFileManager defaultManager]  fileExistsAtPath:dataPath ]) {
            [[NSFileManager defaultManager] createFileAtPath:dataPath contents:nil attributes:nil];
        }
        
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:dataPath];
        
        dispatch_async( _dataWriteQueue , ^ {
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:data];
            [fileHandle closeFile];
        });
        
    }
    return result;
}
#endif

@end
