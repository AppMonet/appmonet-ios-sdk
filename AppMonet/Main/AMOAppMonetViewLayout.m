//
// Created by Jose Portocarrero on 2/3/20.
// Copyright (c) 2020 AppMonet. All rights reserved.
//

#import "AMOAppMonetViewLayout.h"
#import "AMOBidResponse.h"
#import "AMOSdkManager.h"
#import "AMOBidManager.h"
#import "AMOAdViewPoolManager.h"
#import "AMOHoldingContainer.h"
#import "AMODispatchState.h"
#import "AMOUtils.h"

@interface AMOAppMonetViewLayout ()
@property(nonatomic, copy) void (^refreshBlock)(void);
@property(nonatomic, weak) UIView *parent;
@property(strong) AMODispatchState *cancelState;
@property(nonatomic) BOOL isRefreshActive;
@end

@implementation AMOAppMonetViewLayout

- (instancetype)initWithAdView:(AMOAdView *)adView andFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.adView = adView;
    }
    return self;
}

- (void)activateRefresh:(AMOBidResponse *)bid andDelegate:(id <AMOAdViewDelegate>)delegate {
    if (bid.refresh.intValue <= 1000 || self.isRefreshActive || bid.interstitial != nil) {
        return;
    }

    if (self.cancelState) {
        self.cancelState.isCancelled = YES;
    }
    __weak typeof(self) weakSelf = self;
    __weak typeof(delegate) weakDelegate = delegate;
    _refreshBlock = ^{
        AMOBidResponse *currentBid = bid;
        AMOSdkManager *manager = [AMOSdkManager get];
        if ([manager.bidManager areBidsAvailableForAdUnit:currentBid.adUnitId andAdSize:nil andFloorCpm:@0
                                     andBidArrayReference:&currentBid andAdType:BANNER andShouldRequestMore:YES]) {
            if (currentBid == nil || currentBid.id == nil) {
                [AMOUtils cancelableDispatchAfter:dispatch_time(DISPATCH_TIME_NOW, (int64_t) (bid.refresh.intValue * NSEC_PER_MSEC))
                                          inQueue:dispatch_get_main_queue() withState:weakSelf.cancelState withBlock:weakSelf.refreshBlock];
                return;
            }
//
            if (![manager.bidManager isValid:currentBid]) {
                AMOBidResponse *nextBid = [manager.bidManager peekNextBid:bid.adUnitId];
                NSNumber *cpm = @(currentBid.cpm.floatValue * 0.8);
                if (nextBid != nil && [manager.bidManager isValid:nextBid] && nextBid.cpm >= cpm) {
                    currentBid = nextBid;
                } else {
                    return;
                }
            }
//
            AMOAdView *nextAdView = [manager.adViewPoolManager requestWithBid:currentBid];
            AMOAdView *adViewToRender = ([nextAdView.getUUID isEqualToString:weakSelf.adView.getUUID]) ? weakSelf.adView : nextAdView;
            if (![adViewToRender getLoaded]) {
                [adViewToRender load];
            }

            adViewToRender.isAdRefreshed = YES;
            [adViewToRender setBid:currentBid];
            [adViewToRender setTrackingBid:currentBid];
            [adViewToRender setState:AD_RENDERED andEventDelegate:weakDelegate];
            [adViewToRender inject:currentBid];
            [[AMOSdkManager.get bidManager] markUsed:currentBid];

            weakSelf.isRefreshActive = NO;
        }
    };
    self.cancelState = [[AMODispatchState alloc] init];
    [AMOUtils cancelableDispatchAfter:dispatch_time(DISPATCH_TIME_NOW, (int64_t) (bid.refresh.intValue * NSEC_PER_MSEC))
                              inQueue:dispatch_get_main_queue() withState:self.cancelState withBlock:_refreshBlock];
    self.isRefreshActive = YES;
}

- (void)destroyAdView:(id <AMOAdViewDelegate>)delegate {
    [_adView invalidateView:YES withDelegate:delegate];
    [self cleanup];
}

- (void)swapViews:(AMOAppMonetViewLayout *)view andDelegate:(id <AMOAdViewDelegate>)delegate {
    if (view != self) {
        if (self.cancelState) {
            self.cancelState.isCancelled = YES;
        }
        [self removeFromSuperview];
        [_parent addSubview:view];
        [self destroyAdView:[_adView adDelegate]];
        _parent = nil;
    } else {
        [_parent addSubview:self];
    }
    [delegate onAdRefreshed:view];
}

- (BOOL)isAdRefreshed {
    return _adView.isAdRefreshed;
}

- (void)cleanup {
    if (self.cancelState) {
        self.cancelState.isCancelled = YES;
    }
    self.isRefreshActive = NO;
    _refreshBlock = nil;
    _parent = nil;
}

- (void)invalidateView:(BOOL)invalidate withDelegate:(id <AMOAdViewDelegate>)bannerDelegate {
    if (_refreshBlock) {
        if (self.cancelState) {
            self.cancelState.isCancelled = YES;
        }
        _refreshBlock = nil;
    }
    [self.adView invalidateView:invalidate withDelegate:bannerDelegate];
}

- (void)didMoveToSuperview {
    if (self.superview) {
        if (![self.superview isKindOfClass:[AMOHoldingContainer class]]) {
            self.parent = self.superview;
            [_adView isAttachedToSuperView:YES];
        } else {
            [_adView isAttachedToSuperView:NO];
        }
    } else if (!_adView.isDealloc) {
        [_adView isAttachedToSuperView:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"rootContainer_attach" object:_adView.uuid userInfo:nil];
    }
}

@end
