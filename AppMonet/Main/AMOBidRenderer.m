//
// Created by Jose Portocarrero on 11/8/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMOBidRenderer.h"
#import "AMOAdView.h"
#import "AMOBidResponse.h"
#import "AMOAdServerAdapter.h"
#import "AMOConstants.h"
#import "AMOAppMonetViewLayout.h"
#import "AMOSdkManager.h"
#import "AMOAdViewPoolManager.h"
#import "AMOBidManager.h"
#import "AMOUtils.h"


@implementation AMOBidRenderer

+ (AMOAppMonetViewLayout *)renderBid:(AMOBidResponse *)bidResponse andAdSize:(AMOAdSize *)adSize
                  andAdServerAdapter:(id <AMOAdServerAdapter>)adapter {
    AMLogDebug(@"Rendering bid: %@ ", [bidResponse description]);
    AMOSdkManager *sdkManager = [AMOSdkManager get];
    if (sdkManager == nil) {
        AMLogWarn(@"AppMonet not initialized. Unable to render bid");
        return nil;
    }

    if (![sdkManager.bidManager isValid:bidResponse]) {
        [sdkManager.auctionManager trackEvent:@"bidRenderer" withDetail:@"invalid_bid"
                                       andKey:bidResponse.id andValue:@0 andCurrentTime:[AMOUtils getCurrentMillis]];
    }

    AMOAdView *adView = [[[AMOSdkManager get] adViewPoolManager] requestWithBid:bidResponse];
    if (adView == nil) {
        AMLogWarn(@"fail to attach adView. Unable to serve.");
        [sdkManager.auctionManager trackEvent:@"bidRenderer" withDetail:@"null_view"
                                       andKey:bidResponse.id andValue:@0 andCurrentTime:[AMOUtils getCurrentMillis]];
        return nil;
    }

    if (!adView.getLoaded) {
        AMLogDebug(@"Initializing AdView for injection");
        [adView load];
    }

    [adapter setAppMonetAdView:adView.adViewContainer];
    [adView setBid:bidResponse];
    [adView setTrackingBid:bidResponse];
    [adView setState:AD_RENDERED andEventDelegate:adapter.getDelegate];

    AMLogDebug(@"injecting ad into view");

    [adView inject:bidResponse];
    adView.isAdRefreshed = NO;
    [[sdkManager bidManager] markUsed:bidResponse];

    if (adSize && ![adSize.width isEqualToNumber:@0] && ![adSize.height isEqualToNumber:@0] && bidResponse.flexSize == YES) {
        [adView resize:adSize];
    }
    if ([sdkManager isTestMode]) {
        AMLogWarn(kAMOTestModeWarning);
    }
    return adView.adViewContainer;
}

@end
