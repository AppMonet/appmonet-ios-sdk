//
// Created by Jose Portocarrero on 11/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AMOAdServerAdView;
@class AMOAdServerAdRequest;
@class AMORequestData;
@class AMOAuctionRequest;
@protocol AMServerAdRequest;
@class AMOBidResponse;

@interface AMOAuctionRequest : NSObject
@property(nonatomic, strong) NSMutableDictionary *networkExtras;
@property(nonatomic, strong) NSMutableDictionary *adMobExtras;
@property(nonatomic, strong) NSMutableDictionary *targeting;
@property(nonatomic, strong) AMORequestData *requestData;
@property(nonatomic, strong) AMOBidResponse *bid;
@property(nonatomic, strong) NSString *adUnitId;

+ (AMOAuctionRequest *)from:(id <AMOAdServerAdView>)adServerAdView andAdServerAdRequest:(id <AMServerAdRequest>)request;

@end
