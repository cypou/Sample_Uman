/*
 *  PAUImageCache.h
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
@import UIKit;

typedef void (^PAUImageCacheImageAvailableBlock)(UIImage *image);

@interface PAUImageCache : NSObject
{
    NSOperationQueue *_downloadImageQueue;
    NSMutableDictionary *_pathToContainerDictionary;
}

/* Singleton access */
+ (PAUImageCache *)defaultCache;


/* Single access, result is always through the block that may come instantaneously or not if a download is needed */
- (void) imageForURL:(NSURL *)url size:(CGSize)imageSize mode:(UIViewContentMode)mode availableBlock:(PAUImageCacheImageAvailableBlock)availableBlock;

@end
