//
// Created by Jose Portocarrero on 12/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "MPAdView.h"
#import "AMOMopubAdView.h"
#import "AMOMopubAdRequest.h"
#import "MPInterstitialAdController.h"

@interface AMOMopubAdView () <AMOAdServerAdView>
@property(nonatomic, weak) MPAdView *adView;
@property(nonatomic, weak) MPInterstitialAdController *interstitial;
@property(nonatomic, strong) NSString *adUnitId;
@property(nonatomic, strong) MPNativeAdRequest *adRequest;
@property(nonatomic, assign) AMType type;

@end

@implementation AMOMopubAdView

- (instancetype)initWithMopubView:(MPAdView *)adView {
    self = [super init];
    if (self != nil) {
        _adView = adView;
        _adUnitId = [adView adUnitId];
        _type = kAMBanner;
    }
    return self;
}

- (instancetype)initWithAdUnitId:(NSString *)adUnitId andNativeAdRequest:(MPNativeAdRequest *)adRequest {
    if (self = [super init]) {
        _adUnitId = adUnitId;
        _adRequest = adRequest;
        _type = kAMNative;
    }
    return self;
}

- (instancetype)initWithInterstitial:(MPInterstitialAdController *)interstitial {
    if (self = [super init]) {
        _adUnitId = [interstitial adUnitId];
        _interstitial = interstitial;
        _type = kAMInterstitial;
    }
    return self;
}


- (MPAdView *)getMopubView {
    return _adView;
}

- (MPNativeAdRequest *)getNativeAdRequest {
    return _adRequest;
}

- (MPInterstitialAdController *)getInterstitialAdController {
    return _interstitial;
}

- (NSString *)getAdUnitId {
    return _adUnitId;
}

- (AMType)getType {
    return _type;
}

- (void)setAdUnitId:(NSString *)adUnitId {
    _adUnitId = adUnitId;
}

- (void)loadAd:(id <AMServerAdRequest>)request {
    [_adView loadAd];
}

@end
