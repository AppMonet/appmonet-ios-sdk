//
//  AMOReadyCallbackManager.m
//  AppMonet
//
//  Created by Jose Portocarrero on 4/3/20.
//  Copyright © 2020 AppMonet. All rights reserved.
//

#import "AMOReadyCallbackManager.h"

@interface AMOReadyCallbackManager ()
@property(atomic, readonly) NSMutableArray *readyCallbacks;
@property(atomic) id instance;
@property(atomic) BOOL isReady;
@end

@implementation AMOReadyCallbackManager

- (instancetype)init {
    if (self = [super init]) {
        _readyCallbacks = [NSMutableArray array];
    }
    return self;
}

- (void)executeReady:(id)instance {
    @synchronized (self) {
        self.instance = instance;
        _isReady = YES;
        if ([_readyCallbacks count] == 0) {
            return;
        }

        for (void(^block)(id) in _readyCallbacks){
            block(instance);
        }
        [_readyCallbacks removeAllObjects];
    }
}

-(void) onReady:(void(^)(id instance)) block{
    @synchronized(self) {
        if (_isReady) {
            block(_instance);
            return;
        }
        [_readyCallbacks addObject:block];
    }
}

@end
