/*
 *  PAUImageCache.m
 *  Project : Pauser
 *
 *  Description : A cache being able to download and store images so next time
 *  they will not be re-fetched and they can be resized easily
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2014/10/15
 *  Copyright (c) 2014 Symille. All rights reserved.
 *
 */

@import Foundation;

#import "PAUImageCache.h"
#import "PAULogger.h"
#import "PAUUtilities.h"

#define PAUIMAGECACHELOGENABLED NO && PAUGLOBALLOGENABLED


@interface PAUImageCache()

/* key for identifier, very often the URL string */
-(NSString*)_keyForIdentifier:(NSString*)identifier;

/* Data for an identifier if local */
- (NSData *)_localDataForKey:(NSString*)key andSize:(CGSize)size;

/* write image on disk depending on key and dsize */
- (void)_writelocalData:(NSData *)data forKey:(NSString*)key withSize:(CGSize)desiredImageSize;

/* Convert image to given size*/
- (NSData *)_imageWithData:(NSData *)data convertToSize:(CGSize)size;

@end

@implementation PAUImageCache

#pragma mark == LIFE CYCLE ==

/* Singleton access */
+ (PAUImageCache *)defaultCache
{
    static dispatch_once_t pred = 0;
    __strong static PAUImageCache *_imageCache = nil;
    dispatch_once(&pred, ^{
        _imageCache = [[PAUImageCache alloc] init];
    });
	return _imageCache;
}

/* Designated initializer : create folder structure*/
- (id)init
{
    self = [super init];
    
    _pathToContainerDictionary = [[NSMutableDictionary alloc] init];
    
    //take care about the image folder structure. Ensure all is here to startup and grab what is existing
    //the structure will be originals/,   resized/22x22, resized/44x44 etc..
    NSString *directoryPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"/images/"];
    PAUEnsureDirectoryAtPath(directoryPath);
    PAUEnsureDirectoryAtPath([directoryPath stringByAppendingPathComponent:@"originals/"]);
    [_pathToContainerDictionary setObject:[directoryPath stringByAppendingPathComponent:@"originals/"] forKey:[NSString stringWithFormat:@"%0.fx%0.f", 0.0, 0.0]];
    
    //find what is inside
    NSURL *directoriesURL = [NSURL fileURLWithPath:directoryPath isDirectory:YES];
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:directoriesURL
                                                             includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                                                options:0
                                                                           errorHandler:^(NSURL *url, NSError *error) { return YES; }];
    
    //Check if cache directories exists and add it to dic, if not, creates one by default (images/originals)
    NSURL *url = nil;
    while(url = [enumerator nextObject]) {
        NSError *error = nil;
        NSNumber *isDirectory = nil;
        
        if ([url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error] && [isDirectory boolValue]) {
            NSString *subPath = [[[url path] stringByStandardizingPath] substringFromIndex:[[directoryPath stringByStandardizingPath] length]];
            if([subPath hasPrefix:@"/resized/"]) {
                [_pathToContainerDictionary setObject:[directoryPath stringByAppendingPathComponent:subPath] forKey:[url lastPathComponent]];
            }
        }
    }
    
    _downloadImageQueue = [[NSOperationQueue alloc] init];
    
    return self;
}

#pragma mark == DATA ACCESS ==
/* Single access, result is always through the block that may come instantaneously or not if a download is needed */
- (void)imageForURL:(NSURL *)url size:(CGSize)desiredImageSize  mode:(UIViewContentMode)mode availableBlock:(PAUImageCacheImageAvailableBlock)availableBlock
{
    PAULog(PAUIMAGECACHELOGENABLED, @"[PAUIMAGECACHE] Asking for image for %@", [url absoluteString]);
    NSString *tmpKey = [self _keyForIdentifier:[url absoluteString]];
    NSData *localData = [self _localDataForKey:tmpKey andSize:desiredImageSize];
    
    //local data == at least original but may imply a transformation
    if(localData) {
        UIImage *tmpImage = [UIImage imageWithData:localData];
        dispatch_async(dispatch_get_main_queue(),^{
            availableBlock(tmpImage);//Direct returns, image with right size is here
        });
    } else if([@[@"http",@"https"] containsObject:[url scheme]]){
        PAULog(PAUIMAGECACHELOGENABLED, @"[PAUIMAGECACHE] --> Download image");
        //Download original image, resize it and store it
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url] queue:_downloadImageQueue completionHandler:^(NSURLResponse* response, NSData* data, NSError* connectionError) {
            NSInteger errorCode = ((NSHTTPURLResponse*)response).statusCode;
            if (!data || 0 == [data length] ){
                PAULog(PAUIMAGECACHELOGENABLED, @"[PAUIMAGECACHE] --> image nil or empty, error %@", connectionError);
                dispatch_async(dispatch_get_main_queue(),^{
                    availableBlock(nil);
                });
            } else if (errorCode == 404) {
                 PAULog(PAUIMAGECACHELOGENABLED, @"[PAUIMAGECACHE] --> 404 not found");
                dispatch_async(dispatch_get_main_queue(),^{
                    availableBlock(nil);
                });
            } else {
                //write the original : TODO move this to asynchronous
                [self _writelocalData:data forKey:tmpKey withSize:CGSizeZero];
            }
            
            NSData *sizeData = [self _localDataForKey:tmpKey andSize:desiredImageSize];
            UIImage *tmpImage = [UIImage imageWithData:sizeData];
            dispatch_async(dispatch_get_main_queue(),^{
                availableBlock(tmpImage);
            });
        }];
    } else { //no idea abotu the scheme send back nil directly
        dispatch_async(dispatch_get_main_queue(),^{
            availableBlock(nil);
        });
    }
}

#pragma mark == LOW LEVEL MANAGEMENT ==
/* key for identifier, very often the URL string */
-(NSString*)_keyForIdentifier:(NSString*)identifier
{
    NSString *result = nil;
	if( (nil == identifier) || (0 == [identifier length]) ) {
		return result;
	}
    result = PAUMD5FromString(identifier);
    return result;
}

/* Data for an identifier: if the image does not exists with the given size but in originals, the original will be resized on the fly and returned */
- (NSData *)_localDataForKey:(NSString*)key andSize:(CGSize)desiredImageSize
{
    NSData *result = nil;
    
    /*If no size is given, look for original pic container otherwise the one of the size*/
    NSString *dictionaryKey = [NSString stringWithFormat:@"%0.fx%0.f", desiredImageSize.width, desiredImageSize.height];
    
    NSString *imagePath = [_pathToContainerDictionary[dictionaryKey] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg",  key]];
    
    result = [NSData dataWithContentsOfFile:imagePath];
    if (!result) {
        NSString *originalImageDataPath = [_pathToContainerDictionary[@"0x0"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg",key]];
        result = [self _imageWithData:[NSData dataWithContentsOfFile:originalImageDataPath] convertToSize:desiredImageSize];
        if(result) {
            [self _writelocalData:result forKey:key withSize:desiredImageSize];
        }
    }
    return result;
}

/* Save original + cropped image to local when fetched from web */
- (void)_writelocalData:(NSData *)data forKey:(NSString*)key withSize:(CGSize)desiredImageSize
{
    NSString *dictionaryKey = [NSString stringWithFormat:@"%0.fx%0.f", desiredImageSize.width, desiredImageSize.height];
    NSString *tmpCachePath = _pathToContainerDictionary[dictionaryKey];
    //if the folder does not exist this means this is a new size
    if(nil == tmpCachePath) {
        tmpCachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:[NSString stringWithFormat:@"/images/resized/%0.fx%0.f",desiredImageSize.width, desiredImageSize.height]];
        PAUEnsureDirectoryAtPath(tmpCachePath);
        _pathToContainerDictionary[dictionaryKey] = tmpCachePath;
    }
    
    [data writeToFile:[tmpCachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg",key]] atomically:YES];
    
}

/* Convert image to given size*/
- (NSData *)_imageWithData:(NSData *)data convertToSize:(CGSize)size {
    if(nil == data) return nil;
    UIImage *image = [UIImage imageWithData:data];
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);//0 will take the device main screen scale -> [UIScreen mainScreen].scale, and set opaque to NO keep the mask
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData *imgData = UIImageJPEGRepresentation(destImage, 1);//1 is best quality, 0 is poor quality
    
    return imgData;
}

@end
