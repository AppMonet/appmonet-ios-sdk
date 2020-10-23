//
// Created by Jose Portocarrero on 2/26/20.
// Copyright (c) 2020 AppMonet. All rights reserved.
//

#import "AMOMediationManager.h"
#import "AMOBaseManager.h"
#import "AMOBidManager.h"
#import "AMOBidResponse.h"
#import "AMOConstants.h"
#import "AMOUtils.h"

@interface AMOMediationManager ()
@property(nonatomic) AMOBaseManager *sdkManager;
@property(nonatomic) AMOBidManager *bidManager;
@property(nonatomic, strong) NSError *noBidsError;
@end

@implementation AMOMediationManager

- (instancetype)initWithSdkManager:(AMOBaseManager *)sdkManager andBidManager:(AMOBidManager *)bidManager {
    if (self = [super init]) {
        self.bidManager = bidManager;
        self.sdkManager = sdkManager;
        self.noBidsError = [NSError errorWithDomain:@"Third-party network failed to provide an ad." code:-2 userInfo:nil];
    }
    return self;
}

- (void)getBidReadyForMediationAsync:(AMOBidResponse *)bid withAdUnit:(NSString *)adUnitId andAdSize:(AMOAdSize *)adSize
                         andFloorCpm:(NSNumber *)floorCpm andAdType:(AMOAdType)adType andBlock:(AMBidResponseBlock)block {
    [self getBidReadyForMediationAsync:bid withAdUnit:adUnitId andAdSize:adSize andFloorCpm:floorCpm
                             andAdType:adType andBlock:block andDefaultTimeout:nil];
}

- (void)getBidReadyForMediationAsync:(AMOBidResponse *)bid withAdUnit:(NSString *)adUnitId andAdSize:(AMOAdSize *)adSize
                         andFloorCpm:(NSNumber *)floorCpm andAdType:(AMOAdType)adType andBlock:(AMBidResponseBlock)block
                   andDefaultTimeout:(NSNumber *)defaultTimeout {
    NSError *error = nil;
    bid = [self getBidReadyForMediation:bid andAdUnitId:adUnitId shouldIndicateRequest:NO
                             withAdSize:adSize andFloorCpm:floorCpm forAdType:adType withError:&error];
    if (error) {
        NSNumber *finalTimeout = nil;
        NSDictionary *timeouts = self.sdkManager.sdkConfigurations[AMAdUnitTimeout];
        if (timeouts && am_obj_isDictionary(timeouts)) {
            NSNumber *timeout = timeouts[adUnitId];
            finalTimeout = ((timeout == nil || timeout.integerValue <= 0) && defaultTimeout != nil) ? defaultTimeout : timeout;

            if (finalTimeout == nil || [finalTimeout integerValue] <= 0) {
                [_sdkManager indicateRequest:adUnitId withAdSize:adSize forAdType:adType andFloorCpm:floorCpm];
                [self returnBlock:block withBid:bid andError:error];
                return;
            }
        } else {
            [self returnBlock:block withBid:bid andError:error];
            return;
        };

        [_sdkManager indicateRequestAsync:adUnitId andTimeout:finalTimeout andAdSize:adSize andAdType:INTERSTITIAL
                              andFloorCpm:floorCpm withValueBlock:^(NSDictionary *dictionary, NSError *err) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSError *mediationError = nil;
                        AMOBidResponse *mediationBid = [_bidManager getBidForMediation:adUnitId andAdSize:adSize andFloorCpm:floorCpm
                                                                             andAdType:adType andShouldIndicateRequest:NO];

                        mediationBid = [self getBidReadyForMediation:mediationBid andAdUnitId:adUnitId
                                               shouldIndicateRequest:NO withAdSize:adSize andFloorCpm:floorCpm
                                                           forAdType:adType withError:&mediationError];
                        if (mediationError) {
                            [self returnBlock:block withBid:mediationBid andError:_noBidsError];
                            return;
                        }
                        [self returnBlock:block withBid:mediationBid andError:mediationError];
                    });
                }];
    } else {
        [self returnBlock:block withBid:bid andError:error];
    }
}

- (AMOBidResponse *)getBidReadyForMediation:(AMOBidResponse *)bid andAdUnitId:(NSString *)adUnitId
                      shouldIndicateRequest:(BOOL)indicateRequest withAdSize:(AMOAdSize *)adSize
                                andFloorCpm:(NSNumber *)floorCpm forAdType:(AMOAdType)adType
                                  withError:(NSError **)errorPtr {
    if (indicateRequest) {
        [_sdkManager indicateRequest:adUnitId withAdSize:adSize forAdType:adType andFloorCpm:floorCpm];
    }

    if (bid == nil || bid.id == nil) {
        if (errorPtr != NULL) *errorPtr = self.noBidsError;
        return nil;
    }
    if (![_bidManager isBidAttachable:&bid forAdUnitId:adUnitId]) {
        if (errorPtr != NULL) *errorPtr = self.noBidsError;
        return nil;
    }

    if (bid == nil) {
        if (errorPtr != NULL) *errorPtr = self.noBidsError;
        return nil;
    }
    return bid;
}

- (void)returnBlock:(AMBidResponseBlock)block withBid:(AMOBidResponse *)bid andError:(NSError *)error {
    if (block == nil) {
        AMLogError(@"Mediation manager return block is null.");
        return;
    }
    block(bid, error);
}

@end
