//
// Created by Jose Portocarrero on 11/6/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMOAdServerAdRequest.h"

@class GADRequest;
@class GADCustomEventRequest;
@class DFPRequest;


@interface AMODfpAdRequest : AMOAdServerAdRequest
- (instancetype)initWithCustomEventRequest:(GADCustomEventRequest *)customEventRequest;

- (instancetype)initWithDfpRequest:(DFPRequest *)adRequest;

- (DFPRequest *)getDfpRequest;

+ (AMODfpAdRequest *)fromAuctionRequest:(AMOAuctionRequest *)request;
@end
