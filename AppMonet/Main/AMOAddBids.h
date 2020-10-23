//
// Created by Jose Portocarrero on 4/16/20.
// Copyright (c) 2020 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AMOAddBidsManager;


@interface AMOAddBids : NSObject
@property(nonatomic, readonly, copy) void (^block)(NSNumber *, BOOL);

- (instancetype)initWithAddBidsManager:(AMOAddBidsManager *)addBidsManager andTimeout:(NSNumber *)timeout
                              andBlock:(void (^)(NSNumber *remainingTime, BOOL timedOut))block;

- (void)cancelTimeout;

- (NSNumber *)getRemainingTime;

@end