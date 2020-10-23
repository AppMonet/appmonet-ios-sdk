//
// Created by Jose Portocarrero on 10/27/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMOConstants.h"
#import "AMOUtils.h"
#import "AMODeviceData.h"
#import "AMOPreferences.h"
#import "AMOAppMonetContext.h"
#import "AMOBidManager.h"
#import "AMOAdView.h"
#import "AMOAdViewContext.h"
#import "AMOAdViewPoolManager.h"
#import "AMOHttpUtil.h"
#import "AMODispatchState.h"
#import "AMORemoteConfiguration.h"

@implementation AMOAuctionWebView {
    AMOPreferences *_preferences;
    AMOAppMonetContext *_appMonetContext;
    NSNumber *_kPostLoadCheckDelay;
    NSNumber *_kMaxLoadAttempts;
    AMOBidManager *_bidManager;
    AMOAdViewPoolManager *_adViewPoolManager;
    NSHTTPCookieAcceptPolicy _cookiePolicy;
    NSString *_userAgent;
    dispatch_queue_t _executionQueue;
    AMORemoteConfiguration *_remoteConfiguration;
}

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];

    [self setCookiePolicy:NSHTTPCookieAcceptPolicyAlways];
//    [self validateUserAgent];

    // subscribe to AdView loaded events
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(handleHelperCreated:) name:@"helperCreated" object:nil];
//    notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)
    [notificationCenter addObserver:self selector:@selector(appMovedToBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(appMovedToForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

    // set up some system notifications to handle the cookie policy &
    // the user agent changing..
    [notificationCenter addObserver:self selector:@selector(handleCookiePolicyChange:) name:NSHTTPCookieManagerAcceptPolicyChangedNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(handleMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[self.configuration userContentController] addScriptMessageHandler:self name:@"monet"];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)handleMemoryWarning:(NSNotification *)notification {
    [self callJsMethod:@"memoryWarning" arguments:@[] callback:nil];
}

- (void)appMovedToBackground:(NSNotification *)notification {
    [self trackState:@"appBackgrounded"];
}

- (void)appMovedToForeground:(NSNotification *)notification {
    [self trackState:@"appForegrounded"];
}

- (void)handleCookiePolicyChange:(NSNotification *)notification {
    AMLogDebug(@"Cookie policy changed. Confirming..");
    if (notification.object == nil) {
        return;
    }

    NSHTTPCookieStorage *instance = notification.object;
    if (_cookiePolicy != nil && instance.cookieAcceptPolicy != _cookiePolicy) {
        [instance setCookieAcceptPolicy:_cookiePolicy];
    }
}

- (void)setCookiePolicy:(NSHTTPCookieAcceptPolicy)policy {
    _cookiePolicy = policy;
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:policy];
}

- (void)handleHelperCreated:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo == nil || userInfo[@"wvUUID"] == nil) {
        return;
    }

    NSDictionary *context = userInfo[@"context"];
    NSString *uuid = userInfo[@"wvUUID"];
    [self callJsMethod:@"helperCreated" arguments:@[uuid, context] callback:nil];
    [self bindToAdView:uuid];
}

- (NSString *)quote:(NSString *)input {
    if (!input || input.length == 0) {
        return @"''";
    }
    return [NSString stringWithFormat:@"'%@'", input];
}

- (instancetype)initWithDeviceData:(AMODeviceData *)deviceData andRemoteConfiguration:(AMORemoteConfiguration *)configuration
                     andBidManager:(AMOBidManager *)bidManager andPreferences:(AMOPreferences *)preferences
                andAppMonetContext:(AMOAppMonetContext *)appMonetContext andAdViewPoolManager:(AMOAdViewPoolManager *)adViewPoolManager
                 andExecutionQueue:(dispatch_queue_t)executionQueue andCallback:(void (^)(AMOAuctionWebView *))done {
    self = [self init];
    if (self) {
        self.onLoad = done;
        self.scrollView.scrollEnabled = NO;
        self.scrollView.bounces = NO;
        _remoteConfiguration = configuration;
        _adViewPoolManager = adViewPoolManager;
        _executionQueue = executionQueue;
        _deviceData = deviceData;
        _bidManager = bidManager;
        _preferences = preferences;
        _appMonetContext = appMonetContext;
        _kPostLoadCheckDelay = @6;
        _kMaxLoadAttempts = @5;
        _isLoaded = false;
        self.navigationDelegate = self;
        _auctionJS = [NSString stringWithFormat:@"%@/js/%@-auction.sdk.v2.min.js?v=%@&r=1&nocache=true",
                        BASE_URL, AMSdkVersion, AMSdkVersion];
        _auctionHeader = [NSString stringWithFormat:@"<head><title>%@ (cx) </title>", AMSdkVersion];
        NSString *defaultDomain = appMonetContext.defaultDomain ? appMonetContext.defaultDomain : AMAuctionURL;
        _auctionUrl = [_preferences getPref:AMAuctionUrlKey stringDefaultValue:defaultDomain];

        _auctionJS = [_preferences getPref:AMAuctionJsKey stringDefaultValue:_auctionJS];

        _auctionHeader = [preferences getPref:AMAuctionHtmlKey stringDefaultValue:_auctionHeader];
        _auctionHtml = [NSString stringWithFormat:@"<html>%@<script src=\"%@\">%@", _auctionHeader, _auctionJS,
                                                  AMWebViewFooter];

        _jsHandlers = [NSMutableDictionary dictionaryWithDictionary:@{
                @"ajax": ^(AMOAuctionWebView *wv, NSArray *args, NSString *callback) {
                    if (![args[0] isKindOfClass:[NSDictionary class]]) {
                        AMLogDebug(@"Invalid arg (ajax)");
                        [wv returnJs:callback data:@"null"];
                        return;
                    }
                    [AMOHttpUtil makeRequest:wv andRequestString:args[0] andCallback:callback];
                },
                @"consoleLog": ^(AMOAuctionWebView *wv, NSArray *args, NSString *callback) {
                    [AMOUtils logFromJS:callback message:args];
                },
                @"execInContext": ^(AMOAuctionWebView *wv, NSArray *args, NSString *callback) {
                    if (!am_obj_isString(args[0])) {
                        AMLogDebug(@"Invalid arg (eIC)");
                        [wv returnJs:callback data:@"null"];
                        return;
                    }
                    [_adViewPoolManager executeInContextVideo:args[0] andMessage:args[1]];
                    [wv returnJs:callback data:@"true"];
                },
                @"getAdvertisingData": ^(AMOAuctionWebView *webView, NSArray *args, NSString *callback) {
                    [webView returnJs:callback data:[_deviceData getAdvertisingInfo]];
                },
                @"getAuctionUrl": ^(AMOAuctionWebView *webview, NSArray *args, NSString *callback) {
                    [webview returnJs:callback data:_auctionUrl];
                },
                @"getAvailableBidCount": ^(AMOAuctionWebView *webView, NSArray *args, NSString *callback) {
                    if (!am_obj_isString(args[0])) {
                        AMLogDebug(@"Invalid arg (gABC)");
                        [webView returnJs:callback data:@"null"];
                        return;
                    }
                    [webView returnJs:callback data:[@([_bidManager countBids:args[0]]) stringValue]];
                },
                @"getDeviceData": ^(AMOAuctionWebView *webview, NSArray *args, NSString *callback) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (webview != nil) {
                            [webview returnJs:callback data:[_deviceData buildData]];
                        }
                    });
                },
                @"getAdViewUrl": ^(AMOAuctionWebView *webView, NSArray *args, NSString *callback) {
                    if (!am_obj_isString(args[0])) {
                        AMLogDebug(@"Invalid arg (gAVU)");
                        [webView returnJs:callback data:@"null"];
                        return;
                    }
                    NSString *url = [_adViewPoolManager getAdViewUrl:args[0]];
                    [webView returnJs:callback data:[webView quote:url]];
                },
                @"getContextRefCount": ^(AMOAuctionWebView *webview, NSArray *args, NSString *callback) {
                    if (!am_obj_isString(args[0])) {
                        AMLogDebug(@"Invalid arg (gCRC)");
                        [webview returnJs:callback data:@"null"];
                        return;
                    }
                    NSNumber *refCount = [_adViewPoolManager getReferenceCount:args[0]];
                    [webview returnJs:callback data:[refCount stringValue]];
                },
                @"getContextRenderCount": ^(AMOAuctionWebView *webview, NSArray *args, NSString *callback) {
                    if (!am_obj_isString(args[0])) {
                        AMLogDebug(@"Invalid arg (gCRC)");
                        [webview returnJs:callback data:@"null"];
                        return;
                    }

                    AMOAdView *adView = [_adViewPoolManager getAdViewByUuid:args[0]];
                    NSNumber *renders = @0;
                    if (adView != nil) {
                        renders = [adView getRenderCount];
                    }
                    [webview returnJs:callback data:[renders stringValue]];
                },
                @"subscribe": ^(AMOAuctionWebView *webview, NSArray *args, NSString *callback) {
                    if (!am_obj_isString(args[0])) {
                        AMLogDebug(@"Invalid arg (sub)");
                        [webview returnJs:callback data:@"false"];
                        return;
                    }
                    [webview subscribeToNotification:args[0]];
                    [webview returnJs:callback data:@"true"];
                },
                @"getContextState": ^(AMOAuctionWebView *webview, NSArray *args, NSString *callback) {
                    if (!am_obj_isString(args[0])) {
                        AMLogDebug(@"Invalid UUID arg");
                        [webview returnJs:callback data:@"'NOT_EXIST'"];
                        return;
                    }

                    AMOAdView *adView = [_adViewPoolManager getAdViewByUuid:args[0]];
                    if (adView == nil) {
                        AMLogDebug(@"Invalid UUID arg");
                        [webview returnJs:callback data:@"'NOT_FOUND'"];
                        return;
                    }

                    // indicate the state
                    NSString *state = adViewStateValueString(adView.state);
                    [webview returnJs:callback data:[webview quote:state]];
                },
                @"getVMState": ^(AMOAuctionWebView *webview, NSArray *args, NSString *callback) {
                    uint64_t usable = AMusableMemory();
                    uint64_t free = AMfreeMemory();

                    NSDictionary *vmState = @{
                            @"totalMemory": @(usable),
                            @"maxMemory": @(usable),
                            @"freeMemory": @(free),
                            @"nativeHeapAlloc": @0.0, // NA
                            @"nativeHeapFree": @0.0,
                            @"memoryLow": @(FALSE),
                            @"miLow": @(FALSE),
                            @"miThreshold": @0.0,
                            @"miTotal": @(usable),
                            @"miFree": @(free),
                    };
                    [webview returnJs:callback data:vmState];
                },
                @"setBidderData": ^(AMOAuctionWebView *webview, NSArray *args, NSString *callback) {	
                    [_bidManager setBidderData:args];	
                    [webview returnJs:callback data:@"true"];	
                },
                @"init": ^(AMOAuctionWebView *webview, NSArray *args, NSString *callback) {
                    [webview markLoaded];
                    [webview returnJs:callback data:@"true"];
                },
                @"launch": ^(AMOAuctionWebView *webview, NSArray *args, NSString *callback) {
                    if (args.count < 7) {
                        AMLogDebug(@"not enough args for 'launch' - %d", args.count);
                        [webview returnJs:callback data:@"false"];
                        return;
                    }

                    if (!am_obj_isNumber(args[4]) || !am_obj_isNumber(args[5]) || !am_obj_isString(args[0])) {
                        AMLogDebug(@"invalid helper dim passed");
                        [webview returnJs:callback data:@"false"];
                        return;
                    }

                    if (!am_obj_isString(args[2]) || !am_obj_isString(args[3])) {
                        AMLogDebug(@"Invalid html/ua argument passed");
                        [webview returnJs:callback data:@"false"];
                        return;
                    }

                    NSInteger width = [args[4] intValue];
                    NSInteger height = [args[5] intValue];
                    NSString *requestId = args[0];

                    [webview loadVideoHelper:args[1] andUserAgent:args[2] andHtml:args[3] andWidth:width andHeight:height
                                 andAdUnitId:args[6] andReturnBlock:^(AMOAdView *adview) {
                                NSMutableArray *jsArgs = [NSMutableArray array];
                                [jsArgs addObject:requestId];
                                [jsArgs addObject:[adview uuid]];
                                [webview callJsMethod:@"helperReady" arguments:jsArgs callback:nil];
                            }];
                    [webview returnJs:callback data:@"true"];
                },
                @"remove": ^(AMOAuctionWebView *webView, NSArray *args, NSString *callback) {
                    if (args.count < 1 || !am_obj_isString(args[0])) {
                        AMLogDebug(@"invalid arg 0");
                        [webView returnJs:callback data:@"false"];
                        return;
                    }

                    [_adViewPoolManager removeViewWithUUID:args[0] andShouldAdViewBeDestroyed:YES];
                    [webView returnJs:callback data:@"true"];
                },
                @"requestHelperDestroy": ^(AMOAuctionWebView *webView, NSArray *args, NSString *callback) {
                    if (args.count != 1 || !am_obj_isString(args[0])) {
                        AMLogDebug(@"invalid arg 0");
                        [webView returnJs:callback data:@"false"];
                        return;
                    }

                    [_adViewPoolManager requestDestroy:args[0]];
                    [webView returnJs:callback data:@"true"];
                },
                @"setAdUnitNames": ^(AMOAuctionWebView *webview, NSArray *args, NSString *callback) {
                    if (args.count == 0) {
                        [webview returnJs:callback data:@"false"];
                        return;
                    }
                    NSData *data = [args[0] dataUsingEncoding:NSUTF8StringEncoding];
                    [bidManager setAdUnitNames:[AMOUtils parseJson:data]];
                    [webview returnJs:callback data:@"true"];
                },
                @"setBids": ^(AMOAuctionWebView *wv, NSArray *args, NSString *callback) {
                    if (args.count == 0) {
                        AMLogDebug(@"invalid setBids");
                        [wv returnJs:callback data:@"false"];
                        return;
                    }

                    _auctionUrl = _auctionUrl != nil ? _auctionUrl : AMAuctionURL;
                    [_bidManager addBidsFromArray:args defaultUrl:_auctionUrl];
                    [wv returnJs:callback data:@"true"];
                },
                @"setNativeBoolean": ^(AMOAuctionWebView *wv, NSArray *args, NSString *callback) {
                    if (args.count != 2 || !am_obj_isString(args[0])) {
                        AMLogDebug(@"invalid SNB");
                        [wv returnJs:callback data:@"false"];
                        return;
                    }
                    BOOL value = [@"true" isEqualToString:args[1]];
                    [_preferences setPreference:args[0] boolValue:value];
                    [wv returnJs:callback data:@"true"];
                },
                @"setNativeString": ^(AMOAuctionWebView *wv, NSArray *args, NSString *callback) {
                    if (args.count != 2 || !am_obj_isString(args[0])) {
                        AMLogDebug(@"invalid SNS");
                        [wv returnJs:callback data:@"false"];
                        return;
                    }

                    // also save this too
                    [wv saveConfigurationValues:args];
                    [_preferences setPreference:args[0] stringValue:args[1]];
                    [wv returnJs:callback data:@"true"];
                },
                @"getNativeBoolean": ^(AMOAuctionWebView *wv, NSArray *args, NSString *callback) {
                    if (!am_obj_isString(args[0])) {
                        AMLogDebug(@"invalid gNB k");
                        [wv returnJs:callback data:@"null"];
                        return;
                    }

                    NSString *key = args[0];
                    if (key == nil || key.length == 0) {
                        [wv returnJs:callback data:@"null"];
                        return;
                    }

                    BOOL value = [_preferences getPref:key boolDefaultValue:FALSE];
                    [wv returnJs:callback data:value == FALSE ? @"false" : @"true"];
                },
                @"getNativeString": ^(AMOAuctionWebView *wv, NSArray *args, NSString *callback) {
                    if (args.count != 1 || !am_obj_isString(args[0])) {
                        AMLogDebug(@"invalid gNS k");
                        [wv returnJs:callback data:@""];
                        return;
                    }

                    NSString *key = args[0];
                    if (key == nil || key.length == 0) {
                        [wv returnJs:callback data:@""];
                        return;
                    }

                    NSString *value = [_preferences getPref:key stringDefaultValue:@""];
                    [wv returnJs:callback data:[wv quote:value]];
                },
                @"setV": ^(AMOAuctionWebView *wv, NSArray *args, NSString *callback) {
                    if (args.count != 2) {
                        AMLogDebug(@"invalid stv k");
                        return;
                    }

                    [wv saveConfigurationValues:args];
                    [wv returnJs:callback data:@"true"];
                },
                @"subscribeKV": ^(AMOAuctionWebView *wv, NSArray *args, NSString *callback) {
                    if (args.count != 1) {
                        AMLogDebug(@"invalid arguments for subscribeKV");
                        return;
                    }
                    [[NSUserDefaults standardUserDefaults] addObserver:self
                                                            forKeyPath:args[0]
                                                               options:NSKeyValueObservingOptionNew
                                                               context:NULL];
                    [wv returnJs:callback data:@"true"];
                },
                @"getConfiguration": ^(AMOAuctionWebView *wv, NSArray *args, NSString *callback) {
                    if (args.count < 1) {
                        AMLogDebug(@"invalid arguments for getConfiguration");
                        [wv returnJs:callback data:nil];
                        return;
                    }
                    BOOL forceServer = [args[0] boolValue];
                    [_remoteConfiguration getConfiguration:forceServer completion:^(NSString *response) {
                        [wv returnJs:callback data:response];
                    }];
                }
        }];
        [self loadAuctionPage:@1];
    }
    return self;
}

/**
 * This method saves the configuration options coming from Javascript.
 * <p>
 *      array[0] - contains the key to be used to save the configuration option.
 *      array[1] - contains the configuration option.
 * </p>
 *
 * @param array The NSArray object holding the configurations.
 */
- (void)saveConfigurationValues:(NSArray *)array {
    if (array.count <= 0) {
        return;
    }

    if (!am_obj_isString(array[0]) || !am_obj_isString(array[1])) {
        return;
    }
    NSString *compareValue = array[0];
    if ([compareValue isEqualToString:@"ua"] || [compareValue isEqualToString:AMAuctionUrlKey]) {
        [_preferences setPreference:compareValue stringValue:array[1]];
    } else if ([compareValue isEqualToString:AMSdkConfiguration]) {
        NSData *data = [array[1] dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *config = [AMOUtils parseJson:data];
        [_preferences setPreference:compareValue dictValue:config];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (change && change[@"new"]) {
        [self callJsMethod:@"onKVChange" arguments:@[(keyPath) ? keyPath : @"", change[@"new"]] callback:nil];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if ([[navigationAction.request.URL scheme] isEqualToString:kAMOWebViewJsScheme]) {
        return decisionHandler(WKNavigationActionPolicyCancel);
    }
    return decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)subscribeToNotification:(NSString *)name {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(genericSubscriptionReceiver:) name:name object:nil];
}

- (void)genericSubscriptionReceiver:(NSNotification *)notification {
    NSString *name = notification.name;
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo == nil) {
        userInfo = @{};
    }
    [self callJsMethod:@"notifySubscription" arguments:@[(name) ? name : @"", userInfo] callback:nil];
}

- (void)loadAuctionPage:(NSNumber *)tries {
    AMLogDebug(@"Loading auction webview");
    NSString *delimiter = ([_auctionUrl rangeOfString:@"?"].location != NSNotFound) ? @"&" : @"?";
    NSString *pageUrl = [NSString stringWithFormat:@"%@%@aid=%@&v=%@", _auctionUrl, delimiter,
                                                   _appMonetContext.applicationId, AMSdkVersion];
    [self safelyLoadAuctionPage:pageUrl tries:tries];
}

- (void)safelyLoadAuctionPage:(NSString *)pageUrl tries:(NSNumber *)tries {
    AMLogInfo(@"loading auction manager root : %@", pageUrl);

    NSURL *pageURL = [NSURL URLWithString:pageUrl];
    if (![pageURL.scheme containsString:@"http"]) {
        NSString *correctURL = [NSString stringWithFormat:@"http://%@", pageUrl];
        pageURL = [NSURL URLWithString:correctURL];
    }

    [self loadHTMLString:_auctionHtml baseURL:pageURL];
    [self startDetection:tries];
}

- (void)bindToAdView:(NSString *)uuid {
    if (!am_obj_isString(uuid)) {
        AMLogWarn(@"no UUID for AdView");
        return;
    }

    // we don't need to register the same one twice
    if (_helperRegistrations[uuid] != nil) {
        return;
    }

    // set up a callback for when the adView is ready..
    [_adViewPoolManager onAdViewReady:uuid andBlockCallback:^{
        NSArray *args = @[uuid];
        [self callJsMethod:@"helperLoaded" arguments:args callback:nil];
    }];

    NSString *helperDestroyNotification = [NSString stringWithFormat:@"%@%@", uuid, kAMDestroyNotification];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(helperDestroy:) name:helperDestroyNotification
                                               object:nil];

    NSString *helperRespondNotification = [NSString stringWithFormat:@"%@%@", uuid, kAMRespondNotification];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(helperRespond:) name:helperRespondNotification object:nil];

    // remember that we registered this already
    _helperRegistrations[uuid] = @YES;
}

- (void)loadVideoHelper:(NSString *)url andUserAgent:(NSString *)userAgent andHtml:(NSString *)html andWidth:(NSInteger)width andHeight:(NSInteger)height
            andAdUnitId:(NSString *)adUnitId andReturnBlock:(void (^)(AMOAdView *adview))returnBlock {
    AMOAdViewContext *adViewContext = [[AMOAdViewContext alloc] initWithUrl:url andUserAgent:userAgent andWidth:@(width) andHeight:@(height) andAdUnitId:adUnitId andHtml:html andRichMedia:true];
    dispatch_async(dispatch_get_main_queue(), ^{
        AMOAdView *adViewFromContext = [_adViewPoolManager requestWithAdViewContext:adViewContext];

        if (!adViewFromContext) {
            AMLogWarn(@"could not get helper view");
            return;
        }

        if (![adViewFromContext getLoaded]) {
            if (![adViewFromContext load]) {
                AMLogWarn(@"attempt to load invalid view");
                return;
            }
        }

        [self bindToAdView:adViewFromContext.uuid];
        returnBlock(adViewFromContext);
    });
}

- (void)startDetection:(NSNumber *)tries {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, ([_kPostLoadCheckDelay intValue] * [tries intValue]) * NSEC_PER_SEC),
            dispatch_get_main_queue(), ^{
                NSString *scheme = self.URL.scheme;
                if (!self.isLoaded || ![scheme containsString:@"http"]) {
                    AMLogWarn(@"javascript not initialized yet. Reloading page");
                    if ([[_deviceData getConnectionType] isEqualToString:AMNetworkNone]) {
                        AMLogWarn(@"no network connection detecting. Delaying load check");
                        [self startDetection:tries];
                        return;
                    }

                    if (([tries intValue] + 1) < [_kMaxLoadAttempts intValue]) {
                        [self loadAuctionPage:@([tries intValue] + 1)];
                    } else {
                        AMLogDebug(@"max load attempts reached");
                    }
                } else {
                    AMLogDebug(@"load already detected");
                }
            });
}

- (void)dispatchJsCall:(NSString *)method args:(NSArray *)args callback:(NSString *)callback {
    __weak typeof(self) weakSelf = self;

    NSData *cloneData = [NSKeyedArchiver archivedDataWithRootObject:args];
    if (!cloneData) {
        AMLogWarn(@"failed to archive/clone args");
        return;
    }

    NSArray *copiedArray = [NSKeyedUnarchiver unarchiveObjectWithData:cloneData];
    if (!copiedArray) {
        AMLogWarn(@"failed to copy cloned data");
        return;
    }

    dispatch_async(_executionQueue, ^{
        if (!weakSelf) {
            AMLogWarn(@"Lost ourselves. Skipping js dispatch");
            return;
        }

        __strong typeof(weakSelf) strongSelf = weakSelf;
        if(strongSelf!=nil) {
            @synchronized (strongSelf.jsHandlers) {
                __weak JsHandler handler = strongSelf.jsHandlers[method];
                if (handler == nil) {
                    AMLogWarn(@"!! unknown method called from js: %@", method);
                    return;
                }
                handler(strongSelf, copiedArray, callback);
            }
        }
    });
}

- (void)markLoaded {
    if (self.isLoaded) {
        return;
    }

    self.isLoaded = YES;
    if (self.onLoad) {
        self.onLoad(nil);
    }
}

- (NSString *)reformatJson:(NSObject *)data {
    if (!data) {
        return @"null";
    }

    if ([data isKindOfClass:[NSDictionary class]]) {
        return [AMOUtils toJson:data];
    }

    if ([data isKindOfClass:[NSNumber class]]) {
        return [NSString stringWithFormat:@"%@", data];
    }

    if ([data isKindOfClass:[NSArray class]] || [data isKindOfClass:[NSMutableArray class]]) {
        return [AMOUtils toJson:data];
    }

    if ([data isKindOfClass:[NSString class]]) {
        NSString *dataStr = (NSString *) data;
        if (dataStr.length == 0) {
            return @"''";
        }

        if ([dataStr isEqualToString:@"true"] || [dataStr isEqualToString:@"false"]) {
            return dataStr;
        }

        // don't double-quote
        if ([dataStr hasPrefix:@"'"] && [dataStr hasSuffix:@"'"]) {
            return dataStr;
        }

        if ([dataStr hasPrefix:@"{"] && [dataStr hasSuffix:@"}"]) {
            return dataStr;
        }

        return [NSString stringWithFormat:@"'%@'", data];
    }

    return @"null";
};

- (void)returnJs:(NSString *)callback data:(NSObject *)data {
    if (!am_obj_isString(callback)) {
        return;
    }

    @autoreleasepool {
        NSString *jsString;
        @try {
            NSString *json = [self reformatJson:data];
            if (!json) {
                return;
            }

            jsString = [NSString stringWithFormat:@"window['%@'](%@);", callback, json];
            if (!jsString) {
                return;
            }

        } @catch (id exception) {
            AMLogWarn(@"invalid json data passed to returnJs");
            return;
        }

        __weak typeof(self) this = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!this) {
                AMLogDebug(@"We lost ourselves before calling js.");
                return;
            }

            @try {
                if (!jsString) {
                    return;
                }
                [this evaluateJavaScript:jsString completionHandler:^(NSString *result, NSError *error) {
                    if (!result || [[NSNull null] isEqual:result]) {
                        return;
                    }
                    if (NO || !am_obj_isString(result)) {
                        return;
                    }
                    if ([result containsString:@"Error"]) {
                        AMLogWarn(@"Unexpected error evaluating JS: %@", result);
                    }
                }];
            } @catch (NSException *exp) {
                AMLogWarn(@"Error while evaluating JS: %@", exp);
            }
        });
    }
}

- (void)callJsMethod:(NSString *)method arguments:(NSArray *)args waitForResponse:(BOOL)waitForResponse
            callback:(JavascriptResponseHandler)callback {
    [self callJsMethod:method withTimeout:@(0) arguments:args waitForResponse:waitForResponse callback:callback];
}

- (void)callJsMethod:(NSString *)method withTimeout:(NSNumber *)timeout arguments:(NSArray *)args waitForResponse:(BOOL)waitForResponse
            callback:(JavascriptResponseHandler)callback {
    NSError *err = [NSError errorWithDomain:@"callJsMethod" code:400 userInfo:nil];
    AMODispatchState *dispatchState = [[AMODispatchState alloc] init];
    if (!_isLoaded) {
        AMLogWarn(@"javascript is not loaded");
        if (callback) {
            callback(nil, err);
        }
        return;
    }

    NSString *cbIdentifier = [AMOUtils uuid];
    NSString *callbackFn =
            [NSString stringWithFormat:@"function (res){ webkit.messageHandlers.monet.postMessage({args:[res], method: '%@', fn: 'noop'}); }",
                                       cbIdentifier];

    NSString *jsonArgs = [AMOUtils toJson:args];
    NSString *jsString = [NSString
            stringWithFormat:@"window['%@']['%@'](%@, %@);", AMWebViewJSAgentGlobal, method, jsonArgs, callbackFn];

    __weak typeof(self) this = self;
    if (waitForResponse) {
        if (!cbIdentifier) {
            if (callback) {
                callback(nil, err);
            }
            return;
        }
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
                    if (dispatchState != nil) {
                        dispatchState.isCancelled = YES;
                    }
                    callback(response, nil);
                }
            };
        }
        if (timeout.integerValue > 0 && callback != nil) {
            [AMOUtils cancelableDispatchAfter:dispatch_time(DISPATCH_TIME_NOW, (int64_t) (timeout.integerValue * NSEC_PER_MSEC))
                                      inQueue:dispatch_get_main_queue() withState:dispatchState withBlock:^{
                        @synchronized (this.jsHandlers) {
                            AMLogDebug(@"method time out");
                            this.jsHandlers[cbIdentifier] = nil; // only execute once
                            if (callback != nil) {
                                callback(nil, err);
                            }
                        }
                    }];
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!this) {
            AMLogDebug(@"Lost self before calling js.");
            return;
        }

        if (!jsString) {
            AMLogWarn(@"Lost JS String during exec");
            return;
        }

        @try {
            [this evaluateJavaScript:jsString completionHandler:^(NSString *result, NSError *error) {
                if (!result || [[NSNull null] isEqual:result]) {
                    return;
                }
                if (error || !am_obj_isString(result)) {
                    AMLogWarn(@"invalid result");
                    return;
                }
                if ([result containsString:@"Error"]) {
                    AMLogWarn(@"Unexpected error evaluating JS: %@", result);
                }
            }];
        } @catch (NSException *exp) {
            AMLogWarn(@"Failed to execute js: %@", exp);
        }
    });
}

- (void)callJsMethod:(NSString *)method arguments:(NSArray *)args callback:(JavascriptResponseHandler)callback {
    @try {
        [self callJsMethod:method arguments:args waitForResponse:true callback:callback];
    } @catch (NSException *exception) {
        AMLogWarn(@"Failed to call js w/ wait: %@", exception);
    }
}

- (void)helperDestroy:(NSNotification *)notification {
    [self callJsMethod:@"helperDestroy" arguments:@[notification.userInfo[@"adViewUuid"]] callback:nil];

    // clean up
    NSString *uuid = notification.userInfo[@"adViewUuid"];
    if (!am_obj_isString(uuid)) {
        return;
    }

    NSString *helperDestroyNotification = [NSString stringWithFormat:@"%@%@", uuid, kAMDestroyNotification];
    NSString *helperRespondNotification = [NSString stringWithFormat:@"%@%@", uuid, kAMRespondNotification];

    if (nil == _helperRegistrations[uuid]) {
        return;
    }

    BOOL val = [_helperRegistrations[uuid] boolValue];
    if (!val) {
        return;
    }

    @try {
        [NSNotification removeObserver:self forKeyPath:helperDestroyNotification];
        [NSNotification removeObserver:self forKeyPath:helperRespondNotification];
    } @catch (id anException) {
        AMLogWarn(@"unexpected error removing helper observers %@", anException);
    } @finally {
        _helperRegistrations[uuid] = @NO;
    }
}

- (void)helperRespond:(NSNotification *)notification {
    NSString *adViewUuid = notification.userInfo[@"adViewUuid"];
    NSObject *data = notification.userInfo[@"data"];

    if (![data isKindOfClass:[NSDictionary class]]) {
        return;
    }

    NSDictionary *dataDictionary = (NSDictionary *) data;
    NSString *event = dataDictionary[@"event"];
    if (event == nil || event.length == 0) {
        return;
    }

    [self callJsMethod:@"helperRespond" arguments:@[adViewUuid, dataDictionary] callback:nil];
}

- (void)trackState:(NSString *)state {
    UIViewController *controller = [UIApplication sharedApplication].keyWindow.rootViewController;
    NSString *viewName = (controller) ? NSStringFromClass([controller class]) : @"";
    NSString *timestamp = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970] * 1000];
    [self callJsMethod:@"trackAppState" arguments:@[state, viewName, timestamp] callback:nil];
}

@end
