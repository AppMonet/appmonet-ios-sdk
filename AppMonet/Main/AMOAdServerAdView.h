//
// Created by Jose Portocarrero on 11/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMOAdServerWrapper.h"

@class AMOAdServerAdRequest;
@protocol AMServerAdRequest;

@protocol AMOAdServerAdView <NSObject>
- (NSString *)getAdUnitId;

- (AMType)getType;

- (void)setAdUnitId:(NSString *)adUnitId;

- (void)loadAd:(id <AMServerAdRequest>)request;

@end
