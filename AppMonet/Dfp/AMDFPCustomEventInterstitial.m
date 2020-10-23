//
// Created by Nick Jacob on 4/16/19.
// Copyright (c) 2019 AppMonet. All rights reserved.
//

#import "AMDFPCustomEventInterstitial.h"
#import "AMOAdView.h"
#import "AMOConstants.h"
#import "AMODFPRequestReader.h"
#import "AMOSdkManager.h"
#import "AMOBidResponse.h"
#import "AMODFPInterstitial.h"
#import "AMOAppMonetViewLayout.h"
#import "AMOBidRenderer.h"
#import "AMOAdServerAdapter.h"
#import "AMOMediationManager.h"
#import "AMOUtils.h"

static NSString *const amCustomEventErrorDomain = @"com.monet.bidder.CustomEventInterstitial";

@interface AMDFPCustomEventInterstitial () <AMOAdViewDelegate, AMODFPInterstitialDelegate, AMOAdServerAdapter, GADCustomEventInterstitial>
@property(nonatomic, weak) AMOAppMonetViewLayout *adView;
@property(nonatomic, strong) AMODFPInterstitial *interstitial;
@property(nonatomic, strong) AMOBidResponse *bid;
@property(nonatomic, strong) GADCustomEventRequest *request;
@property(nonatomic, strong) AMOSdkManager *sdkManager;

@end

@implementation AMDFPCustomEventInterstitial {
    BOOL _adLoaded;
}

@synthesize delegate = _delegate;

- (NSError *)errorOf:(NSInteger)errorCode {
    return [[NSError alloc] initWithDomain:amCustomEventErrorDomain code:errorCode userInfo:nil];
}


- (void)presentFromRootViewController:(UIViewController *)root_view_controller {
    self.interstitial = [[AMODFPInterstitial alloc] init];
    self.interstitial.delegate = self;
    [self.interstitial presentFromViewController:root_view_controller withAdView:_adView];
}

- (void)interstitial:(AMODFPInterstitial *)interstitial willShow:(AMOAppMonetViewLayout *)ad_view {
    [self.delegate customEventInterstitialWillPresent:self];
}

- (void)interstitial:(AMODFPInterstitial *)interstitial didShow:(AMOAppMonetViewLayout *)adView {
    AMLogInfo(@"Interstitial showed"); // nothing -- we already called "will present"
}

- (void)interstitial:(AMODFPInterstitial *)interstitial willDismiss:(AMOAppMonetViewLayout *)ad_view {
    [self.delegate customEventInterstitialWillDismiss:self];
}

- (void)interstitial:(AMODFPInterstitial *)interstitial didDissmis:(AMOAppMonetViewLayout *)ad_view {
    [_adView invalidateView:YES withDelegate:self];
    _adView = nil;
    [self.delegate customEventInterstitialDidDismiss:self];
}

- (void)interstitial:(AMODFPInterstitial *)interstitial willLeaveApplication:(NSURL *)url {
    [self.delegate customEventInterstitialWillLeaveApplication:self];
}

- (void)interstitial:(AMODFPInterstitial *)interstitial hasError:(NSError *)error {
    [self.delegate customEventInterstitial:self didFailAd:error];
}

- (void)interstitial:(AMODFPInterstitial *)interstitial wasClicked:(NSURL *)url {
    [self.delegate customEventInterstitialWasClicked:self];
}

- (id <AMOAdViewDelegate>)getDelegate {
    return self;
}

- (void)setAppMonetAdView:(AMOAppMonetViewLayout *)adView {
    self.adView = adView;
}

- (void)requestInterstitialAdWithParameter:(nullable NSString *)serverParameter label:(nullable NSString *)serverLabel request:(GADCustomEventRequest *)request {
    if (![self isSdkManagerAvailable]) {
        return;
    }

    AMOAdSize *size = [[AMOAdSize alloc] initWithWidth:@(kAMOInterstitialWidth) andHeight:@(kAMOInterstitialHeight)];
    NSString *adUnitId = [AMODFPRequestReader extractAdUnitID:request andServerLabel:serverLabel
                                              withServerValue:serverParameter andAdSize:size];
    if (![self isAdUnitIdConfigured:adUnitId]) {
        return;
    }
    [[AMOSdkManager.get auctionManager] trackRequest:adUnitId andSource:[AMOUtils getCustomEventSourceType:INTERSTITIAL]];

    AMOBidResponse *bid = [AMODFPRequestReader bidResponseFromHeaderBidding:request
                                                             andServerLabel:serverLabel
                                                                andAdUnitID:adUnitId];
    
    NSNumber *cpm = [AMODFPRequestReader getCpm:serverParameter];
    if (bid == nil) {
        bid = [AMODFPRequestReader bidResponseFromMediation:request andAdSize:size andAdUnitID:adUnitId
                                                andCpmFloor:cpm andAdType:INTERSTITIAL];
    }
    [ _sdkManager.mediationManager getBidReadyForMediationAsync:bid withAdUnit:adUnitId andAdSize:size andFloorCpm:cpm
                                 andAdType:INTERSTITIAL andBlock:^(AMOBidResponse *response, NSError *error) {
                if (error) {
                    AMLogError(@"unexpected error in mediation: %@", error);
                    [self loadFailed:kGADErrorInternalError];
                    return;
                }
                _adView = [AMOBidRenderer renderBid:response andAdSize:nil andAdServerAdapter:self];
                if (_adView == nil) {
                    AMLogError(@"unexpected: could not generate the adView");
                    [self loadFailed:kGADErrorInternalError];
                }
            }];
}

#pragma mark - <Private Methods>

- (BOOL)isSdkManagerAvailable {
    _sdkManager = [AMOSdkManager get];
    if (_sdkManager == nil) {
        AMLogWarn(@"AppMonet SDK has not been initialized. Unable to serve ads.");
        [self loadFailed:kGADErrorInternalError];
        return NO;
    }
    return YES;
}

- (BOOL)isAdUnitIdConfigured:(NSString *)adUnitId {
    if (adUnitId == nil || [adUnitId length] == 0) {
        AMLogDebug(@"no adUnit/tagId: floor line item configured incorrectly");
        [self loadFailed:kGADErrorInternalError];
        return NO;
    }
    return YES;
}

- (void)loadFailed:(NSInteger)errorCode {
    [self.delegate customEventInterstitial:self didFailAd:[self errorOf:errorCode]];
}

- (void)adView:(AMOAdView *)adView wasClicked:(NSURL *)url {
    [_delegate customEventInterstitialWasClicked:self];
}

- (void)adView:(AMOAdView *)adView willLeaveApplication:(NSURL *)url {
    [self.delegate customEventInterstitialWillLeaveApplication:self];
}

- (void)adView:(AMOAdView *)adView willReturnToApplication:(NSURL *)url {
    //do nothing.
}

- (void)adView:(AMOAppMonetViewLayout *)adView adLoaded:(AMOBidResponse *)bid {
    _adLoaded = YES;
    [self.delegate customEventInterstitialDidReceiveAd:self];
}

- (void)adClosed {
//do nothing
}

- (void)onAdRefreshed:(AMOAppMonetViewLayout *)view {
// do nothing
}

- (void)adView:(AMOAdView *)adView adError:(AMErrorCode)errorCode {
    if (_adLoaded) {
        AMLogWarn(@"already loaded -- will not failLoad now");
        return;
    }
    NSString *errorValue = errorCodeValueString(errorCode);
    [self.delegate customEventInterstitial:self didFailAd:[NSError errorWithDomain:errorValue code:errorCode userInfo:nil]];
}


@end
