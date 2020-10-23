//
//  AMOBasicValidityCallback.m
//  AppMonet
//
//  Created by Jose Portocarrero on 12/7/17.
//  Copyright © 2017 AppMonet. All rights reserved.
//

#import "AMOBasicValidityCallback.h"
#import "AMOBidManager.h"

@implementation AMOBasicValidityCallback {
    AMOBidManager *_bidManager;
}

- (instancetype)initWithBidManager:(AMOBidManager *)bidManager {
    self = [super init];
    if (self) {
        _bidManager = bidManager;
    }
    return self;
}

- (BOOL)isValid:(AMOBidResponse *)bid {
    return [_bidManager isValid:bid];
}

@end
