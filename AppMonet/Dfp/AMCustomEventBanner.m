//
// Created by Jose Portocarrero on 11/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//
#import "AMOAdServerAdapter.h"
#import "AMCustomEventBanner.h"
#import "AMOAdView.h"
#import "AMOBidResponse.h"
#import "AMOAdSize.h"
#import "AMODfpAdSize.h"
#import "AMOBidRenderer.h"
#import "AMOConstants.h"
#import "AMOUtils.h"
#import "AMODFPRequestReader.h"
#import "AMOAppMonetViewLayout.h"
#import "AMOMediationManager.h"
#import "AMOSdkManager.h"

@interface AMCustomEventBanner () <GADCustomEventBanner, AMOAdViewDelegate, AMOAdServerAdapter>
@property(nonatomic, weak) AMOAppMonetViewLayout *adView;

@end

@implementation AMCustomEventBanner {
    AMOAdSize *_adSizes;
    BOOL _adViewLoaded;
}

@synthesize delegate;

- (void)requestBannerAd:(GADAdSize)adSize parameter:(NSString *GAD_NULLABLE_TYPE)serverParameter
                  label:(NSString *GAD_NULLABLE_TYPE)serverLabel request:(GADCustomEventRequest *)request {
    AMLogInfo(@"requestBannerAd invoked. Custom banner found");
    if (request == nil) {
        AMLogError(@"load failed. no request");
        [self loadError:kGADErrorInvalidRequest];
        return;
    }

    _adSizes = [[AMODfpAdSize alloc] initWithAdSize:adSize];
    NSString *adUnitId = [AMODFPRequestReader extractAdUnitID:request andServerLabel:serverLabel
                                              withServerValue:serverParameter andAdSize:_adSizes];
    [[AMOSdkManager.get auctionManager] trackRequest:adUnitId andSource:[AMOUtils getCustomEventSourceType:BANNER]];

    if (!am_obj_isString(adUnitId)) {
        AMLogError(@"fail: no ad unit!");
        [self loadError:kGADErrorInvalidRequest];
        return;
    }

    // first, try to get the ad from header bidding
    // and then render it..
    AMOBidResponse *bid = [AMODFPRequestReader bidResponseFromHeaderBidding:request
                                                             andServerLabel:serverLabel
                                                                andAdUnitID:adUnitId];

    NSNumber *cpm = [AMODFPRequestReader getCpm:serverParameter];
    if (bid == nil) {
        bid = [AMODFPRequestReader bidResponseFromMediation:request andAdSize:_adSizes andAdUnitID:adUnitId
                                                andCpmFloor:cpm andAdType:BANNER];
    }
    NSError *error = nil;

    bid = [[AMOSdkManager get].mediationManager getBidReadyForMediation:bid andAdUnitId:adUnitId shouldIndicateRequest:YES
                                                             withAdSize:_adSizes andFloorCpm:cpm forAdType:BANNER withError:&error];
    if (error) {
        [self loadError:kGADErrorNoFill];
        return;
    }

    _adView = [AMOBidRenderer renderBid:bid andAdSize:_adSizes andAdServerAdapter:self];
    if (_adView == nil) {
        AMLogWarn(@"Unexpected - no AdView after render!");
        [self loadError:kGADErrorInternalError];
    }
}

- (void)adView:(AMOAppMonetViewLayout *)adView adLoaded:(AMOBidResponse *)bid {
    _adViewLoaded = YES;
    if (adView.isAdRefreshed) {
        [_adView swapViews:adView andDelegate:self];
        return;
    }
    [delegate customEventBanner:self didReceiveAd:adView];
}

- (void)adView:(AMOAdView *)adView adError:(AMErrorCode)error {
    if (!_adViewLoaded) {
        [delegate customEventBanner:self didFailAd:AMGADError(error)];
    }
}

- (void)adView:(AMOAdView *)adView willLeaveApplication:(NSURL *)url {
    [delegate customEventBannerWillLeaveApplication:self];
}

- (void)adView:(AMOAdView *)adView willReturnToApplication:(NSURL *)url {
    // DO NOTHING
}

- (void)adView:(AMOAdView *)adView wasClicked:(NSURL *)url {
    [delegate customEventBannerWasClicked:self];
}

- (void)adClosed {
    //nothing
}

- (void)onAdRefreshed:(AMOAppMonetViewLayout *)view {
    _adView = view;
}

- (void)loadError:(enum GADErrorCode)code {
    [self.delegate customEventBanner:self didFailAd:AMGADError(code)];
}

- (id <AMOAdViewDelegate>)getDelegate {
    return self;
}

- (void)setAppMonetAdView:(AMOAppMonetViewLayout *)adView {
    self.adView = adView;
}

- (void)dealloc {
    AMLogDebug(@"CustomEventBanner deallocated.");
    [_adView invalidateView:YES withDelegate:self];
}

@end
