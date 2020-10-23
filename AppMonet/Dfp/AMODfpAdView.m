//
// Created by Jose Portocarrero on 11/6/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMODfpAdView.h"
#import "AMODfpAdSize.h"
#import "AMOAdServerAdRequest.h"
@import GoogleMobileAds;

@implementation AMODfpAdView {
    DFPBannerView *_adView;
    NSString *_adUnitId;
    AMType type;
}
- (instancetype)initWithDfpBannerView:(DFPBannerView *)adView {
    self = [super init];
    if (self != nil) {
        _adView = adView;
        _adUnitId = adView.adUnitID;
        type = kAMBanner;
    }
    return self;
}

- (instancetype)initWithAdUnitId:(NSString *)adUnitID {
    self = [super init];
    if (self != nil) {
        _adUnitId = adUnitID;
    }
    return self;
}

- (instancetype)initWithGadBannerView:(GADBannerView *)adView {
    self = [super init];
    if (self != nil) {
        _adView = nil;
        _adUnitId = adView.adUnitID;
        type = kAMBanner;
    }
    return self;
}

- (instancetype)initWithGADInterstitial:(GADInterstitial *)interstitial{
    self = [super init];
    if (self != nil) {
        _adView = nil;
        _adUnitId = interstitial.adUnitID;
        type = kAMInterstitial;
    }
    return self;
}

- (instancetype)initWithDfpInterstitial:(DFPInterstitial *)interstitial {
    self = [super init];
    if (self != nil) {
        _adView = nil;
        _adUnitId = interstitial.adUnitID;
        type = kAMInterstitial;
    }

    return self;
}

- (NSString *)getAdUnitId {
    return _adUnitId;
}

- (AMType)getType {
    return type;
}

- (void)setAdUnitId:(NSString *)adUnitId {
    _adUnitId = adUnitId;
}

- (void)loadAd:(id <AMServerAdRequest>)request {

}

@end
