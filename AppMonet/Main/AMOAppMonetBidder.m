//
// Created by Jose Portocarrero on 11/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMOAuctionManager.h"
#import "AMOAdServerAdRequest.h"
#import "AMOAdServerAdView.h"
#import "AMOAuctionRequest.h"
#import "AMOConstants.h"
#import "AMOAppMonetBidder.h"
#import "AMOBidResponse.h"
#import "AMOSdkManager.h"
#import "AMOUtils.h"

@implementation AMOAppMonetBidder {
    NSMutableDictionary *_adViews;
    NSMutableDictionary *_extrantExtras;
    AMOAuctionManager *_auctionManager;
    id <AMOAdServerWrapper> _adServerWrapper;
}
- (instancetype)initWithAuctionManager:(AMOAuctionManager *)auctionManager
                    andAdServerWrapper:(id <AMOAdServerWrapper>)adServerWrapper {
    self = [super init];
    if (self != nil) {
        _adViews = [NSMutableDictionary dictionary];
        _extrantExtras = [NSMutableDictionary dictionary];
        _auctionManager = auctionManager;
        _adServerWrapper = adServerWrapper;
    }
    return self;
}

- (void)addBids:(id <AMOAdServerAdView>)adView andAdServerAdRequest:(id <AMServerAdRequest>)adRequest
     andTimeout:(NSNumber *)timeout andExecutionQueue:(dispatch_queue_t)executionQueue andValueBlock:(void (^)(id <AMServerAdRequest>))block {
    if ([AMOSdkManager.get isTestMode]) {
        AMLogWarn(kAMOTestModeWarning);
    }
    return [self addBidsToPublisherAdRequest:adView andAdServerAdRequest:adRequest andTimeout:timeout andExecutionQueue:executionQueue
                               andValueBlock:block];
}

- (void)prefetchBids:(NSArray<NSString *> *)adUnitIds {
    // just call trackRequest for each of the ad unit ids
    [adUnitIds enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        AMLogDebug(@"Prefetching %@", obj);
        [_auctionManager trackRequest:obj andSource:@"prefetchBids"];
    }];
}

- (void)removeAdUnit:(NSString *)adUnitId {
    if (_adViews[adUnitId]) {
        AMLogDebug(@"Removing adUnit at ID - %@", adUnitId);
        [_adViews removeObjectForKey:adUnitId];
    } else {
        AMLogDebug(@"No adUnit assigned at %@ - no remove", adUnitId);
    }
}

- (AMOAdServerAdRequest *)addBids:(id <AMOAdServerAdView>)adView andAdServerAdRequest:(id <AMServerAdRequest>)adRequest {
    if ([AMOSdkManager.get isTestMode]) {
        AMLogWarn(kAMOTestModeWarning);
    }
    return [self addBidsToPublisherAdRequest:adView andAdServerAdRequest:adRequest];
}

- (void)cancelRequest:(NSString *)adUnitId andAMServerAdRequest:(id <AMServerAdRequest>)adRequest andBidResponse:(AMOBidResponse *)bid {
    if (adUnitId == nil || adRequest == nil) {
        return;
    }

    if (!_adViews[adUnitId]) {
        return;
    }

    id <AMOAdServerAdView> adView = _adViews[adUnitId];
    if (adView == nil) {
        AMLogWarn(@"could not associate adView for next request");
        return;
    }

    // the request that we get has minimal targeting.
    // we need to create a new request from merging that
    // with what we have in sExtantExtras
    AMOAuctionRequest *extant = _extrantExtras[adUnitId];
    extant = extant != nil ? extant : [AMOAuctionRequest from:adView andAdServerAdRequest:adRequest];
    id <AMServerAdRequest> request = [_adServerWrapper newAdRequest:[adRequest apply:extant andAdServerAdView:adView]];

    if (bid != nil) {
        AMLogInfo(@"attaching next bid ... %@", [bid description]);
        [_auctionManager trackRequest:adView.getAdUnitId andSource:@"addBidRefresh"];

        AMOAuctionRequest *req = [_auctionManager addRawBid:adView andServerAdRequest:request andBidResponse:bid];
        [adView loadAd:[self buildRequest:req andAdType:adView.getType]];
    } else {
        AMLogDebug(@"passing request");
        [adView loadAd:request];
    }

}

//todo - documentation
- (void)addBidsToPublisherAdRequest:(id <AMOAdServerAdView>)adView andAdServerAdRequest:(id <AMServerAdRequest>)adRequest
                         andTimeout:(NSNumber *)timeout andExecutionQueue:(dispatch_queue_t)executionQueue
                      andValueBlock:(void (^)(id <AMServerAdRequest>))block {
    [self registerView:adView andAdServerAdRequest:adRequest];
    dispatch_async(executionQueue, ^{
        [_auctionManager attachBidAsync:adView andAdServerAdRequest:adRequest andTimeout:timeout
                          andValueBlock:^(AMOAuctionRequest *auctionRequest) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  [_auctionManager trackRequest:adView.getAdUnitId andSource:@"addBidsAsync"];
                                  if (auctionRequest == nil) {
                                      [self addBidsNoFill:[adView getAdUnitId]];
                                      AMLogInfo(@"no bid returned from js");
                                      block(adRequest);
                                      return;
                                  }
                                  id <AMServerAdRequest> newRequest = [self buildRequest:auctionRequest andAdType:adView.getType];
                                  AMLogDebug(@"passing bid back");
                                  block(newRequest);
                              });
                          }];
    });
}

- (void)registerView:(id <AMOAdServerAdView>)adView andAdServerAdRequest:(id <AMServerAdRequest>)request {
    if (adView == nil) {
        return;
    }

    [_adViews removeObjectForKey:adView.getAdUnitId];
    _adViews[adView.getAdUnitId] = adView;
    if (request == nil) {
        return;
    }
    [_extrantExtras removeObjectForKey:adView.getAdUnitId];
    _extrantExtras[adView.getAdUnitId] = [AMOAuctionRequest from:adView andAdServerAdRequest:request];
}

- (id <AMServerAdRequest>)addBidsToPublisherAdRequest:(id <AMOAdServerAdView>)adView andAdServerAdRequest:(AMOAdServerAdRequest *)otherRequest {
    // fetch a bid from our backend & attach it's KVPs to the
    // request
    [self registerView:adView andAdServerAdRequest:otherRequest];
    AMOAuctionRequest *request = [_auctionManager attachBid:adView andAdServerAdRequest:otherRequest];
    [_auctionManager trackRequest:adView.getAdUnitId andSource:@"addBids"];
    if (request == nil) {
        AMLogDebug(@"no bids received");
        [self addBidsNoFill:[adView getAdUnitId]];
        return otherRequest;
    }
    return [self buildRequest:request andAdType:adView.getType];
}

- (id <AMServerAdRequest>)buildRequest:(AMOAuctionRequest *)request andAdType:(AMType)type {
    return [_adServerWrapper newAdRequest:request andAdType:type];
}

- (void)addBidsNoFill:(NSString *)adUnitId {
    [_auctionManager trackEvent:@"addbids_nofill" withDetail:@"null" andKey:adUnitId andValue:@0
                 andCurrentTime:[AMOUtils getCurrentMillis]];
}


@end
