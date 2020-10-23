//
// Created by Jose Portocarrero on 12/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMOAdServerAdRequest.h"

@class MPAdView;
@class AMOMopubAdView;

@interface AMOMopubAdRequest : AMOAdServerAdRequest
@property(nonatomic, strong) NSMutableDictionary *localExtras;

- (instancetype)initWithMoPubView:(MPAdView *)adView;

- (instancetype)init;

+ (AMOMopubAdRequest *)fromAuctionRequest:(AMOAuctionRequest *)request;

-(void) applyToView: (AMOMopubAdView *) adView;

@end
