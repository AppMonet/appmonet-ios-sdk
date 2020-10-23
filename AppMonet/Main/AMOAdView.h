//
// Created by Jose Portocarrero on 11/2/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
@import WebKit;
@import SafariServices;
#import "AMOAuctionWebView.h"

@class AMOAdViewContext;
@class AMOBidResponse;
@class AMOAppMonetViewLayout;
@protocol AMOAdServerAdapter;
@protocol AMOAdViewDelegate;
@class AMOAdSize;

typedef enum {
    AD_LOADING = 0, AD_RENDERED = 1, AD_MIXED_USE = 2, AD_OPEN = 3, NOT_FOUND = 4
} AMAdViewState;
#define adViewStateValueString(enum) @[@"LOADING", @"RENDERED", @"MIXED_USE", @"OPEN", @"NOT_FOUND"][enum];

typedef enum {
    NO_FILL = 0, INTERNAL_ERROR = 1, TIMEOUT = 2, UNKNOWN = 3, BAD_REQUEST = 4
} AMErrorCode;
#define errorCodeValueString(enum) @[@"NO_FILL", @"INTERNAL_ERROR", @"TIMEOUT", @"UNKNOWN", @"BAD_REQUEST"][enum];

typedef enum {
    BANNER = 0, INTERSTITIAL = 1, NATIVE = 2
} AMOAdType;

#define adTypeValueString(enum) @[@"banner", @"interstitial", @"native"] [enum];

@interface AMOAdView : WKWebView
@property(nonatomic, strong) AMOBidResponse *bid;
@property(nonatomic) AMAdViewState state;
@property(nonatomic, strong, readonly) NSString *uuid;
@property(nonatomic, strong) UIView *originalContainer;
@property(nonatomic, weak) id <AMOAdViewDelegate> adDelegate;
@property(nonatomic, strong) AMOAppMonetViewLayout *adViewContainer;
@property(nonatomic, assign) BOOL isDealloc;
@property(nonatomic, assign) BOOL isAdRefreshed;

- (instancetype)initWithAdViewContext:(AMOAdViewContext *)adViewContext andHtml:(NSString *)html andUuid:(NSString *)uuid;

- (void)callFinishLoad:(NSString *)renderPixel;

- (void)callJsMethod:(NSString *)method arguments:(NSArray *)args callback:(JavascriptResponseHandler)callback;

- (void)cleanForDealloc;

- (BOOL)getLoaded;

- (NSNumber *)getRenderCount;

- (NSString *)getUUID;

- (NSString *)getWVhash;

- (void)inject:(AMOBidResponse *)bid;

- (void)invalidateView:(BOOL)invalidate withDelegate:(id <AMOAdViewDelegate>)customEventBannerDelegate;

- (BOOL)load;

- (void)markBidInvalid:(NSString *)bidId;

- (void)resize:(AMOAdSize *)adSize;

- (void)setBid:(AMOBidResponse *)bid;

- (void)setState:(AMAdViewState)state andEventDelegate:(id <AMOAdViewDelegate>)delegate;

- (void)setLoaded:(BOOL)isLoaded;

- (void)setTrackingBid:(AMOBidResponse *)bid;

- (void)isAttachedToSuperView:(BOOL)isAttached;

@end

typedef void (^AdViewJsHandler)(AMOAdView *wv, NSArray *args, NSString *callback);

@protocol AMOAdViewDelegate <NSObject>

- (void)adView:(AMOAdView *)adView wasClicked:(NSURL *)url;

- (void)adView:(AMOAdView *)adView willLeaveApplication:(NSURL *)url;

- (void)adView:(AMOAdView *)adView willReturnToApplication:(NSURL *)url;

- (void)adView:(AMOAppMonetViewLayout *)adView adLoaded:(AMOBidResponse *)bid;

- (void)adClosed;

- (void)adView:(AMOAdView *)adView adError:(AMErrorCode)errorCode;

@optional
- (void)onAdRefreshed:(AMOAppMonetViewLayout *)view;
@end
