//
// Created by Jose Portocarrero on 11/1/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMOAdView.h"

@class AMOAdSize;
@class AMOBidResponse;


@interface AMOBidManager : NSObject
@property(nonatomic, strong) NSDictionary *bidsById;
@property(nonatomic, strong) NSDictionary *seenBids;

- (instancetype)initWithExecutionQueue:(dispatch_queue_t)executionQueue;

- (void)addBids:(NSArray *)bids;

- (void)addBidsFromArray:(NSArray *)bids defaultUrl:(NSString *)defaultUrl;

- (BOOL)areBidsAvailableForAdUnit:(nonnull NSString *)adUnitId andAdSize:(nullable AMOAdSize *)adSize
                      andFloorCpm:(nonnull NSNumber *)floorCpm andBidArrayReference:(AMOBidResponse **)bid
                        andAdType:(AMOAdType)adType andShouldRequestMore:(BOOL)requestMore;

- (void)cleanBids;

- (AMOBidResponse *)fromDictionary:(NSDictionary *)dictionary;

- (void)addBid:(AMOBidResponse *)bid toDictionary:(NSMutableDictionary *)dictionary;

- (NSInteger)countBids:(NSString *)adUnitId;

- (nullable AMOBidResponse *)getBidForMediation:(NSString *)adUnitId andAdSize:(AMOAdSize *)adSize
                                    andFloorCpm:(NSNumber *)floorCpm andAdType:(AMOAdType)adType
                       andShouldIndicateRequest:(BOOL)indicateRequest;

- (nullable AMOBidResponse *)getBidForAdUnit:(nonnull NSString *)adUnitId;

- (void)invalidateForView:(NSString *)wvUUID;

- (NSString *)invalidFlag:(AMOBidResponse *)bid;

- (NSString *)invalidReason:(AMOBidResponse *)bid;

- (BOOL)isBidAttachable:(AMOBidResponse **)bid forAdUnitId:(NSString *)adUnitId;

- (BOOL)isValid:(nullable AMOBidResponse *)bid;

- (void)logState;

- (void)markUsed:(AMOBidResponse *)bid;

- (AMOBidResponse *)peekBidForAdUnit:(NSString *)adUnitId;

- (AMOBidResponse *)peekNextBid:(NSString *)adUnitId;

- (AMOBidResponse *)removeBid:(NSString *)bidId;

- (BOOL)setAdUnitNames:(NSDictionary *)adUnits;

- (void)setBidderData:(NSArray *)bidderData;

- (AMOBidResponse *)getBidWithId:(NSString *)bidId;
@end
