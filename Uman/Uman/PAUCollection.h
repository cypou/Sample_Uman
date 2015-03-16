/*
 *  PAUCollection.h
 *  Project : Pauser
 *
 *  Description : A collection will be an object grouping other object through
 *  their UUIDs. It can have multiple orders
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2014/10/15
 *  Copyright (c) 2014 Symille. All rights reserved.
 *
 */

@import Foundation;

#import "PAUBaseObject.h"

extern NSString *const kPAUCollectionDefaultOrder;
extern NSString *const kPAUCollectionOrderDataKey;
extern NSString *const kPAUCollectionOrderRangeKey;


@interface PAUCollection : PAUBaseObject
{
    NSMutableDictionary *_allOrders;
}

@property (nonatomic, assign) NSInteger offset;
@property (nonatomic, strong) NSString *displayIdentifier; //used to link it to something else

/* Designated initializer to create a sparse collection. Usually the backend created them */
- (id) initWithDisplayIdentifier:(NSString *)displayIdentifier;

/* New items to be added. If range overlap the newest version will be used, but a warning will be displayed in the log
 This is mainly used internally by the backend and should rarely be called directly */
- (void) addItems:(NSArray *)itemArray forRange:(NSRange)range  inOrder:(NSString *)orderName withReplaceAll:(BOOL)doReplaceAll;

/* Remove items form the collections (in all order). This is mainly used internally by the backend and should rarely be called directly */
- (void) removeItems:(NSArray *)itemArray;

/* Main query methods. Will return the items. If the collection is not topologically continuous, the returned result will be filled with nil */
- (NSArray *) itemsInOrder:(NSString *)orderName;

/* Main query methods will return the flattened range for an item. That is if we had data form 0 to 10 and then from
 15 to 25, this will return from 0 to 25 */
- (NSRange) rangeForOrder:(NSString *)orderName;


@end
