//
// Created by Jose Portocarrero on 10/26/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMOAuctionManager.h"
#import "AMOAdView.h"

@class AMODeviceData;
@class AMOAuctionManager;
@protocol AMOAdServerWrapper;
@class AMOAppMonetBidder;
@class AMOAdViewPoolManager;
@class AppMonetConfigurations;
@protocol AMOAuctionManagerDelegate;
@class AMOAppMonetContext;
@class AMOBidManager;
@class AMOPreferences;
@class AMOAdSize;
@class AMOMediationManager;
@class AMOAddBidsManager;

typedef void (^InitializationBlock)(NSError *error);

typedef void (^AMValueBlock)(NSDictionary *, NSError *);

@interface AMOBaseManager : NSObject <AMOAuctionManagerDelegate>

@property(nonatomic, strong, readonly) AMOAppMonetContext *appMonetContext;
@property(nonatomic, strong, readonly) AMODeviceData *deviceData;
@property(nonatomic, strong, readonly) AMOAuctionManager *auctionManager;
@property(nonatomic, strong, readonly) AMOAppMonetBidder *appMonetBidder;
@property(nonatomic, strong, readonly) id <AMOAdServerWrapper> adServerWrapper;
@property(nonatomic, strong, readonly) AMOAdViewPoolManager *adViewPoolManager;
@property(nonatomic, strong, readonly) AMOBidManager *bidManager;
@property(nonatomic, strong, readonly) AMOPreferences *preferences;
@property(nonatomic, copy) InitializationBlock block;
@property(nonatomic) dispatch_source_t cleanTimer;
@property(nonatomic) dispatch_queue_t backgroundQueue;
@property(nonatomic, strong) NSMutableDictionary *sdkConfigurations;
@property(nonatomic, strong) AMOMediationManager *mediationManager;
@property(nonatomic) BOOL isTestMode;
@property(nonatomic, retain) AMOAddBidsManager *addBidsManager;

- (id)initWithApplicationId:(AppMonetConfigurations *)appMonetConfigurations andAdServerWrapper:(id <AMOAdServerWrapper>)adServerWrapper andBlock:(InitializationBlock)block;

- (void)preFetchBids:(NSArray *)adUnitIds;

- (NSDictionary *)getSdkConfigurations;

- (void)indicateRequestAsync:(NSString *)adUnitId andTimeout:(NSNumber *)timeout andAdSize:(AMOAdSize *)adSize andAdType:(AMOAdType)adType
                 andFloorCpm:(NSNumber *)floorCpm withValueBlock:(AMValueBlock)block;

- (void)testMode;

+ (void)testModeEnabled;

- (void)indicateRequest:(NSString *)adUnitId withAdSize:(AMOAdSize *)adSize forAdType:(AMOAdType)adType andFloorCpm:(NSNumber *)floorCpm;

- (void)trackTimeoutEvent:(NSString *)adUnitId withTimeout:(NSNumber *)timeout;

+ (void)enableVerboseLogging:(BOOL)state;

@end
