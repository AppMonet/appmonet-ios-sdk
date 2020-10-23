//
//  AMONativeAdAdapter.m
//  AppMonet_Mopub
//
//  Created by Jose Portocarrero on 1/3/20.
//  Copyright © 2020 AppMonet. All rights reserved.
//

#import "AMONativeAdAdapter.h"
#import "MPNativeAdAdapter.h"

@interface AMONativeAdAdapter ()
@property(nonatomic, strong) NSMutableDictionary *adProperties;

@end

@implementation AMONativeAdAdapter

@synthesize defaultActionURL;
@synthesize delegate;

- (instancetype)initWithMonetAdView:(AMOAppMonetViewLayout *)adView {
    self = [super init];
    if (self != nil) {
        _adView = adView;
    }
    return self;
}

- (void)setupWithAdProperties:(NSDictionary *)info {
    self.adProperties = [info mutableCopy];
}

- (NSDictionary *)properties {
    return self.adProperties;
}

- (void)handleClick {
    [self.delegate nativeAdDidClick:self];
    MPLogAdEvent([MPLogEvent adTappedForAdapter:NSStringFromClass(self.class)], nil);
}

- (void)adWillLogImpression {
    [self.delegate nativeAdWillLogImpression:self];
}

- (NSURL *)defaultActionURL {
    return nil;
}

- (UIView *)mainMediaView {
    return _adView;
}

- (BOOL)enableThirdPartyClickTracking {
    return NO;
}

@end

