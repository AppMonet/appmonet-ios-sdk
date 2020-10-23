//
// Created by Jose Portocarrero on 12/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMOSdkManager.h"
#import "AppMonetConfigurations.h"
#import "AMOConstants.h"
#import "AMOMopubAdView.h"
#import <MoPub/MPAdView.h>
#import "AMOAppMonetBidder.h"
#import "AMOMopubAdRequest.h"
#import "AMOMopubBannerAdListener.h"
#import "MPNativeAdRequest.h"
#import "AMOMopubNativeAdRequest.h"
#import "AMOMopubInterstitialAdRequest.h"
#import "AMOAddBidsManager.h"

@implementation AMOSdkManager
static AMOSdkManager *_instance;
static AppMonetConfigurations *_appMonetConfigurations;

#pragma mark - Public Methods -
#pragma mark Inherited Methods

- (id)initWithApplicationId:(AppMonetConfigurations *)appMonetConfigurations andAdServerWrapper:(id <AMOAdServerWrapper>)adServerWrapper andBlock:(InitializationBlock)block {
    self = [super initWithApplicationId:appMonetConfigurations andAdServerWrapper:adServerWrapper andBlock:block];
    _appMonetConfigurations = appMonetConfigurations;
    return self;
}

#pragma mark Static Methods

+ (void)initializeSdk:(AppMonetConfigurations *)configurations
   andAdServerWrapper:(id <AMOAdServerWrapper>)adServerWrapper andBlock:(InitializationBlock)block {
    @synchronized (self) {
        if (_instance) {
            AMLogWarn(@"Sdk has already been initialized. No need to initialize it again.");
            return;
        }
        _instance = [[self alloc] initWithApplicationId:configurations andAdServerWrapper:adServerWrapper andBlock:block];
    }
}

+ (AMOSdkManager *)get {
    @synchronized (self) {
        return _instance;
    }
}

- (MPAdView *)addBids:(MPAdView *)adView andAdUnitId:(NSString *)adUnitId {
    if (adView == nil) {
        AMLogWarn(@"attempt to add bids to nonexistent AdView");
        return nil;
    }

    if (adView.adUnitId == nil) {
        AMLogWarn(@"Mopub adunit id is null. Unable to fetch bids for unit");
        return adView;
    }

    AMOMopubAdView *mpView = [[AMOMopubAdView alloc] initWithMopubView:adView];

    if (!([adUnitId isEqualToString:adView.adUnitId])) {
        [mpView setAdUnitId:adUnitId];
    }

    id <AMServerAdRequest> baseRequest;
    [self registerView:adView andAdUnitId:adUnitId];
    id <AMServerAdRequest> request;
    baseRequest = [[AMOMopubAdRequest alloc] initWithMoPubView:adView];
    request = [self.appMonetBidder addBids:mpView andAdServerAdRequest:baseRequest];

    if (request != nil) {
        [((AMOMopubAdRequest *) request) applyToView:mpView];
    }
    return mpView.getMopubView;
}

- (void)addBids:(MPAdView *)adView andAdUnitId:(NSString *)adUnitId andTimeout:(NSNumber *)timeout andOnReady:(void (^)(void))onReadyBlock {
    __weak typeof(self) weakSelf = self;
    [self.addBidsManager onReady:timeout withBlock:^(NSNumber *remainingTime, BOOL timedOut) {
        typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            if (timedOut) {
                [strongSelf trackTimeoutEvent:adUnitId withTimeout:timeout];
                onReadyBlock();
                return;
            }
            if ([strongSelf isAppMonetBidderNil:onReadyBlock]) {
                return;
            }
            AMOMopubAdView *mpView = [[AMOMopubAdView alloc] initWithMopubView:adView];
            if ([adView adUnitId] == nil) {
                AMLogDebug(@"Mopub adunit id is null. Unable to fetch bids for unit");
                onReadyBlock();
                return;
            }

            if (!([[adView adUnitId] isEqualToString:adUnitId])) {
                [mpView setAdUnitId:adUnitId];
            }

            [strongSelf registerView:adView andAdUnitId:adUnitId];

            [strongSelf.appMonetBidder addBids:mpView andAdServerAdRequest:[[AMOMopubAdRequest alloc] initWithMoPubView:adView]
                                    andTimeout:remainingTime andExecutionQueue:strongSelf.backgroundQueue andValueBlock:^(id <AMServerAdRequest> value) {
                        AMOMopubAdRequest *request = (AMOMopubAdRequest *) value;
                        [request applyToView:mpView];
                        onReadyBlock();
                    }];
        } else {
            onReadyBlock();
        }
    }];
}

- (void)addNativeBids:(MPNativeAdRequest *)adRequest andAdUnitId:(NSString *)adUnitId andTimeout:(NSNumber *)timeout :(void (^)(void))onReadyBlock {
    if ([self isAppMonetBidderNil:onReadyBlock]) {
        return;
    }
    AMOMopubNativeAdRequest *mpRequest = [[AMOMopubNativeAdRequest alloc] initWithNativeAdRequest:&adRequest];
    __weak typeof(self) weakSelf = self;
    [self.addBidsManager onReady:timeout withBlock:^(NSNumber *remainingTime, BOOL timedOut) {
        typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            if (timedOut) {
                [strongSelf trackTimeoutEvent:adUnitId withTimeout:timeout];
                onReadyBlock();
                return;
            }
            AMOMopubAdView *mpView = [[AMOMopubAdView alloc] initWithAdUnitId:adUnitId andNativeAdRequest:adRequest];
            [strongSelf.appMonetBidder addBids:mpView andAdServerAdRequest:mpRequest andTimeout:remainingTime
                             andExecutionQueue:strongSelf.backgroundQueue andValueBlock:^(id <AMServerAdRequest> value) {
                        AMOMopubNativeAdRequest *request = (AMOMopubNativeAdRequest *) value;
                        [request applyToView:mpView];
                        onReadyBlock();
                    }];
        } else {
            onReadyBlock();
        }
    }];
}

- (void)addInterstitialBids:(MPInterstitialAdController *)interstitial andAdUnitId:(NSString *)adUnitId andTimeout:(NSNumber *)timeout :(void (^)(void))onReadyBlock {
    if ([self isAppMonetBidderNil:onReadyBlock]) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    AMOMopubInterstitialAdRequest *mpRequest = [[AMOMopubInterstitialAdRequest alloc] initWithInterstitialAdController:&interstitial];
    [self.addBidsManager onReady:timeout withBlock:^(NSNumber *remainingTime, BOOL timedOut) {
        typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            if (timedOut) {
                [strongSelf trackTimeoutEvent:adUnitId withTimeout:timeout];
                onReadyBlock();
                return;
            }
            AMOMopubAdView *mpView = [[AMOMopubAdView alloc] initWithInterstitial:interstitial];
            [strongSelf.appMonetBidder addBids:mpView andAdServerAdRequest:mpRequest andTimeout:remainingTime
                             andExecutionQueue:strongSelf.backgroundQueue andValueBlock:^(id <AMServerAdRequest> value) {
                        AMOMopubInterstitialAdRequest *request = (AMOMopubInterstitialAdRequest *) value;
                        [request applyToInterstitial:mpView];
                        onReadyBlock();
                    }];
        } else {
            onReadyBlock();
        }
    }];
}

- (void)registerView:(MPAdView *)adView andAdUnitId:(NSString *)adUnitIdAlias {
    if (adView == nil) return;

    NSString *adUnitId = adUnitIdAlias == nil ? [adView adUnitId] : adUnitIdAlias;
    if (adUnitId == nil) {
        return;
    }

    id <MPAdViewDelegate> delegate = [adView delegate];
    if (![delegate isKindOfClass:[AMOMopubBannerAdListener class]] && [adView adUnitId] != nil && !_appMonetConfigurations.disableBannerListener) {
        AMLogDebug(@"registering view with internal listener: %@", adUnitId);
        [adView setDelegate:[[AMOMopubBannerAdListener alloc] initWithAdUnitId:adUnitId andMopubAdViewDelegate:delegate andSdkmanager:self]];
    }
}

#pragma mark - Private methods -

- (BOOL)isAppMonetBidderNil:(void (^)(void))onReadyBlock {
    if (self.appMonetBidder == nil) {
        onReadyBlock();
        return YES;
    }
    return NO;
}


@end
