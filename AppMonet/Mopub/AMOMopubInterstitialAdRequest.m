//
// Created by Jose Portocarrero on 1/9/20.
// Copyright (c) 2020 AppMonet. All rights reserved.
//

#import "AMOMopubInterstitialAdRequest.h"
#import "MPInterstitialAdController.h"
#import "AMOAuctionRequest.h"
#import "AMOMopubAdView.h"
#import "AMOConstants.h"
#import "AMOMoPubUtils.h"

@implementation AMOMopubInterstitialAdRequest

- (instancetype)initWithInterstitialAdController:(MPInterstitialAdController **)interstitial {
    if (self = [super init]) {
        _localExtras = [[NSMutableDictionary alloc] initWithDictionary:((*interstitial).localExtras)
                ? [(*interstitial).localExtras mutableCopy] : [NSMutableDictionary dictionary]];
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

+ (AMOMopubInterstitialAdRequest *)fromAuctionRequest:(AMOAuctionRequest *)request {
    AMOMopubInterstitialAdRequest *adRequest = [[AMOMopubInterstitialAdRequest alloc] init];
    for (NSString *key in request.targeting) {
        adRequest.localExtras[key] = request.targeting[key];
    }
    if (request.bid != nil) {
        adRequest.bid = request.bid;
    }
    return adRequest;
}

- (void)applyToInterstitial:(AMOMopubAdView *)adView {
    MPInterstitialAdController *request = adView.getInterstitialAdController;
    [_localExtras setValue:self.bid forKey:AMBidsKey];
    [_localExtras setValue:adView.getAdUnitId forKey:kAMAdUnitKeywordKey];
    NSMutableString *keywords = [[AMOMoPubUtils getKeywords:_localExtras] mutableCopy];
    if (request.keywords != nil) {
        keywords = [AMOMoPubUtils mergeKeywords:request.keywords withNewKeyWords:keywords];
    }
    request.keywords = keywords;
    NSMutableDictionary *viewLocalExtras = [request.localExtras mutableCopy];
    if(viewLocalExtras){
        [viewLocalExtras addEntriesFromDictionary:_localExtras];
        request.localExtras = viewLocalExtras;
    }else {
        request.localExtras = _localExtras;
    }
}

@end
