//
// Created by Jose Portocarrero on 12/6/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMCustomEventBanner.h"
#import "AMOConstants.h"
#import "AMOBidResponse.h"
#import "AMOBidManager.h"
#import "AMOSdkManager.h"
#import "AMOAdSize.h"
#import "AMOBidRenderer.h"
#import "AMOAdView.h"
#import "AMCustomEventUtil.h"
#import "AMOAppMonetViewLayout.h"
#import "AMOMediationManager.h"
#import "AMOUtils.h"

static NSString *internalError = @"Unable to serve ad due to invalid internal state.";
static NSString *networkNoFill = @"Third-party network failed to provide an ad.";



@interface AMCustomEventBanner () <AMOAdViewDelegate, AMOAdServerAdapter>
@property(nonatomic, strong) AMOAdSize *adSize;
@property(nonatomic, weak) AMOAppMonetViewLayout *adViewLayout;
@property(nonatomic, strong) AMOSdkManager *sdkManager;
@property(nonatomic, copy) NSString *appMonetAdUnitId;
@property(nonatomic) BOOL adLoaded;
@end

@implementation AMCustomEventBanner

@synthesize localExtras;

- (id)init {
    self = [super init];
    return self;
}

#pragma  mark - <AMCustomEventBannerDelegate>

- (void)adClosed {
    //Not implemented
}

- (void)onAdRefreshed:(AMOAppMonetViewLayout *)view {
    self.appMonetAdView = view;
}

- (void)adView:(AMOAdView *)adView adError:(AMErrorCode)error {
    if (_adLoaded) {
        return;
    }
    NSString *errorValue = errorCodeValueString(error);
    [self.delegate inlineAdAdapter:self didFailToLoadAdWithError:[self error:errorValue code:error]];
}

- (void)adView:(AMOAdView *)adView wasClicked:(NSURL *)url {
    MPLogAdEvent([MPLogEvent adTappedForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate inlineAdAdapterWillBeginUserAction:self];
    [self.delegate inlineAdAdapterDidTrackClick:self];
}

- (void)adView:(AMOAdView *)ad_view willLeaveApplication:(NSURL *)url {
    MPLogAdEvent([MPLogEvent adWillLeaveApplicationForAdapter:NSStringFromClass(self.class)],
            [self getAdNetworkId]);
    [self.delegate inlineAdAdapterWillLeaveApplication:self];
}

- (void)adView:(AMOAdView *)ad_view willReturnToApplication:(NSURL *)url {
    // DO NOTHING
}

- (void)adView:(AMOAppMonetViewLayout *)ad_view adLoaded:(AMOBidResponse *)bid {
    _adLoaded = YES;
    if (ad_view.isAdRefreshed) {
        [self.adViewLayout swapViews:ad_view andDelegate:self];
        return;
    }
    MPLogAdEvent([MPLogEvent adLoadSuccessForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adShowAttemptForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate inlineAdAdapter:self didLoadAdWithAdView:ad_view];
    [self.delegate inlineAdAdapterDidTrackImpression:self];
}

#pragma mark - <AMAdServerAdapter>

- (id <AMOAdViewDelegate>)getDelegate {
    return self;
}

- (void)setAppMonetAdView:(AMOAppMonetViewLayout *)adView {
    self.adViewLayout = adView;
}

#pragma mark - MPInlineAdAdapter Overridden Methods

- (void)requestAdWithSize:(CGSize)size adapterInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
    @autoreleasepool {
        if (![self isSdkManagerAvailable]) {
            [self.delegate inlineAdAdapter:self didFailToLoadAdWithError:[self error:internalError code:-2]];
            return;
        }
        _adSize = [[AMOAdSize alloc] initWithWidth:@(size.width) andHeight:@(size.height)];
        NSString *adUnitId = [AMCustomEventUtil getAdUnit:info fromLocalExtras:self.localExtras withAdSize:_adSize];
        self.appMonetAdUnitId = adUnitId;
        if (![self isAdUnitIdConfigured:adUnitId]) {
            [self.delegate inlineAdAdapter:self didFailToLoadAdWithError:[self error:networkNoFill code:-1]];
            return;
        }
        [[_sdkManager auctionManager] trackRequest:adUnitId andSource:[AMOUtils getCustomEventSourceType:BANNER]];

        AMOBidManager *bidManager = [[AMOSdkManager get] bidManager];
        NSNumber *floorCpm = [AMCustomEventUtil getCpm:info];
        AMOBidResponse *bid = [AMCustomEventUtil getBidFromLocalExtras:localExtras];

        if (bid == nil) {
            bid = [bidManager getBidForMediation:adUnitId andAdSize:_adSize andFloorCpm:floorCpm andAdType:BANNER andShouldIndicateRequest:NO];
        }

        NSError *error = nil;
        bid = [_sdkManager.mediationManager getBidReadyForMediation:bid andAdUnitId:adUnitId shouldIndicateRequest:YES
                                                         withAdSize:_adSize andFloorCpm:floorCpm forAdType:BANNER withError:&error];
        if (error) {
            [self.delegate inlineAdAdapter:self didFailToLoadAdWithError:[self error:networkNoFill code:-1]];
            return;
        }
        self.appMonetAdView = [AMOBidRenderer renderBid:bid andAdSize:_adSize andAdServerAdapter:self];
        if (self.adViewLayout == nil) {
            AMLogError(@"unexpected: could not generate the adView");
            [self.delegate inlineAdAdapter:self didFailToLoadAdWithError:[self error:internalError code:-2]];
            return;
        }
        MPLogAdEvent([MPLogEvent adLoadAttemptForAdapter:NSStringFromClass(self.class) dspCreativeId:nil dspName:nil],
                [self getAdNetworkId]);
    }
}

- (BOOL)enableAutomaticImpressionAndClickTracking {
    return NO;
}

- (NSString *)getAdNetworkId {
    return self.appMonetAdUnitId;
}

- (void)dealloc {
    @autoreleasepool {
        if (self.adViewLayout) {
            [self.adViewLayout invalidateView:YES withDelegate:self];
            self.appMonetAdView = nil;
        }
        _sdkManager = nil;
        _adSize = nil;
    }
}

#pragma mark - Private Methods

- (BOOL)isAdUnitIdConfigured:(NSString *)adUnitId {
    if (adUnitId == nil || [adUnitId length] == 0) {
        AMLogDebug(@"no adUnit/tagId: floor line item configured incorrectly");
        [self.delegate inlineAdAdapter:self didFailToLoadAdWithError:[self error:internalError code:-2]];
        return NO;
    }
    return YES;
}

- (BOOL)isSdkManagerAvailable {
    _sdkManager = [AMOSdkManager get];
    if (_sdkManager == nil) {
        AMLogWarn(@"AppMonet SDK has not been initialized. Unable to serve ads.");
        [self.delegate inlineAdAdapter:self didFailToLoadAdWithError:[self error:internalError code:-2]];
        return NO;
    }
    return YES;
}

- (NSError *)error:(NSString *)message code:(NSInteger)code {
    return [NSError errorWithDomain:message code:code userInfo:nil];
}

@end
