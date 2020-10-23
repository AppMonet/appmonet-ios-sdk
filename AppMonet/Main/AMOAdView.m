//
// Created by Jose Portocarrero on 11/2/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMOAdView.h"
#import "AMOAdViewContext.h"
#import "AMOAdSize.h"
#import "AMOConstants.h"
#import "AMOBidResponse.h"
#import "AMOUtils.h"
#import "AMOSdkManager.h"
#import "AMOAdViewPoolManager.h"
#import "AMOHttpUtil.h"
#import "AMOAppAudienceViewController.h"
#import "AMOMonetSchemaHandler.h"
#import "AMOAppMonetViewLayout.h"
#import "AMOContentBlocker.h"
#import <StoreKit/SKAdNetwork.h>
#import <StoreKit/StoreKit.h>
#import "AMODeviceData.h"
#import "AMOAppMonetContext.h"

@interface AMOAdView () <UIGestureRecognizerDelegate, AMAppAudienceViewControllerDelegate, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, SKStoreProductViewControllerDelegate>
@property(nonatomic, strong) NSURL *landingPageURL;
@property(nonatomic, assign) BOOL hasLoadedAd;
@property(nonatomic, assign) BOOL isLandingPageOpened;
@property(nonatomic) NSMutableDictionary *jsHandlers;
@property(nonatomic, strong) NSMutableDictionary *bids;
@property(nonatomic, strong) AMOAdSize *adSize;
@property(nonatomic, strong) NSString *url;
@property(nonatomic, strong) NSString *html;
@property(nonatomic, strong) AMOBidResponse *bidForTracking;
@property(nonatomic, assign) BOOL hasCallFinishLoad;
@property(nonatomic, assign) BOOL wasClicked;
@property(nonatomic, assign) BOOL isOpening;
@property(nonatomic, assign) BOOL isObserving;
@property(nonatomic, assign) BOOL hasRenderedSufficiently;
@property(nonatomic, assign) NSInteger *renderCount;
@property(nonatomic, strong) NSString *wvHash;
@property(nonatomic, strong) UITapGestureRecognizer *gr;
@property(nonatomic, strong) NSMutableDictionary *innerCorsDict;
@property(nonatomic, strong) AMOAppAudienceViewController *appAudienceView;
@end

@implementation AMOAdView

@synthesize adDelegate;

- (instancetype)initWithAdViewContext:(AMOAdViewContext *)adViewContext andHtml:(NSString *)html andUuid:(NSString *)uuid {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.allowsInlineMediaPlayback = YES;
    config.mediaPlaybackAllowsAirPlay = YES;

    if (@available(iOS 11, *)) {
        [WKContentRuleListStore.defaultStore
                compileContentRuleListForIdentifier:@"ContentBlockingRules"
                             encodedContentRuleList:[AMOContentBlocker blockedResourcesList:adViewContext.url]
                                  completionHandler:^(WKContentRuleList *ruleList, NSError *error) {
                                      if (error == nil) {
                                          [config.userContentController addContentRuleList:ruleList];
                                      }
                                  }];
        AMOMonetSchemaHandler *handler = [[AMOMonetSchemaHandler alloc] init];
        [config setURLSchemeHandler:handler forURLScheme:@"monet"];
    }
    self = [super initWithFrame:CGRectZero configuration:config];
    if (self) {
        self.scrollView.scrollEnabled = NO;
        self.scrollView.bounces = NO;
        _isDealloc = NO;
        _adSize = [AMOAdSize from:adViewContext.width andHeight:adViewContext.height
               andAdServerWrapper:[AMOSdkManager.get adServerWrapper]];
        _url = adViewContext.url;
        _html = html;
        _uuid = (uuid) ? uuid : [[NSUUID UUID] UUIDString];
        _wvHash = adViewContext.toHash;
        _hasLoadedAd = false;
        _hasCallFinishLoad = false;
        _wasClicked = false;
        _isOpening = false;
        _hasRenderedSufficiently = false;
        _renderCount = 0;
        self.contentMode = UIViewContentModeScaleToFill;
        _innerCorsDict = [[NSMutableDictionary alloc] init];
        self.opaque = NO;
        self.backgroundColor = UIColor.clearColor;
        self.scrollView.backgroundColor = UIColor.clearColor;
        self.navigationDelegate = self;
        self.UIDelegate = self;
        [self setupJSHandlers];
        [self constrainSizing];
        [self bindApplicationState];
        _gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture)];
        [_gr setNumberOfTapsRequired:1];
        _gr.delegate = self;
        [self addGestureRecognizer:_gr];
        CGRect sizeFrame = self.frame;
        sizeFrame.size.height = _adSize.height.floatValue; // [_adSize.getHeightInPixels floatValue];
        sizeFrame.size.width = _adSize.width.floatValue; // [_adSize.getWidthInPixels floatValue];
        self.frame = sizeFrame;

        if (@available(iOS 11.0, *)) {
            self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }

        _bids = [NSMutableDictionary dictionary];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackVastEnvents:) name:@"vastEvent" object:nil];
        _isObserving = YES;
        self.adViewContainer = [self buildContainer:sizeFrame];
        // we need to notify everyone that new adview
        // was created.. :)
        if (!adViewContext.explicitlyCreated) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"helperCreated" object:nil userInfo:@{
                    @"wvUUID": _uuid,
                    @"context": [adViewContext toDictionary],
            }];
        }
        [[self.configuration userContentController] addScriptMessageHandler:self name:@"monet"];
    }
    return self;
}

#pragma mark - Private Methods

- (AMOAppMonetViewLayout *)buildContainer:(CGRect)frame {
    AMOAppMonetViewLayout *viewLayout = [[AMOAppMonetViewLayout alloc] initWithAdView:self andFrame:frame];
    [viewLayout insertSubview:self atIndex:0];
    return viewLayout;
}

#pragma mark - WKWebView Callback

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (am_obj_isDictionary(message.body)) {
        NSString *method = [message.body objectForKey:kAMOWebViewJsMethod];
        NSArray *args = [message.body objectForKey:kAMOWebViewJsArgs];
        NSString *callback = [message.body objectForKey:kAMOWebViewJsCall];
        [self dispatchJsCall:method args:args callback:callback];
    }
}

#pragma mark - AppAudience Delegates

- (void)appAudienceLoading:(AMOAppAudienceViewController *)appAudience {
    self.frame = appAudience.view.bounds;
    [appAudience.view addSubview:self];
}

- (void)appAudienceDismissing:(AMOAppAudienceViewController *)appAudience {
    [self removeFromParent];
    self.frame = _originalContainer.bounds;
    [_originalContainer addSubview:self];
    _appAudienceView = nil;
    _originalContainer = nil;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    // do nothing..
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (error == nil) {
        return;
    }

    // we don't care..
    if (error.code == NSURLErrorCancelled) {
        return;
    }

    if (!self.hasLoadedAd) {
        AMLogError(@"Error loading webview. %@", error);
        if (self.adDelegate) {
            [self.adDelegate adView:self adError:INTERNAL_ERROR];
        }
    }
}

- (void)cleanLocal {
    [self.jsHandlers removeAllObjects];
    self.jsHandlers = nil;
    _gr = nil;
}

- (void)cleanGestureRecognizer {
    _gr.delegate = nil;
    [_gr removeTarget:self action:@selector(handleGesture)];
    adDelegate = nil;
    [self removeGestureRecognizer:_gr];
}

- (void)cleanForDealloc {
    // make sure we run this on the main queue (UI thread)
    dispatch_async(dispatch_get_main_queue(), ^{
        _isDealloc = YES;
        if (_appAudienceView) {
            [_appAudienceView close];
        }

        [[[AMOSdkManager get] adViewPoolManager] removeViewWithUUID:_uuid andShouldAdViewBeDestroyed:false];
        self.navigationDelegate = nil;
        self.UIDelegate = nil;

        if (_isObserving) {
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            _isObserving = NO;
        }

        [self cleanLocal];
        [self cleanGestureRecognizer];
        [_adViewContainer removeFromSuperview];
        _adViewContainer.adView = nil;
        [self removeFromParent];
        _adViewContainer = nil;
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        [self stopLoading];
        [[self.configuration userContentController] removeAllUserScripts];
        [[self.configuration userContentController] removeScriptMessageHandlerForName:@"monet"];
    });
}

- (BOOL)getLoaded {
    return _hasLoadedAd;
}

- (NSNumber *)getRenderCount {
    return nil;
}

- (NSString *)getUUID {
    return _uuid;
}

- (NSString *)getWVhash {
    return _wvHash;
}

- (void)inject:(AMOBidResponse *)bid {
    _hasCallFinishLoad = false;
    _hasRenderedSufficiently = false;
    _renderCount += 1;
    if (bid.url != nil && [bid.url caseInsensitiveCompare:_url] != NSOrderedSame) {
        return;
    }

    NSNumber *pixelBidWidth = [AMOUtils asIntPixels:bid.width];
    NSNumber *realWidth = @(self.frame.size.width);

    if (([realWidth intValue] == 0 && bid.width != _adSize.width) ||
            ([realWidth intValue] > 0 && pixelBidWidth != realWidth)) {
        AMLogDebug(@"bid should be rendered at a different size: resizing");
        [self resizeWithBid:bid];
    }

    // video rendering
    if (bid.nativeRender) {
        [self injectWithHtml:bid.adm];
        _bids[bid.id] = bid.renderPixel;
        return;
    }
    __weak AMOAdView *weakSelf = self;
    [self onAdViewSdkLoaded:^(void) {
        if (weakSelf != nil) {
            NSMutableArray *args = [NSMutableArray array];
            [args addObject:[AMOUtils encodeBase64:bid.adm]];
            [args addObject:[bid.width stringValue]];
            [args addObject:[bid.height stringValue]];
            [weakSelf callJsMethod:@"render" arguments:args callback:^(NSDictionary *response, NSError *error) {
                [weakSelf callFinishLoad:bid.renderPixel];
            }];
        }
    }];
}

- (void)injectWithHtml:(NSString *)html {
    __weak AMOAdView *weakSelf = self;
    [self onAdViewSdkLoaded:^{
        AMLogDebug(@"requesting inject of bid");
        if (weakSelf != nil) {
            NSMutableArray *args = [NSMutableArray array];
            [args addObject:[AMOUtils encodeBase64:html]];
            [weakSelf callJsMethod:@"inject" arguments:args callback:nil];
        }
    }];
}

- (void)invalidateView:(BOOL)invalidate withDelegate:(id <AMOAdViewDelegate>)bannerDelegate {
    if (invalidate) {
        [self markMopubImpressionEnded];
    }

    AMOAdViewPoolManager *adViewPoolManager = [[AMOSdkManager get] adViewPoolManager];

    if (![adViewPoolManager canRelease:self]) {
        if (adDelegate == bannerDelegate) {
            if (_bid != nil) {
                AMLogInfo(@"hiding: %@", _bid.url);
            }

            [self setState:AD_LOADING andEventDelegate:nil];

        }
        return;
    }
    self.adDelegate = nil;
    AMLogDebug(@"adView marked for removal -> %@", _uuid);
    if (_bid == nil || !invalidate || _bid.nativeRender) {
        [adViewPoolManager removeAdView:self andShouldAdViewBeDestroyed:YES andShouldForceDestroy:YES];
        return;
    }

    [self cleanForDealloc];
}

- (void)returnJs:(NSString *)callback data:(NSObject *)data {
    NSString *json;
    if (!data) {
        json = @"{}";
    } else if ([data isKindOfClass:[NSDictionary class]] || [data isKindOfClass:[NSArray class]]) {
        json = [AMOUtils toJson:data];
    } else if ([data isKindOfClass:[NSString class]]) {
        json = (NSString *) data;
    }

    NSString *jsString;
    if (callback == nil) {
        jsString = [NSString stringWithFormat:@"window.document.write(%@);", json];
    } else {
        jsString = [NSString stringWithFormat:@"window['%@'](%@);", callback, json];
    }

    __weak typeof(self) this = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!this) {
            AMLogDebug(@"Attempt to execute js in destroyed webView");
            return;
        }

        @try {
            [this evaluateJavaScript:jsString completionHandler:nil];
        } @catch (NSException *exp) {
            AMLogWarn(@"Failed to execute javascript: %@", exp);
        }
    });
}

- (BOOL)load {
    if (!am_obj_isString(_html) || !am_obj_isString(_url)) {
        return NO;
    }
    [self loadHTMLString:_html baseURL:[NSURL URLWithString:_url]];
    return YES;
}

- (void)markBidInvalid:(NSString *)bidId {
    [self callJsMethod:@"markInvalid" arguments:@[bidId] callback:nil];
}

- (void)setBid:(AMOBidResponse *)bid {
    _bid = bid;
}

- (void)setState:(AMAdViewState)state andEventDelegate:(id <AMOAdViewDelegate>)delegate {
    if (state != _state && state == AD_RENDERED && !_hasCallFinishLoad) {
        AMLogWarn(@"attempt to set to rendered before finish load called");
    }
    __weak AMOAdView *weakSelf = self;
    switch (state) {
        case AD_RENDERED: {
            self.adDelegate = delegate;
            [self detachHidden];
            [self initForCreative:delegate];
            _state = AD_RENDERED;
            [self onAdViewSdkLoaded:^{
                if (weakSelf != nil) {
                    AMLogDebug(@"stateChange called | RENDERING");
                    [weakSelf callJsMethod:@"stateChange" arguments:@[@"RENDERING"] callback:nil];
                }
            }];
            break;
        }
        case AD_LOADING: {
            // NOTE: why do we do this?
            self.adDelegate = nil;
            _state = AD_LOADING;
            [self onAdViewSdkLoaded:^{
                AMLogDebug(@"stateChange called | LOADING");
                if (weakSelf != nil) {
                    [weakSelf callJsMethod:@"stateChange" arguments:@[@"LOADING"] callback:nil];
                }
            }];
            break;
        }
        default: {
            break;
        }
    }
}


- (void)setLoaded:(BOOL)isLoaded {
    self.hasLoadedAd = isLoaded;
}

- (void)setTrackingBid:(AMOBidResponse *)bid {
    _bidForTracking = bid;
}

- (void)isAttachedToSuperView:(BOOL)isAttached {
    [self callJsMethod:@"attachChange" arguments:@[(isAttached) ? @"true" : @"false"] callback:nil];
}


- (BOOL)                         gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)applicationStateChange:(NSNotification *)notification {
    if (self.isLandingPageOpened) {
        AMLogDebug(@"entering foreground from ad!!! - %@", notification);
        self.isLandingPageOpened = NO;

        if (self.adDelegate) {
            [self.adDelegate adView:self willLeaveApplication:self.landingPageURL];
        }
    }
}

- (void)bindApplicationState {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationStateChange:)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)callFinishLoad:(NSString *)renderPixel {
    _hasCallFinishLoad = true;
    [AMOHttpUtil firePixel:renderPixel andPixelEvents:AMImpression];
    AMLogDebug(@"fiLoad");

    if (self.adDelegate == nil) {
        AMLogWarn(@"impression available while in unavailable state. Stopping.");
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.adDelegate) {
            [_adViewContainer activateRefresh:_bidForTracking andDelegate:adDelegate];
            [self.adDelegate adView:_adViewContainer adLoaded:self.bid];
        }
    });
}

- (void)constrainSizing {
    self.scrollView.scrollEnabled = NO;
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
}

- (void)detachHidden {
    if (self.isHidden) {
        self.hidden = NO;
    }
    [_adViewContainer removeFromSuperview];
}

- (void)initForCreative:(id <AMOAdViewDelegate>)delegate {
    self.adDelegate = delegate;
}

- (void)markMopubImpressionEnded {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"helperRespond" object:nil userInfo:@{@"data": @"mpImpEnded"}];
    [self callJsMethod:@"impressionEnded" arguments:@[@"ended"] callback:nil];
}

- (void)removeFromParent {
    [self removeFromSuperview];
}

- (void)resize:(AMOAdSize *)adSize {
    CGRect newFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
            [adSize.width floatValue], [adSize.height floatValue]);
    self.frame = newFrame;
    _adViewContainer.frame = newFrame;
}

- (void)resizeWithBid:(AMOBidResponse *)bid {
    CGRect newFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
            [bid.width floatValue], [bid.height floatValue]);

    self.frame = newFrame;
    _adViewContainer.frame = newFrame;
}

- (void)trackVastEnvents:(NSNotification *)notification {
    NSDictionary *messagePayload = notification.userInfo;
    NSString *trackingEvent = messagePayload[@"vastTrackingEvent"];
    NSString *trackingBid = messagePayload[@"vastTrackingBidId"];
    for (NSString *key in _bids) {
        @autoreleasepool {
            if ([key isEqualToString:trackingBid]) {
                NSString *trackingPixel = _bids[key];
                if ([trackingEvent isEqualToString:@"start"]) {
                    if (!_hasRenderedSufficiently) {
                        [self callFinishLoad:_bids[key]];
                    } else {
                        AMLogDebug(@"rendering second impression into slot");
                    }
                } else if ([trackingEvent isEqualToString:@"Impression"]) {
                    [AMOHttpUtil firePixel:trackingPixel andPixelEvents:AMVastImpression];
                } else if ([trackingEvent isEqualToString:@"firstQuartile"]) {
                    _hasRenderedSufficiently = true;
                    if (!_hasCallFinishLoad) {
                        AMLogWarn(@"first quartile called without impression.");
                    }
                    [AMOHttpUtil firePixel:trackingPixel andPixelEvents:AMVastFirstQuartile];
                } else if ([trackingEvent isEqualToString:@"midpoint"]) {
                    [AMOHttpUtil firePixel:trackingPixel andPixelEvents:AMVastMidpoint];
                } else if ([trackingEvent isEqualToString:@"thirdquartile"]) {
                    [AMOHttpUtil firePixel:trackingPixel andPixelEvents:AMVastThirdQuartile];
                } else if ([trackingEvent isEqualToString:@"complete"]) {
                    [AMOHttpUtil firePixel:trackingPixel andPixelEvents:AMVastComplete];
                } else if ([trackingEvent isEqualToString:@"error"]) {
                    [AMOHttpUtil firePixel:trackingPixel andPixelEvents:AMVastError];
                } else if ([trackingEvent isEqualToString:@"failload"]) {
                    if (!_hasCallFinishLoad && self.adDelegate) {
                        [self.adDelegate adView:self adError:NO_FILL];
                    } else if (!_hasRenderedSufficiently) {
                        AMLogWarn(@"attempt to call failLoad after finishLoad");
                    }
                } else {
                    //                AMLogInfo(@"logging vast event: %@ for bid %@", vastTracking.event, vastTracking.bidId);
                }
                return;
            }
        }
    }
}

- (WKWebView *)        webView:(WKWebView *)webView
createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
           forNavigationAction:(WKNavigationAction *)navigationAction
                windowFeatures:(WKWindowFeatures *)windowFeatures {
    // Open any links to new windows in the current WKWebView rather than create a new one
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

/*****REFACTOR*********/
/**
 * This method is triggered when an iframe is loaded by the webview. It is here where we check if the monet:// protocol
 * is defined as the iframe src so we can parse out the query request.
 *
 * @param webView  The webview loading the iframe.
 * @param request   The request url.
 * @param navigationType The type of navigation that loaded the iframe. We don't care about this.
 * @return We don't care. It returns to internal implementation of UIWebView. I h   ave no idea what yes or no will do lol.
 */
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if ([[navigationAction.request.URL scheme] isEqualToString:AMWebViewJSAgentGlobal]) {
        return decisionHandler(WKNavigationActionPolicyCancel);
    } else if (![[navigationAction.request.URL absoluteString] hasPrefix:_url] && navigationAction.targetFrame.isMainFrame) {
        [self openSKAdNetworkAppStore:self.bid.extras withHandler:^(BOOL didHandle) {
            if (didHandle) {
                _wasClicked = false;
                return decisionHandler(WKNavigationActionPolicyCancel);
            }

            if (_wasClicked && !_isOpening) {
                AMLogDebug(@"opening clicked ad in browser");
                [self stopLoading];
                _isOpening = true;
                if ([[navigationAction.request.URL scheme] isEqualToString:@"about"]) {
                    AMLogDebug(@"Ignoring attempt to open about schema in new window");
                    return decisionHandler(WKNavigationActionPolicyCancel);
                }
                [self openClickedUrl:[navigationAction.request.URL absoluteString]];
                _isOpening = false;
                _wasClicked = false;
                return decisionHandler(WKNavigationActionPolicyCancel);
            }
            return decisionHandler(WKNavigationActionPolicyCancel);
        }];
        return;
    }
    return decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)openSKAdNetworkAppStore:(NSDictionary *)params withHandler:(void (^)(BOOL))handler {
    if (params == nil || params[@"skadn"] == nil) {
        return handler(NO);
    }

    if (@available(iOS 11.3, *)) {
        NSDictionary *skadn = params[@"skadn"];
        NSMutableDictionary *productParameters = [[NSMutableDictionary alloc] init];
        productParameters[SKStoreProductParameterAdNetworkAttributionSignature] = skadn[@"signature"];
        productParameters[SKStoreProductParameterITunesItemIdentifier] = skadn[@"itunesitem"];
        productParameters[SKStoreProductParameterAdNetworkIdentifier] = skadn[@"network"];
        productParameters[SKStoreProductParameterAdNetworkCampaignIdentifier] = @([skadn[@"campaign"] intValue]);
        productParameters[SKStoreProductParameterAdNetworkTimestamp] = @([skadn[@"timestamp"] intValue]);

        if (@available(iOS 14, *)) {
            NSString *skAdNetworkVersion = skadn[@"version"];
            if ([skAdNetworkVersion isEqualToString:@"2.0"]) {
                productParameters[@"adNetworkPayloadVersion"] = skAdNetworkVersion;
                productParameters[@"adNetworkSourceAppStoreIdentifier"] = @([skadn[@"sourceapp"] intValue]);
            }
        }

        productParameters[SKStoreProductParameterAdNetworkNonce] = [[NSUUID alloc] initWithUUIDString:skadn[@"nonce"]];
        dispatch_async(dispatch_get_main_queue(), ^{
            SKStoreProductViewController *adController = [[SKStoreProductViewController alloc] init];
            adController.delegate = self;

            __weak typeof(self) this = self;
            [adController loadProductWithParameters:productParameters completionBlock:^(BOOL result, NSError *error) {
                if (!result || error) {
                    if (error) {
                        AMLogError(@"Error loading product: %@", error);
                    }
                    return handler(NO);
                }

                if (this == nil) {
                    return handler(NO);
                }

                UIViewController *currentVC = [this currentViewController];
                if (!currentVC) {
                    return handler(NO);
                }

                [currentVC presentViewController:adController animated:YES completion:^{
                    AMLogInfo(@"Presented app store -- success");
                }];
                return handler(YES);
            }];
        });
        return;
    }

    return handler(NO);
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

- (UIViewController *)currentViewController {
    /// Finds the view's view controller.
    Class vcc = [UIViewController class];
    UIResponder *responder = self;
    while ((responder = [responder nextResponder]))
        if ([responder isKindOfClass:vcc])
            return (UIViewController *) responder;
    return nil;
}

- (void)dispatchJsCall:(NSString *)method args:(NSArray *)args callback:(NSString *)callback {
    @autoreleasepool {
        __weak typeof(self) this = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (!this || !this.jsHandlers) {
                return;
            }

            AdViewJsHandler handler = this.jsHandlers[method];
            if (!handler) {
                AMLogDebug(@"unknown method called from js: %@", method);
                return;
            }
            handler(this, args, callback);
        });
    }
}

- (void)handleGesture {
    _wasClicked = true;
}

- (void)onAdViewSdkLoaded:(void (^)(void))block {
    if ([[[AMOSdkManager get] adViewPoolManager] isAdViewReady:_uuid]) {
        AMLogDebug(@"adView already loaded. Executing immediately");
        if (block != nil) {
            block();
        } else {
            AMLogError(@"AMOAdView onAdViewSdkLoaded block is null");
        }
        return;
    }
    [[[AMOSdkManager get] adViewPoolManager] onAdViewReady:_uuid andBlockCallback:block];
}

- (void)openClickedUrl:(NSString *)url {
    AMLogInfo(@"opening landing page in browser. url : %@", url);
    // get the landing page URL...
    self.landingPageURL = [[NSURL alloc] initWithString:url];

    if (_bid != nil) {
        AMLogDebug(@"firing click pixel %@", _bid.clickPixel);
        [AMOHttpUtil firePixel:_bid.clickPixel];
    }

    // open url will happen in a new window..
    // we will consider this opening
    [self.adDelegate adView:self willLeaveApplication:self.landingPageURL];

    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:[[NSURL alloc] initWithString:[self processClickUrl:url]] options:@{} completionHandler:nil];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[self processClickUrl:url]]];
    }

    if (self.adDelegate) {
        [self.adDelegate adView:self wasClicked:self.landingPageURL];
    }
}

- (NSString *)processClickUrl:(NSString *)url {
    NSString *redirectUrl = [[AMOSdkManager get] getSdkConfigurations][kAMORedirectUrl];
    if (redirectUrl != nil || redirectUrl.length > 0) {
        NSDictionary *userDataMap = @{
                @"D": [[[AMOSdkManager get] deviceData] advertisingId],
                @"b": [[[AMOSdkManager get] deviceData] getBundleName],
                @"aid": [[[AMOSdkManager get] appMonetContext] applicationId],
                @"ts": [AMOUtils getCurrentMillis]
        };
        NSString *userDataJson = [AMOUtils toJson:userDataMap];
        if (userDataJson == nil) {
            userDataJson = @"{}";
        }
        NSString *encodeData = [NSString stringWithFormat:@"&p=%@", [[AMOUtils encodeBase64:userDataJson] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        return [NSString stringWithFormat:@"%@%@%@", redirectUrl, [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]], encodeData];
    }
    return url;
}

- (void)setupJSHandlers {
    self.jsHandlers = [NSMutableDictionary dictionaryWithDictionary:@{
            @"ajax": ^(AMOAuctionWebView *wv, NSArray *args, NSString *callback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [AMOHttpUtil makeRequest:wv andRequestString:args[0] andCallback:callback];
                });
            },
            @"consoleLog": ^(AMOAdView *wv, NSArray *args, NSString *callback) {
                [AMOUtils logFromJS:callback message:args];
            },
            @"finish": ^(AMOAdView *wv, NSArray *args, NSString *callback) {
                [wv returnJs:callback data:@"true"];
            },
            @"requestSelfDestroy": ^(AMOAdView *wv, NSArray *args, NSString *callback) {
                // remove it
                // validate the args
                NSDictionary *wvData = @{
                        kAMWvUuidKey: wv.getUUID,
                };

                [[NSNotificationCenter defaultCenter] postNotificationName:kAMDestroyHelperNotification object:nil userInfo:wvData];
                [wv returnJs:callback data:@"true"];
            },
            @"markReady": ^(AMOAdView *webview, NSArray *args, NSString *callback) {
                NSString *uuid = webview.uuid;
                if (uuid) {
                    self.hasLoadedAd = YES;
                    [[[AMOSdkManager get] adViewPoolManager] markAdViewAsReady:uuid];
                    [[[AMOSdkManager get] adViewPoolManager] triggerNotification:uuid andMessage:@"__ready__"
                                                                    andArguments:nil];
                    [[[AMOSdkManager get] adViewPoolManager] triggerNotification:uuid andMessage:@"helperRespond"
                                                                    andArguments:@{@"adViewUuid": uuid, @"data": @{@"__ready__": uuid}}];
                    [webview returnJs:callback data:@"true"];
                }
            },
            @"getHelperCreatedAt": ^(AMOAdView *wv, NSArray *args, NSString *callback) {
                [wv returnJs:callback data:nil];
            },
            @"getLayoutState": ^(AMOAdView *wv, NSArray *args, NSString *callback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [wv returnJs:callback data:(wv.superview == nil) ? @"'detached_window'" : @"'attached_window'"];
                });
            },
            @"getRefCount": ^(AMOAdView *wv, NSArray *args, NSString *callback) {
                [wv returnJs:callback data:[[[[AMOSdkManager get] adViewPoolManager] getReferenceCount:_uuid] stringValue]];
            },
            @"setCookiePolicy": ^(AMOAuctionWebView *wv, NSArray *args, NSString *callback) {
                if (args.count != 1 || !am_obj_isString(args[0])) {
                    AMLogDebug(@"invalid sCP a");
                    [wv returnJs:callback data:@"false"];
                    return;
                }

                NSString *pol = args[0];
                if ([pol isEqualToString:@"always"]) {
                    [self setCookiePolicy:NSHTTPCookieAcceptPolicyAlways];
                } else if ([pol isEqualToString:@"never"]) {
                    [self setCookiePolicy:NSHTTPCookieAcceptPolicyNever];
                } else if ([pol isEqualToString:@"main_frame"]) {
                    [self setCookiePolicy:NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain];
                } else {
                    [wv returnJs:callback data:@"false"];
                    return;
                }
                [wv returnJs:callback data:@"true"];
            },
            @"wvUUID": ^(AMOAdView *wv, NSArray *args, NSString *callback) {
                [wv returnJs:callback data:[NSString stringWithFormat:@"'%@'", _uuid]];
            },
            @"respond": ^(AMOAdView *webview, NSArray *args, NSString *callback) {
                NSMutableDictionary *dictArgs = [NSMutableDictionary dictionaryWithCapacity:2];
                dictArgs[@"adViewUuid"] = _uuid;
                dictArgs[@"data"] = args[0];
                [[[AMOSdkManager get] adViewPoolManager] triggerNotification:_uuid andMessage:@"helperRespond" andArguments:dictArgs];
                [webview returnJs:callback data:@"true"];
                dictArgs = nil;
            },
            @"closeInterstitial": ^(AMOAdView *webview, NSArray *args, NSString *callback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.adDelegate adClosed];
                });
                [webview returnJs:callback data:@"true"];
            }
    }];
}

- (void)callJsMethod:(NSString *)method arguments:(NSArray *)args callback:(JavascriptResponseHandler)callback {
    @autoreleasepool {
        NSString *cbIdentifier = [AMOUtils uuid];
        NSString *callbackFn = [NSString
                stringWithFormat:@"function (res){ webkit.messageHandlers.monet.postMessage({args:[res], method: '%@', fn: 'noop'}); }",
                                 cbIdentifier
        ];

        NSString *jsonArgs = [AMOUtils toJson:args];
        NSString *jsString = [NSString
                stringWithFormat:@"window['%@']['%@'](%@, %@);", AMWebViewJSAgentGlobal, method, jsonArgs, callbackFn];

        __weak typeof(self) this = self;
        @synchronized (this.jsHandlers) {
            this.jsHandlers[cbIdentifier] = ^(AMOAuctionWebView *wv, NSArray *responseArgs, NSString *fn) {
                if (this && this.jsHandlers && cbIdentifier) {
                    @synchronized (this.jsHandlers) {
                        this.jsHandlers[cbIdentifier] = nil; // only execute once
                    }
                }

                NSDictionary *response = @{
                        @"args": responseArgs,
                        @"fn": fn
                };

                if (callback != nil) {
                    callback(response, nil);
                }
            };
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!this) {
                AMLogWarn(@"Attempt to evaluate JS after self");
                return;
            }

            @try {
                [this evaluateJavaScript:jsString completionHandler:nil];
            } @catch (NSException *exp) {
                AMLogWarn(@"Failed to execute js: %@", exp);
            }
        });
    }
}

- (void)setCookiePolicy:(NSHTTPCookieAcceptPolicy)policy {
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:policy];
}


- (void)removeNativeView {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_appAudienceView != nil) {
            [_appAudienceView close];
        } else {
            AMLogDebug(@"app audience is not opened nothing to do");
        }
    });
}
@end
