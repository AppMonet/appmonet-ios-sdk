//
// Created by Jose Portocarrero on 4/16/20.
// Copyright (c) 2020 AppMonet. All rights reserved.
//

#import "AMOAddBidsManager.h"
#import "AMOAddBids.h"
#import "AMOConstants.h"

@implementation AMOAddBidsManager

- (instancetype)init {
    if (self = [super init]) {
        _readyCallbacks = [NSMutableArray array];
    }
    return self;
}

- (void)executeReady {
    @synchronized (self) {
        _isReady = YES;
        if ([_readyCallbacks count] == 0) {
            return;
        }
        for (AMOAddBids *addBids in _readyCallbacks) {
            [addBids cancelTimeout];
            addBids.block([addBids getRemainingTime], NO);
        }
        [_readyCallbacks removeAllObjects];
    }
}

- (void)onReady:(NSNumber *)timeout withBlock:(void (^)(NSNumber *remainingTime, BOOL timedOut))block {
    @synchronized (self) {
        if (_isReady) {
            if (block != nil) {
                block(timeout, NO);
            } else {
                AMLogError(@"AddBidsManager onReady block is null");
            }
            return;
        }
        AMOAddBids *addBids = [[AMOAddBids alloc] initWithAddBidsManager:self andTimeout:timeout andBlock:block];
        [_readyCallbacks addObject:addBids];
    }
}

- (void)removeAddBids:(AMOAddBids *)addBids {
    @synchronized (self) {
        [_readyCallbacks removeObject:addBids];
    }
}
@end
