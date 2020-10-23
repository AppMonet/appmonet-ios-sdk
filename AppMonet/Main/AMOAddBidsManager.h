//
// Created by Jose Portocarrero on 4/16/20.
// Copyright (c) 2020 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AMOAddBids;

@interface AMOAddBidsManager : NSObject
@property(atomic, readonly) NSMutableArray *readyCallbacks;
@property(atomic) BOOL isReady;

- (void)executeReady;

- (void)onReady:(NSNumber *)timeout withBlock:(void (^)(NSNumber *remainingTime, BOOL timedOut))block;

- (void)removeAddBids:(AMOAddBids *)addBids;

@end