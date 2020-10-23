//
// Created by Jose Portocarrero on 2/26/20.
// Copyright (c) 2020 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMOAdView.h"

@class AMOBaseManager;
@class AMOBidManager;
@class AMOBidResponse;
@class AMOAdSize;

typedef void (^AMBidResponseBlock)(AMOBidResponse *, NSError *);

@interface AMOMediationManager : NSObject

- (instancetype)initWithSdkManager:(AMOBaseManager *)sdkManager andBidManager:(AMOBidManager *)bidManager;

- (void)getBidReadyForMediationAsync:(AMOBidResponse *)bids withAdUnit:(NSString *)adUnitId andAdSize:(AMOAdSize *)adSize
                          andFloorCpm:(NSNumber *)floorCpm andAdType:(AMOAdType)adType andBlock:(AMBidResponseBlock)block;

- (void)getBidReadyForMediationAsync:(AMOBidResponse *)bid withAdUnit:(NSString *)adUnitId andAdSize:(AMOAdSize *)adSize
                         andFloorCpm:(NSNumber *)floorCpm andAdType:(AMOAdType)adType andBlock:(AMBidResponseBlock)block
                   andDefaultTimeout:(NSNumber *)defaultTimeout;

- (AMOBidResponse *)getBidReadyForMediation:(AMOBidResponse *)bids andAdUnitId:(NSString *)adUnitId
                      shouldIndicateRequest:(BOOL)indicateRequest withAdSize:(AMOAdSize *)adSize
                                andFloorCpm:(NSNumber *)floorCpm forAdType:(AMOAdType)adType withError:(NSError **)errorPtr;
@end
