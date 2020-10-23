//
// Created by Jose Portocarrero on 12/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMOBaseManager.h"

@class AppMonetConfigurations;
@class MPAdView;
@protocol AMOAdServerWrapper;
@protocol MPAdViewDelegate;
@class MPNativeAdRequest;
@class MPInterstitialAdController;

@interface AMOSdkManager : AMOBaseManager
@property(nonatomic, strong, readonly) id <AMOAdServerWrapper> adServerWrapper;
@property (nonatomic, retain) AMOAddBidsManager *addBidsManager;

+ (void)initializeSdk:(AppMonetConfigurations *)configurations
   andAdServerWrapper:(id <AMOAdServerWrapper>)adServerWrapper andBlock:(InitializationBlock)block;

+ (AMOSdkManager *)get;

- (MPAdView *)addBids:(MPAdView *)adView andAdUnitId:(NSString *)adUnitId;

- (void)addBids:(MPAdView *)adView andAdUnitId:(NSString *)adUnitId andTimeout:(NSNumber *)timeout andOnReady:(void (^)(void))onReadyBlock;

- (void) addNativeBids:(MPNativeAdRequest *)adRequest andAdUnitId:(NSString *) adUnitId andTimeout:(NSNumber *) timeout :(void (^)(void)) onReadyBlock;

- (void)addInterstitialBids:(MPInterstitialAdController *)interstitial andAdUnitId:(NSString *)adUnitId andTimeout:(NSNumber *)timeout :(void (^)(void))onReadyBlock;


@end
