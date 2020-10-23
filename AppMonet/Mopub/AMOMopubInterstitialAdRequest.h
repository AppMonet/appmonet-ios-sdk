//
// Created by Jose Portocarrero on 1/9/20.
// Copyright (c) 2020 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMOAdServerAdRequest.h"

@class MPInterstitialAdController;
@class AMOMopubAdView;

@interface AMOMopubInterstitialAdRequest : AMOAdServerAdRequest
@property(nonatomic, strong) NSMutableDictionary *localExtras;

- (instancetype)initWithInterstitialAdController:(MPInterstitialAdController **)interstitial;

+ (AMOMopubInterstitialAdRequest *)fromAuctionRequest:(AMOAuctionRequest *)request;

- (void)applyToInterstitial:(AMOMopubAdView *)adView;


@end