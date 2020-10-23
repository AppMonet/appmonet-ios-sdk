//
// Created by Jose Portocarrero on 12/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMOMopubAdRequest.h"
#import "AMOAuctionRequest.h"
#import "MPAdView.h"
#import "AMOConstants.h"
#import "AMOMopubAdView.h"
#import "AMOMoPubUtils.h"

@implementation AMOMopubAdRequest {
    MPAdView *_adView;
    NSMutableDictionary *_localExtras;
}
- (instancetype)initWithMoPubView:(MPAdView *)adView {
    self = [super init];
    if (self) {
        _localExtras = [[NSMutableDictionary alloc] initWithDictionary:(adView.localExtras)
                ? [adView.localExtras mutableCopy] : [NSMutableDictionary dictionary]];
        _adView = adView;
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
        _adView = nil;
    }
    return self;
}

+ (AMOMopubAdRequest *)fromAuctionRequest:(AMOAuctionRequest *)request {
    AMOMopubAdRequest *adRequest = [[AMOMopubAdRequest alloc] init];
    for (NSString *key in request.targeting) {
        adRequest.localExtras[key] = request.targeting[key];
    }
    if (request.bid != nil) {
        adRequest.bid = request.bid;
    }
    return adRequest;
}

- (void)applyToView:(AMOMopubAdView *)adView {
    MPAdView *view = adView.getMopubView;
    [_localExtras setValue:self.bid forKey:AMBidsKey];
    [_localExtras setValue:adView.getAdUnitId forKey:kAMAdUnitKeywordKey];
    NSMutableString *keywords = [[AMOMoPubUtils getKeywords:_localExtras] mutableCopy];
    if (view.keywords != nil) {
        keywords = [AMOMoPubUtils mergeKeywords:view.keywords withNewKeyWords:keywords];
    }
    view.keywords = keywords;
    NSMutableDictionary *viewLocalExtras = [view.localExtras mutableCopy];
    if(viewLocalExtras){
        [viewLocalExtras addEntriesFromDictionary:_localExtras];
        view.localExtras = viewLocalExtras;
    }else {
        view.localExtras = _localExtras;
    }
}



@end
