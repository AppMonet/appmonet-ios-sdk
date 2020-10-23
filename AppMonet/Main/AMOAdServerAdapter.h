//
// Created by Jose Portocarrero on 11/8/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AMOAdSize;
@class AMOAdView;
@class AMOAppMonetViewLayout;
@protocol AMOAdViewDelegate;

@protocol AMOAdServerAdapter <NSObject>

- (id <AMOAdViewDelegate>)getDelegate;

- (void)setAppMonetAdView:(AMOAppMonetViewLayout *)adView;

@end

