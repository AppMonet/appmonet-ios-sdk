//
// Created by Jose Portocarrero on 11/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class AMOAuctionRequest;
@class AMOBidResponse;
@protocol AMOAdServerAdView;

@protocol AMServerAdRequest
- (AMOAuctionRequest *)apply:(AMOAuctionRequest *)auctionRequest andAdServerAdView:(id <AMOAdServerAdView>)adView;

- (AMOBidResponse *)getBid;

- (NSDate *)getBirthday;

- (NSString *)getContentUrl;

- (NSMutableDictionary *)getCustomTargeting;

- (NSString *)getGender;

- (CLLocation *)getLocation;

- (NSString *)getPublisherProvidedId;

- (BOOL)hasBids;
@end

@interface AMOAdServerAdRequest : NSObject <AMServerAdRequest>
@property(nonatomic, strong) AMOBidResponse *bid;

- (NSMutableDictionary *)filterTargeting:(NSMutableDictionary *)targeting;

@end
