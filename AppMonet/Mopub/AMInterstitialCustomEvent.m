//
//  AMInterstitialCustomEvent.m
//  AppMonet_Mopub
//
//  Created by Jose Portocarrero on 3/27/18.
//  Copyright © 2018 AppMonet. All rights reserved.
//

#import "AMInterstitialCustomEvent.h"
#import "AMOConstants.h"
#import "AMOBidResponse.h"
#import "AMOBidManager.h"
#import "AMOSdkManager.h"
#import "AMOBidRenderer.h"
#import "AMOInterstitialViewController.h"
#import "AMCustomEventUtil.h"
#import "AMOAppMonetViewLayout.h"
#import "AMOMediationManager.h"
#import "AMOUtils.h"

#import "MoPub.h"

@interface AMInterstitialCustomEvent () <AMOAdViewDelegate, AMOAdServerAdapter, AMInterstitialViewControllerDelegate>
@property(nonatomic, strong) AMOSdkManager *sdkManager;
@property(nonatomic, copy) NSString *appMonetAdUnitId;

@property(nonatomic, weak) AMOAppMonetViewLayout *adView;
@property(nonatomic, strong) AMOInterstitialViewController *appMonetInterstitial;
@property(nonatomic) BOOL adLoaded;

@end

@implementation AMInterstitialCustomEvent

@synthesize localExtras;

- (void)adView:(AMOAdView *)adView adError:(AMErrorCode)error {
    if (_adLoaded) {
        AMLogWarn(@"already loaded -- will not failLoad now");
        return;
    }
    NSString *errorValue = errorCodeValueString(error);
    [self onError:errorValue];
}

- (void)adView:(AMOAdView *)adView wasClicked:(NSURL *)url {
    MPLogAdEvent([MPLogEvent adTappedForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterDidReceiveTap:self];
    [self.delegate fullscreenAdAdapterDidTrackClick:self];
}

- (void)adView:(AMOAdView *)ad_view willLeaveApplication:(NSURL *)url {
    MPLogAdEvent([MPLogEvent adWillLeaveApplicationForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterWillLeaveApplication:self];
}

- (void)adView:(AMOAdView *)ad_view willReturnToApplication:(NSURL *)url {
    // do nothing
}

- (void)adView:(AMOAppMonetViewLayout *)ad_view adLoaded:(AMOBidResponse *)bid {
    _adLoaded = YES;
    MPLogAdEvent([MPLogEvent adLoadSuccessForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterDidLoadAd:self];
}

- (void)adClosed {
    [_appMonetInterstitial dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - <AMAdServerAdapter>

- (id <AMOAdViewDelegate>)getDelegate {
    return self;
}

- (void)setAppMonetAdView:(AMOAppMonetViewLayout *)adView {
    _adView = adView;
}

#pragma mark - <AMInterstitialViewControllerDelegate>

- (NSString *)adUnitId {
    return _adView.adView.getUUID;
}

- (void)interstitialWillAppear:(AMOInterstitialViewController *)interstitial {
    MPLogAdEvent([MPLogEvent adWillAppearForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterAdWillAppear:self];
}

- (void)interstitialDidAppear:(AMOInterstitialViewController *)interstitial {
    MPLogAdEvent(MPLogEvent.adShowSuccess, self.getAdNetworkId);
    MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adDidAppearForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterAdDidAppear:self];
    [self.delegate fullscreenAdAdapterDidTrackImpression:self];
}

- (void)interstitialWillDisappear:(AMOInterstitialViewController *)interstitial {
    MPLogAdEvent([MPLogEvent adWillDisappearForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterAdWillDisappear:self];
}

- (void)interstitialDidDisappear:(AMOInterstitialViewController *)interstitial {
    MPLogAdEvent([MPLogEvent adDidDisappearForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterAdDidDisappear:self];
}

#pragma mark - MPFullscreenAdAdapter Override

- (BOOL)isRewardExpected {
    return NO;
}

- (BOOL)hasAdAvailable {
    return _adLoaded;
}

- (BOOL)enableAutomaticImpressionAndClickTracking {
    return NO;
}

- (void)requestAdWithAdapterInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
    AMLogDebug(@"requestInterstitialWithCustomEventInfo");

    if (![self isSdkManagerAvailable]) {
        return;
    }

    AMOAdSize *size = [[AMOAdSize alloc] initWithWidth:@(kAMOInterstitialWidth) andHeight:@(kAMOInterstitialHeight)];
    _appMonetAdUnitId = [AMCustomEventUtil getAdUnit:info fromLocalExtras:self.localExtras withAdSize:size];
    if (![self isAdUnitIdConfigured:_appMonetAdUnitId]) {
        return;
    }
    [[_sdkManager auctionManager] trackRequest:_appMonetAdUnitId andSource:[AMOUtils getCustomEventSourceType:INTERSTITIAL]];

    AMOBidManager *bidManager = [[AMOSdkManager get] bidManager];
    NSNumber *floorCpm = [AMCustomEventUtil getCpm:info];
    AMOBidResponse *bid = [AMCustomEventUtil getBidFromLocalExtras:localExtras];

    if (bid == nil) {
        bid = [bidManager getBidForMediation:_appMonetAdUnitId andAdSize:size andFloorCpm:floorCpm andAdType:INTERSTITIAL andShouldIndicateRequest:NO];
    }

    [_sdkManager.mediationManager getBidReadyForMediationAsync:bid withAdUnit:_appMonetAdUnitId andAdSize:size andFloorCpm:floorCpm andAdType:INTERSTITIAL andBlock:^(AMOBidResponse *response, NSError *error) {
        if (error) {
            [self onError:error.description];
            return;
        }
        _adView = [AMOBidRenderer renderBid:response andAdSize:nil andAdServerAdapter:self];
        if (_adView == nil) {
            AMLogError(@"unexpected: could not generate the adView");
            [self onError:@"Unable to serve due to invalid adView"];
        }
    }];
}

- (NSString *)getAdNetworkId {
    return _appMonetAdUnitId;
}

- (void)presentAdFromViewController:(UIViewController *)viewController {
    MPLogAdEvent([MPLogEvent adShowAttemptForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    _appMonetInterstitial = [[AMOInterstitialViewController alloc] init];
    _appMonetInterstitial.delegate = self;
    [_appMonetInterstitial presentInterstitialFromViewController:viewController complete:nil];
}

#pragma  mark - Clean up

- (void)dealloc {
    @autoreleasepool {
        if (_adView) {
            [_adView invalidateView:YES withDelegate:self];
            _adView = nil;
        }
        _sdkManager = nil;
    }
}

#pragma mark - Private Methods

- (BOOL)isAdUnitIdConfigured:(NSString *)adUnitId {
    if (adUnitId == nil || [adUnitId length] == 0) {
        AMLogDebug(@"no adUnit/tagId: floor line item configured incorrectly");
        [self onError:@"Unable to serve ad due to misconfigured adUnit."];
        return NO;
    }
    return YES;
}

- (BOOL)isSdkManagerAvailable {
    _sdkManager = [AMOSdkManager get];
    if (_sdkManager == nil) {
        AMLogWarn(@"AppMonet SDK has not been initialized. Unable to serve ads.");
        [self onError:@"Unable to serve ad due to invalid internal state."];
        return NO;
    }
    return YES;
}

- (void)onError:(NSString *)errorMessage {
    NSError *moPubError = [NSError errorWithCode:MOPUBErrorAdapterInvalid localizedDescription:errorMessage];
    MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error:moPubError], [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapter:self didFailToLoadAdWithError:moPubError];
}

@end
