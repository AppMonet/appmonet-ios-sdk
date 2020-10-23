//
// Created by Jose Portocarrero on 12/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMOAdServerAdView.h"

@class MPAdView;
@class MPNativeAdRequest;
@class MPInterstitialAdController;

@interface AMOMopubAdView : NSObject <AMOAdServerAdView>
- (instancetype)initWithMopubView:(MPAdView *)adView;

- (instancetype)initWithInterstitial:(MPInterstitialAdController *)interstitial;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId andNativeAdRequest:(MPNativeAdRequest *)adRequest;

- (MPAdView *)getMopubView;

- (void)setAdUnitId:(NSString *)adUnitId;

- (MPNativeAdRequest *)getNativeAdRequest;

- (MPInterstitialAdController *)getInterstitialAdController;

@end
