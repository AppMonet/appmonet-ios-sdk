//
// Created by Jose Portocarrero on 10/27/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIView.h>
#import <WebKit/WebKit.h>
#import "AMOBaseManager.h"
#import "AMOAdView.h"

@class AMODeviceData;
@class AMOAuctionWebView;

@protocol AMOAuctionManagerDelegate;
@class AMOPreferences;
@class AMOAppMonetContext;
@class AMOBidManager;
@class AMOAuctionRequest;
@protocol AMOAdServerAdView;
@class AMOAdServerAdRequest;
@protocol AMServerAdRequest;
@class AMOBidResponse;
@class AMOAdViewPoolManager;
@class AMOBaseManager;
@class AMOAdSize;
@class AMOReadyCallbackManager;
@class AMOAdView;

typedef void (^AMValueBlock)(NSDictionary *, NSError *);

@interface AMOAuctionManager : NSObject

@property(nonatomic, strong, readonly) AMODeviceData *deviceData;
@property(nonatomic, strong, readonly) AMOAppMonetContext *appMonetContext;
@property(nonatomic, strong) AMOAuctionWebView *auctionWebView;
@property(nonatomic, weak) id <AMOAuctionManagerDelegate> delegate;

- (id)initWithDeviceData:(AMODeviceData *)deviceData andBidManager:(AMOBidManager *)bidManager
      andAppMonetContext:(AMOAppMonetContext *)applicationContext andPreferences:(AMOPreferences *)preferences
    andAdViewPoolManager:(AMOAdViewPoolManager *)adViewPoolManager andExecutionQueue:(dispatch_queue_t)executionQueue
             andDelegate:(id <AMOAuctionManagerDelegate>)delegate andRootContainer:(UIView *)rootContainer;


- (nonnull AMOAuctionRequest *)addRawBid:(id <AMOAdServerAdView>)adView andServerAdRequest:(id <AMServerAdRequest>)baseRequest
                  andBidResponse:(nonnull AMOBidResponse *)bid;


- (AMOAuctionRequest *)attachBid:(id <AMOAdServerAdView>)adView andAdServerAdRequest:(id <AMServerAdRequest>)adRequest;

- (void)attachBidAsync:(id <AMOAdServerAdView>)adView andAdServerAdRequest:(id <AMServerAdRequest>)adRequest
            andTimeout:(NSNumber *)timeout andValueBlock:(void (^)(AMOAuctionRequest *auctionRequest))block;

- (AMOBidResponse *)getRawBid:(NSString *)adUnitId;

- (void)indicateRequest:(NSString *)adUnitId withAdSize:(AMOAdSize *)adSize forAdType:(AMOAdType)adType andFloorCpm:(NSNumber *)floorCpm;

- (void)indicateRequestAsync:(NSString *)adUnitId andTimeout:(NSNumber *)timeout
                   andAdSize:(AMOAdSize *)adSize andAdType:(AMOAdType)adType andFloorCpm:(NSNumber *)floorCpm
              withValueBlock:(AMValueBlock)block;

- (void)syncLogger:(NSString *)logLevel;

- (void)trackRequest:(NSString *)adUnitId andSource:(NSString *)source;

- (void)markBidsUsed:(NSString *)adUnitId andBids:(nullable AMOBidResponse *)bids;

- (void)trackEvent:(NSString *)eventName withDetail:(NSString *)detail andKey:(NSString *)key andValue:(NSNumber *)value
    andCurrentTime:(NSNumber *)currentTime;

- (void)testMode;

@end
