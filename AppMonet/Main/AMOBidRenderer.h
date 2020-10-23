//
// Created by Jose Portocarrero on 11/8/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AMOAdView;
@class AMOBidResponse;
@protocol AMOAdServerAdapter;
@class AMOAppMonetViewLayout;
@class AMOAdSize;


@interface AMOBidRenderer : NSObject
+ (AMOAppMonetViewLayout *)renderBid:(AMOBidResponse *)bidResponse andAdSize:(AMOAdSize *)adSize
                  andAdServerAdapter:(id <AMOAdServerAdapter>)adapter;
@end