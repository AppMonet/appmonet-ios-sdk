//
// Created by Jose Portocarrero on 11/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMOAuctionRequest.h"

@class AMOAuctionManager;
@protocol AMOAdServerWrapper;
@class AMOAdServerAdRequest;
@protocol AMOAdServerAdView;
@class AMOBidResponse;

@interface AMOAppMonetBidder : NSObject
- (instancetype)initWithAuctionManager:(AMOAuctionManager *)auctionManager
                    andAdServerWrapper:(id <AMOAdServerWrapper>)adServerWrapper;

- (void)removeAdUnit:(NSString *)adUnitId;

- (AMOAdServerAdRequest *)addBids:(id <AMOAdServerAdView>)adView andAdServerAdRequest:(id <AMServerAdRequest>)adRequest;

- (void)addBids:(id <AMOAdServerAdView>)adView andAdServerAdRequest:(id <AMServerAdRequest>)adRequest
     andTimeout:(NSNumber *)timeout andExecutionQueue:(dispatch_queue_t)executionQueue andValueBlock:(void (^)(id <AMServerAdRequest>))block;

- (void)prefetchBids:(NSArray<NSString *> *)adUnitIds;

- (void)cancelRequest:(NSString *)adUnitId andAMServerAdRequest:(id <AMServerAdRequest>)adRequest
       andBidResponse:(AMOBidResponse *)bid;
@end
