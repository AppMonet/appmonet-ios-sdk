//
//  AMCustomEventNative.m
//  AppMonet_Mopub
//
//  Created by Jose Portocarrero on 1/3/20.
//  Copyright © 2020 AppMonet. All rights reserved.
//


#import "AMCustomEventNative.h"
#import "AMOSdkManager.h"
#import "AMOBidManager.h"
#import "AMOBidResponse.h"
#import "AMOBidRenderer.h"
#import "AMOAdServerAdapter.h"
#import "AMONativeAdAdapter.h"
#import "AMCustomEventUtil.h"
#import "AMOConstants.h"
#import "AMOUtils.h"
#import "AMOMediationManager.h"

@interface AMCustomEventNative () <AMOAdServerAdapter, AMOAdViewDelegate>
@property(nonatomic, weak) AMOAppMonetViewLayout *adView;
@property(nonatomic, strong) NSMutableDictionary *info;
@property(nonatomic, strong) AMONativeAdAdapter *adapter;

@end

@implementation AMCustomEventNative
@synthesize delegate;


- (void)requestAdWithCustomEventInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
    AMLogDebug(@"Loading Native Ad..");
    AMOAdSize *adSize = [[AMOAdSize alloc] initWithWidth:@320 andHeight:@250];
    NSString *adUnitId = [AMCustomEventUtil getAdUnit:info fromLocalExtras:self.localExtras withAdSize:adSize];
    AMOSdkManager *sdkManager = [AMOSdkManager get];
    if (sdkManager == nil) {
        [delegate nativeCustomEvent:self didFailToLoadAdWithError:[NSError errorWithCode:MOPUBErrorUnknown]];
        return;
    }

    if (adUnitId == nil) {
        [delegate nativeCustomEvent:self didFailToLoadAdWithError:[NSError errorWithCode:MOPUBErrorAdapterHasNoInventory]];
        return;
    }
    [[sdkManager auctionManager] trackRequest:adUnitId andSource:[AMOUtils getCustomEventSourceType:NATIVE]];

    AMOBidResponse *bid = [AMCustomEventUtil getBidFromLocalExtras:self.localExtras];
    NSNumber *floorCpm = [AMCustomEventUtil getCpm:info];
    AMOBidManager *bidManager = [[AMOSdkManager get] bidManager];

    if (bid == nil) {
        bid = [bidManager getBidForMediation:adUnitId andAdSize:adSize andFloorCpm:floorCpm andAdType:NATIVE andShouldIndicateRequest:NO];
    }

    NSError *error = nil;
    bid = [sdkManager.mediationManager getBidReadyForMediation:bid andAdUnitId:adUnitId shouldIndicateRequest:YES
                                                     withAdSize:adSize andFloorCpm:floorCpm forAdType:BANNER withError:&error];
    if (error) {
        [delegate nativeCustomEvent:self didFailToLoadAdWithError:[NSError errorWithCode:MOPUBErrorAdapterHasNoInventory]];
        return;
    }

    if (bid.extras != nil && bid.extras.count > 0) {
        for (NSString *key in bid.extras) {
            if (key == nil) continue;
            _info[key] = bid.extras[key];
        }
    }
    self.info = (info!=nil) ? [info mutableCopy] : [NSMutableDictionary dictionary];
    _adView = [AMOBidRenderer renderBid:bid andAdSize:nil andAdServerAdapter:self];
    if (_adView == nil) {
        [delegate nativeCustomEvent:self didFailToLoadAdWithError:[NSError errorWithCode:MOPUBErrorUnknown]];
    }
}

- (id <AMOAdViewDelegate>)getDelegate {
    return self;
}


- (void)setAppMonetAdView:(AMOAppMonetViewLayout *)adView {
    _adView = adView;
}

- (void)adView:(AMOAdView *)adView wasClicked:(NSURL *)url {
    if (_adapter) {
        [_adapter handleClick];
    }
}

- (void)adView:(AMOAdView *)adView willLeaveApplication:(NSURL *)url {

}

- (void)adView:(AMOAdView *)adView willReturnToApplication:(NSURL *)url {

}

- (void)adView:(AMOAppMonetViewLayout *)adView adLoaded:(AMOBidResponse *)bid {
    if (adView.isAdRefreshed) {
        [_adView swapViews:adView andDelegate:self];
        return;
    }
    _adapter = [[AMONativeAdAdapter alloc] initWithMonetAdView:adView];
    [_adapter setupWithAdProperties:self.info];
    MPNativeAd *moPubNativeAd = [[MPNativeAd alloc] initWithAdAdapter:_adapter];
    [self.delegate nativeCustomEvent:self didLoadAd:moPubNativeAd];
    [_adapter adWillLogImpression];
}

- (void)adView:(AMOAdView *)adView adError:(AMErrorCode)errorCode {

}

- (void)adClosed {
    //no implementation
}


- (void)onAdRefreshed:(AMOAppMonetViewLayout *)view {
    _adView = view;
}


@end

