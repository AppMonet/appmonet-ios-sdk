//
// Created by Jose Portocarrero on 2/3/20.
// Copyright (c) 2020 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AMOAdView.h"
#import "AMOAdSize.h"

@interface AMOAppMonetViewLayout : UIView
@property(nonatomic, weak) AMOAdView *adView;

- (instancetype)initWithAdView:(AMOAdView *)adView andFrame:(CGRect)frame;

- (void)activateRefresh:(AMOBidResponse *)bid andDelegate:(id <AMOAdViewDelegate>)delegate;

- (void)invalidateView:(BOOL)invalidate withDelegate:(id <AMOAdViewDelegate>)bannerDelegate;

- (void)swapViews:(AMOAppMonetViewLayout *)view andDelegate:(id <AMOAdViewDelegate>)delegate;

- (BOOL)isAdRefreshed;
@end
