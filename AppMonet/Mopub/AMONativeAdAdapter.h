//
//  AMONativeAdAdapter.h
//  AppMonet_Mopub
//
//  Created by Jose Portocarrero on 1/3/20.
//  Copyright © 2020 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MoPub.h"
#import "AMOAppMonetViewLayout.h"

@interface AMONativeAdAdapter : NSObject <MPNativeAdAdapter>
@property(nonatomic, weak) AMOAppMonetViewLayout *adView;

- (instancetype)initWithMonetAdView:(AMOAppMonetViewLayout *)adView;

- (void)handleClick;

- (void)adWillLogImpression;

- (UIView *)mainMediaView;

- (void)setupWithAdProperties:(NSDictionary *)info;

@end

