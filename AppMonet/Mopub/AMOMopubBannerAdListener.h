//
//  AMOMopubBannerAdListener.h
//  AppMonet
//
//  Created by Jose Portocarrero on 10/18/19.
//  Copyright © 2019 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPAdView.h"

@class AMOSdkManager;

@interface AMOMopubBannerAdListener : NSObject<MPAdViewDelegate>
- (instancetype)initWithAdUnitId:(NSString *)adUnitId andMopubAdViewDelegate:(id <MPAdViewDelegate>)originalDelegate andSdkmanager:(AMOSdkManager *)sdkManager;
- (void)adViewDidLoadAd:(MPAdView *)view adSize:(CGSize)adSize;

- (void)adView:(MPAdView *)view didFailToLoadAdWithError:(NSError *)error;
@end
