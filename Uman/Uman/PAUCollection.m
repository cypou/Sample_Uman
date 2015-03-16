/*
 *  PAUCollection.m
 *  Project : Pauser
 *
 *  Description : A collection will be an object grouping other object through
 *  their UUIDs. It can have multiple orders. Although special the collection is
 *  a PAUBaseObject
 *
 *  DRI     : Laurent Cerveau
 *  Created : 2014/10/15
 *  Copyright (c) 2014 Symille. All rights reserved.
 *
 */

@import Foundation;

#import "PAUBaseObject.h"
#import "PAUCollection.h"

#define PAUCOLLECTIONLOG YES && PAUGLOBALLOGENABLED

NSString *const kPAUCollectionDefaultOrder = @"PAUCollectionDefaultOrder";
NSString *const kPAUCollectionOrderDataKey = @"PAUCollectionOrderDataKey";
NSString *const kPAUCollectionOrderRangeKey = @"PAUCollectionOrderRangeKey";


@implementation PAUCollection

@synthesize offset = _offset;

/* Designated initializer to create a sparse collection. Usually the backend created them */
- (id) initWithDisplayIdentifier:(NSString *)displayIdentifier
{
    self = [super initWithUUID:nil];
    if(self){
        self.displayIdentifier = displayIdentifier;
    }
    return self;
}

/* Register towards to the base class */
+ (void)load
{
    [PAUBaseObject registerClass:NSStringFromClass([self class]) forType:kPAUObjectTypeCollection JSONClassName:@"collection"];
}

+ (NSString *) uuidPrefix
{
    return @"collection";
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<PAUCollection:%p - %@ - %@>", self, self.uuid, self.displayIdentifier];
}

/* Additon of items */
- (void) addItems:(NSArray *)itemArray forRange:(NSRange)range inOrder:(NSString *)orderName withReplaceAll:(BOOL)doReplaceAll
{
    //the caller is responsible for passing "coherent" data
    if((nil == itemArray) || (0 == [itemArray count])) return;
    if((range.location != NSNotFound) && (range.length != [itemArray count])) {
        return;
    }
    
    if(nil == orderName)
        orderName= kPAUCollectionDefaultOrder;

    if(nil == _allOrders) {
        _allOrders = [[NSMutableDictionary alloc] init];
    }
    
    NSMutableDictionary *orderCollectionInformation = _allOrders[orderName];
    if(nil == orderCollectionInformation) {
        orderCollectionInformation = [NSMutableDictionary dictionaryWithObject:[NSMutableArray array] forKey:kPAUCollectionOrderDataKey];
        [_allOrders setObject:orderCollectionInformation forKey:orderName];
    } else {
        if(nil == [orderCollectionInformation objectForKey:kPAUCollectionOrderDataKey]) {
            [orderCollectionInformation setObject:[NSMutableArray array] forKey:kPAUCollectionOrderDataKey];
        }
    }
    
    //if we replace all then...we remove everythig
    NSMutableArray *tmpArray = [orderCollectionInformation objectForKey:kPAUCollectionOrderDataKey];
    if(doReplaceAll) {
        [tmpArray removeAllObjects];
    }
    
    /* Now we will add the items. We do make the hypothesis that any order has no duplicates.
     The first step is to compute the real final range
     We do receive a range [nobj1... nobjN]. we have in the data [obj1... objP]. we do the following.
     - First we check if the passed data has a intersection with inside data. If we have we do adjus the passed range
     - Then we compute the final total range. We do have first [loc, len] and we add [loc1, len1].So
     if (loc1 > loc+len) fill the data with 0 to reach loc and then the data
     else we end up with loc+len-loc1+len1*/
    NSUInteger tmpLength = [tmpArray count];
    NSRange currentCoverage = NSMakeRange(0, tmpLength);
    NSRange intersectionRange = NSIntersectionRange(currentCoverage, range);

    
    NSMutableSet *commonObjects = [NSMutableSet setWithArray:tmpArray];
    if([commonObjects containsObject:(id)kCFNull]) { [commonObjects removeObject:(id)kCFNull]; };
    [commonObjects intersectSet:[NSSet setWithArray:itemArray]];

    if(0 == intersectionRange.length) {
        if( 0 == [commonObjects count]) {
            // NSUInteger firstPos = range.location;
            NSMutableArray *realObjectToAdd = [NSMutableArray array];
            for(NSString *anID in itemArray) {
                if(![tmpArray containsObject:anID]) {
                    [realObjectToAdd addObject:anID];
                }
            }
            if(0 != [realObjectToAdd count]) {
                [self insertItems:realObjectToAdd atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange([tmpArray count], [realObjectToAdd count])]];
            }
        } else {
            for(NSString *anID in itemArray) {
                if(![tmpArray containsObject:anID]) {
                    [tmpArray addObject:anID];
                }
            }
        }
    } else {
        if( 0 == [commonObjects count]) {
            [self insertItems:itemArray atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [itemArray count])]];
        } else {
            
        }
    }
    BOOL hasNewItem = NO;
#pragma unused(hasNewItem)
    
    NSRange tmpRange = NSMakeRange(0, [tmpArray count]);
    [orderCollectionInformation setObject:[NSValue valueWithRange:tmpRange] forKey:kPAUCollectionOrderRangeKey];
}

/* Nil remove all */
- (void) removeItems:(NSArray *)itemArray
{
    if(nil == itemArray) {
        for(NSString *anOrder in _allOrders) {
            [(NSMutableArray *)[_allOrders objectForKey:anOrder] removeAllObjects];
        }
    } else {
        for(NSString *anOrder in _allOrders) {
            if(NO == [anOrder isEqualToString:kPAUCollectionDefaultOrder]) {
                NSMutableArray *newArray = [[[_allOrders objectForKey:anOrder] objectForKey:kPAUCollectionOrderDataKey] mutableCopy];
                for(NSString *anItemUUID in itemArray) {
                    [newArray removeObject:anItemUUID];
                }
                if(newArray) {
                    [[_allOrders objectForKey:anOrder] setObject:newArray forKey:kPAUCollectionOrderDataKey];
                }
            } else {
                NSMutableIndexSet *tmpIndexSet = [[NSMutableIndexSet alloc] init];
                NSMutableArray *tmpArray = [[_allOrders objectForKey:anOrder] objectForKey:kPAUCollectionOrderDataKey];
                [itemArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    NSUInteger tmpIndex = [tmpArray indexOfObject:obj];
                    if(NSNotFound != tmpIndex) {
                        [tmpIndexSet addIndex:tmpIndex];
                    }
                }];
                [self removeItemsAtIndexes:tmpIndexSet];
                
            }
        }
        for(NSString *anOrder in _allOrders) {
            NSArray *tmpArray = [[_allOrders objectForKey:anOrder] objectForKey:kPAUCollectionOrderDataKey];
            NSRange tmpRange = NSMakeRange(0, [tmpArray count]);
            [[_allOrders objectForKey:anOrder] setObject:[NSValue valueWithRange:tmpRange] forKey:kPAUCollectionOrderRangeKey];
        }
    }
}

/* Get the items for a given order */
- (NSArray *) itemsInOrder:(NSString *)orderName
{
    if(nil == orderName)
        orderName= kPAUCollectionDefaultOrder;
    
    NSInteger length = [[[_allOrders objectForKey:orderName] objectForKey:kPAUCollectionOrderDataKey] count];
    return ([[[_allOrders objectForKey:orderName] objectForKey:kPAUCollectionOrderDataKey] objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(_offset, length - _offset)]]);
}

/* Get the range for a given order */
- (NSRange) rangeForOrder:(NSString *)orderName
{
    if(nil == orderName)
        orderName= kPAUCollectionDefaultOrder;
    
    return ([[[_allOrders objectForKey:orderName] objectForKey:kPAUCollectionOrderRangeKey] rangeValue]);
}

#pragma mark == KVC/KVO on collections ==
/* For now first level we need to add a keypath for the order */
/* KVC/KVO compliance : for items for now we do not consider the order*/
- (NSUInteger) countOfItems
{
    return [[[_allOrders objectForKey:kPAUCollectionDefaultOrder] objectForKey:kPAUCollectionOrderDataKey] count];
}

/* KVC/KVO compliance : for items for now we do not consider the order*/
- (id)objectInItemsAtIndex:(NSUInteger)index {
    return [[[_allOrders objectForKey:kPAUCollectionDefaultOrder] objectForKey:kPAUCollectionOrderDataKey] objectAtIndex:index];
}

/* KVC/KVO compliance : for items for now we do not consider the order*/
-(NSArray *)itemsAtIndexes:(NSIndexSet *)indexes {
    return([[[_allOrders objectForKey:kPAUCollectionDefaultOrder] objectForKey:kPAUCollectionOrderDataKey] objectsAtIndexes:indexes]);
}

/*KVO/KVC compliance mutable ordered collection */
- (void)insertObject:(NSString *)itemUUID inItemsAtIndex:(NSUInteger)index
{
    if(itemUUID) {
        [[[_allOrders objectForKey:kPAUCollectionDefaultOrder] objectForKey:kPAUCollectionOrderDataKey] insertObject:itemUUID atIndex:index];
    }
}

/*KVO/KVC compliance mutable ordered collection */
- (void)insertItems:(NSArray *)itemUUIDs atIndexes:(NSIndexSet *)indexSet
{
     [[[_allOrders objectForKey:kPAUCollectionDefaultOrder] objectForKey:kPAUCollectionOrderDataKey] insertObjects:itemUUIDs atIndexes:indexSet];
}

/*KVO/KVC compliance mutable ordered collection */
-(void)removeObjectFromItemsAtIndex:(NSUInteger)index {
    [[[_allOrders objectForKey:kPAUCollectionDefaultOrder] objectForKey:kPAUCollectionOrderDataKey] removeObjectAtIndex:index];
}

/*KVO/KVC compliance mutable ordered collection */
-(void)removeItemsAtIndexes:(NSIndexSet *)indexSet
{
    [[[_allOrders objectForKey:kPAUCollectionDefaultOrder] objectForKey:kPAUCollectionOrderDataKey] removeObjectsAtIndexes:indexSet];
}

/*KVO/KVC compliance mutable ordered collection */
-(void) replaceObjectInItemsAtIndex:(NSUInteger) index withObject:(NSString *)itemUUID
{
    [[[_allOrders objectForKey:kPAUCollectionDefaultOrder] objectForKey:kPAUCollectionOrderDataKey] replaceObjectAtIndex:index withObject:itemUUID];
}

@end
