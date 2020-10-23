//
// Created by Jose Portocarrero on 11/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>

#define AMGADError(errorCode) [GADRequestError errorWithDomain:kGADErrorDomain code:errorCode userInfo:@{}]

@import GoogleMobileAds;

@class AMOAdView;
@class AMOAdSize;
@class AMOAppMonetViewLayout;

@interface AMCustomEventBanner : NSObject
@end
