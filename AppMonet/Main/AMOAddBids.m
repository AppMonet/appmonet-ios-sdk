//
// Created by Jose Portocarrero on 4/16/20.
// Copyright (c) 2020 AppMonet. All rights reserved.
//

#import "AMOAddBids.h"
#import "AMOUtils.h"
#import "AMOAddBidsManager.h"
#import "AMODispatchState.h"

@interface AMOAddBids ()
@property(nonatomic, readonly, strong) NSNumber *endingTime;
@property(atomic) BOOL isCanceled;
@property(nonatomic, readonly, strong) AMODispatchState *cancelState;
@end

@implementation AMOAddBids

- (instancetype)initWithAddBidsManager:(AMOAddBidsManager *)addBidsManager andTimeout:(NSNumber *)timeout
                              andBlock:(void (^)(NSNumber *remainingTime, BOOL timedOut))block {
    if (self = [super init]) {
        _block = block;
        _endingTime = @([self getCurrentTime].integerValue + timeout.integerValue);
        _cancelState = [[AMODispatchState alloc] init];
        [AMOUtils cancelableDispatchAfter:dispatch_time(DISPATCH_TIME_NOW, (int64_t) (timeout.intValue * NSEC_PER_MSEC))
                                  inQueue:dispatch_get_main_queue() withState:_cancelState withBlock:^{
                    [addBidsManager removeAddBids:self];
                    if (self.isCanceled) {
                        return;
                    }
                    [self cancelTimeout];
                    block(@0, YES);
                }];
    }
    return self;
}

- (void)cancelTimeout {
    self.isCanceled = YES;
    self.cancelState.isCancelled = YES;
}

- (NSNumber *)getRemainingTime {
    NSNumber *remainingTime = @(_endingTime.integerValue - [self getCurrentTime].integerValue);
    NSNumber *finalTime = (remainingTime.integerValue < 0) ? @(0) : remainingTime;
    return finalTime;
}

- (NSNumber *)getCurrentTime {
    return [AMOUtils getCurrentMillis];
}

@end
