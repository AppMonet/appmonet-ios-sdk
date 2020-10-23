//
//  AMNativeAdRenderer.m
//  AppMonet_Mopub
//
//  Created by Jose Portocarrero on 1/3/20.
//  Copyright © 2020 AppMonet. All rights reserved.
//

#import <MoPub/MPNativeAds.h>
#import <MoPub/MPLogging.h>
#import "AMNativeAdRenderer.h"
#import "AMONativeAdAdapter.h"

@interface AMNativeAdRenderer () <MPNativeAdRendererImageHandlerDelegate, MPNativeAdRenderer>
@property(nonatomic, strong) UIView <MPNativeAdRendering> *adView;
@property(nonatomic, strong) AMONativeAdAdapter *adapter;
@property(nonatomic, strong) Class renderingViewClass;
@property(nonatomic, strong) MPNativeAdRendererImageHandler *rendererImageHandler;

@end

@implementation AMNativeAdRenderer

- (instancetype)initWithRendererSettings:(id <MPNativeAdRendererSettings>)rendererSettings {
    if (self = [super init]) {
        MPStaticNativeAdRendererSettings *settings = (MPStaticNativeAdRendererSettings *) rendererSettings;
        _renderingViewClass = settings.renderingViewClass;
        _rendererImageHandler = [MPNativeAdRendererImageHandler new];
        _rendererImageHandler.delegate = self;
    }
    return self;
}

+ (MPNativeAdRendererConfiguration *)rendererConfigurationWithRendererSettings:(id <MPNativeAdRendererSettings>)rendererSettings {
    MPNativeAdRendererConfiguration *config = [[MPNativeAdRendererConfiguration alloc] init];
    config.rendererClass = [self class];
    config.rendererSettings = rendererSettings;
    config.supportedCustomEvents = @[@"AMCustomEventNative"];
    return config;
}

- (UIView *)retrieveViewWithAdapter:(id <MPNativeAdAdapter>)adapter error:(NSError *__autoreleasing *)error {
    if (!adapter || ![adapter isKindOfClass:[AMONativeAdAdapter class]]) {
        if (error) {
            *error = MPNativeAdNSErrorForRenderValueTypeError();
        }

        return nil;
    }

    self.adapter = (AMONativeAdAdapter *) adapter;

    MPLogAdEvent([MPLogEvent adShowAttemptForAdapter:NSStringFromClass(self.class)], nil);
    MPLogAdEvent([MPLogEvent adWillAppearForAdapter:NSStringFromClass(self.class)], nil);

    if ([self.renderingViewClass respondsToSelector:@selector(nibForAd)]) {
        self.adView = (UIView <MPNativeAdRendering> *) [[[self.renderingViewClass nibForAd] instantiateWithOwner:nil options:nil] firstObject];
    } else {
        self.adView = [[self.renderingViewClass alloc] init];
    }

    self.adView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    if ([self shouldLoadMediaView]) {
        UIView *mediaView = [self.adapter mainMediaView];
        UIView *mainImageView = [self.adView nativeMainImageView];
        mediaView.frame = mainImageView.bounds;
        mediaView.userInteractionEnabled = YES;
        mainImageView.userInteractionEnabled = YES;

        [mainImageView addSubview:mediaView];
    }

    return self.adView;
}

- (void)adViewWillMoveToSuperview:(UIView *)superview {
    if (superview) {
        if ([self.adView respondsToSelector:@selector(layoutCustomAssetsWithProperties:imageLoader:)]) {
            [self.adView layoutCustomAssetsWithProperties:self.adapter.properties imageLoader:nil];
        }
    }
}


- (BOOL)shouldLoadMediaView {
    return [self.adapter respondsToSelector:@selector(mainMediaView)]
            && [self.adapter mainMediaView]
            && [self.adView respondsToSelector:@selector(nativeMainImageView)];
}

@end
