//
// Created by Jose Portocarrero on 1/8/20.
// Copyright (c) 2020 AppMonet. All rights reserved.
//

#import <MPNativeAdRequestTargeting.h>
#import "AMOMopubNativeAdRequest.h"
#import "AMOConstants.h"
#import "AMOAuctionRequest.h"
#import "AMOMopubAdView.h"
#import "AMOMoPubUtils.h"

@implementation AMOMopubNativeAdRequest

- (instancetype)initWithNativeAdRequest:(MPNativeAdRequest **)adRequest {
    if (self = [super init]) {
        if ((*adRequest).targeting == nil) {
            (*adRequest).targeting = [MPNativeAdRequestTargeting targeting];
        }
        _localExtras = [[NSMutableDictionary alloc] initWithDictionary:((*adRequest).targeting.localExtras != nil)
                ? [(*adRequest).targeting.localExtras mutableCopy] : [NSMutableDictionary dictionary]];
        if (_localExtras[AMBidsKey]) {
            self.bid = [_localExtras valueForKey:AMBidsKey];
        }
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _localExtras = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (AMOMopubNativeAdRequest *)fromAuctionRequest:(AMOAuctionRequest *)request {
    AMOMopubNativeAdRequest *adRequest = [[AMOMopubNativeAdRequest alloc] init];
    for (NSString *key in request.targeting) {
        if (key == nil) continue;
        adRequest.localExtras[key] = request.targeting[key];
    }
    if (request.bid != nil) {
        adRequest.bid = request.bid;
    }
    return adRequest;
}

- (void)applyToView:(AMOMopubAdView *)adView {
    MPNativeAdRequest *request = adView.getNativeAdRequest;
    [_localExtras setValue:self.bid forKey:AMBidsKey];
    [_localExtras setValue:adView.getAdUnitId forKey:kAMAdUnitKeywordKey];
    NSMutableString *keywords = [[AMOMoPubUtils getKeywords:_localExtras] mutableCopy];
    if (request.targeting != nil && request.targeting.keywords != nil) {
        keywords = [AMOMoPubUtils mergeKeywords:request.targeting.keywords withNewKeyWords:keywords];
    }
    request.targeting.keywords = keywords;
    NSMutableDictionary *viewLocalExtras = [request.targeting.localExtras mutableCopy];
    if(viewLocalExtras){
        [viewLocalExtras addEntriesFromDictionary:_localExtras];
        request.targeting.localExtras = viewLocalExtras;
    }else {
        request.targeting.localExtras = _localExtras;
    }
}

@end
