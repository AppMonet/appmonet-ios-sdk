//
// Created by Jose Portocarrero on 11/6/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMOAdServerAdView.h"

@class DFPBannerView;
@class GADBannerView;
@class DFPInterstitial;
@class GADInterstitial;

@interface AMODfpAdView : NSObject <AMOAdServerAdView>
- (instancetype)initWithDfpBannerView:(DFPBannerView *)adView;

- (instancetype)initWithAdUnitId:(NSString *)adUnitID;

- (instancetype)initWithGadBannerView:(GADBannerView *)adview;

- (instancetype)initWithDfpInterstitial:(DFPInterstitial *)interstitial;

- (instancetype)initWithGADInterstitial:(GADInterstitial *)interstitial;

@end
