//
// Created by Jose Portocarrero on 1/8/20.
// Copyright (c) 2020 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMOAdServerAdRequest.h"
#import "MPNativeAdRequest.h"

@class AMOMopubAdView;

@interface AMOMopubNativeAdRequest : AMOAdServerAdRequest
@property(nonatomic, strong) NSMutableDictionary *localExtras;

- (instancetype)initWithNativeAdRequest:(MPNativeAdRequest **)adRequest;

+ (AMOMopubNativeAdRequest *)fromAuctionRequest:(AMOAuctionRequest *)request;

- (void)applyToView:(AMOMopubAdView *)adView;

@end

