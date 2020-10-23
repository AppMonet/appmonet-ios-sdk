//
//  AMOMopubBannerAdListener.m
//  AppMonet
//
//  Created by Jose Portocarrero on 10/18/19.
//  Copyright © 2019 AppMonet. All rights reserved.
//

#import "AMOMopubBannerAdListener.h"
#import "AMOSdkManager.h"

@interface AMOMopubBannerAdListener ()
@property(nonatomic, strong) AMOSdkManager *sdkManager;
@property(nonatomic, strong) id <MPAdViewDelegate> originalDelegate;
@property(nonatomic, strong) NSString *adUnitId;
@end

@implementation AMOMopubBannerAdListener

- (instancetype)initWithAdUnitId:(NSString *)adUnitId andMopubAdViewDelegate:(id <MPAdViewDelegate>)originalDelegate
                   andSdkmanager:(AMOSdkManager *)sdkManager {
    if (self = [super init]) {
        _originalDelegate = originalDelegate;
        _adUnitId = adUnitId;
        _sdkManager = sdkManager;
    }
    return self;
}

- (UIViewController *)viewControllerForPresentingModalView {
    if ([_originalDelegate respondsToSelector:@selector(viewControllerForPresentingModalView)]) {
        return [_originalDelegate viewControllerForPresentingModalView];
    }
    return nil;
}

- (void)adViewDidLoadAd:(MPAdView *)view adSize:(CGSize)adSize {
    NSLog(@"banner loaded. Attaching next bid");
    [self setBannerRefreshTimer:view];
    if ([_originalDelegate respondsToSelector:@selector(adViewDidLoadAd:adSize:)]) {
        [_originalDelegate adViewDidLoadAd:view adSize:adSize];
    }
}

- (void)adView:(MPAdView *)view didFailToLoadAdWithError:(NSError *)error {
    NSLog(@"banner failed. Attaching new bid");
    [_sdkManager addBids:view andAdUnitId:_adUnitId];
    if ([_originalDelegate respondsToSelector:@selector(adView:didFailToLoadAdWithError:)]) {
        [_originalDelegate adView:view didFailToLoadAdWithError:error];
    }
}

- (void)setBannerRefreshTimer:(MPAdView *)banner {
    double delayInSeconds = 4;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t) (delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        [_sdkManager addBids:banner andAdUnitId:_adUnitId];
    });
}

- (void)adViewDidLoadAd:(MPAdView *)view {
    if ([_originalDelegate respondsToSelector:@selector(adViewDidLoadAd:)]) {
       [_originalDelegate adViewDidLoadAd:view];
    }
}

- (void)adViewDidFailToLoadAd:(MPAdView *)view {
    if ([_originalDelegate respondsToSelector:@selector(adViewDidFailToLoadAd:)]) {
        [_originalDelegate adViewDidFailToLoadAd:view];
    }
}

- (void)willPresentModalViewForAd:(MPAdView *)view {
    if ([_originalDelegate respondsToSelector:@selector(willPresentModalViewForAd:)]) {
        [_originalDelegate willPresentModalViewForAd:view];
    }
}

- (void)didDismissModalViewForAd:(MPAdView *)view {
    if ([_originalDelegate respondsToSelector:@selector(didDismissModalViewForAd:)]) {
        [_originalDelegate didDismissModalViewForAd:view];
    }
}

- (void)willLeaveApplicationFromAd:(MPAdView *)view {
    if ([_originalDelegate respondsToSelector:@selector(willLeaveApplicationFromAd:)]) {
        [_originalDelegate willLeaveApplicationFromAd:view];
    }
}

@end
