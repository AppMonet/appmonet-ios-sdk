//
// Created by Jose Portocarrero on 10/27/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class AMODeviceData;
@class AMOAuctionManager;
@class AMOPreferences;
@class AMOAppMonetContext;
@class AMOBidManager;
@class AMOAdView;
@class AMOAdViewPoolManager;
@class AMORemoteConfiguration;

typedef void (^JavascriptResponseHandler)(NSDictionary *response, NSError *error);


@interface AMOAuctionWebView : WKWebView <WKNavigationDelegate, WKScriptMessageHandler>
@property(nonatomic, assign) BOOL isLoaded;
@property(nonatomic, strong) NSMutableDictionary *jsHandlers;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *helperRegistrations;
@property(nonatomic, copy) void (^onLoad)(AMOAuctionWebView *);
@property(nonatomic, strong) NSString *auctionUrl;
@property(nonatomic, strong) AMODeviceData *deviceData;
@property(nonatomic, readwrite, copy) NSString *auctionHtml;
@property(nonatomic, readonly, copy) NSString *auctionJS;
@property(nonatomic, readonly, copy) NSString *auctionHeader;


- (instancetype)init;

- (instancetype)initWithDeviceData:(AMODeviceData *)deviceData andRemoteConfiguration:(AMORemoteConfiguration *)configuration
                     andBidManager:(AMOBidManager *)bidManager andPreferences:(AMOPreferences *)preferences
                andAppMonetContext:(AMOAppMonetContext *)appMonetContext andAdViewPoolManager:(AMOAdViewPoolManager *)adViewPoolManager
                 andExecutionQueue:(dispatch_queue_t)executionQueue andCallback:(void (^)(AMOAuctionWebView *))done;

- (void)callJsMethod:(NSString *)method arguments:(NSArray *)args callback:(JavascriptResponseHandler)callback;

- (void)callJsMethod:(NSString *)method arguments:(NSArray *)args waitForResponse:(BOOL)waitForResponse
            callback:(JavascriptResponseHandler)callback;

- (void)callJsMethod:(NSString *)method withTimeout:(NSNumber *)timeout arguments:(NSArray *)args waitForResponse:(BOOL)waitForResponse
            callback:(JavascriptResponseHandler)callback;

- (void)safelyLoadAuctionPage:(NSString *)pageUrl tries:(NSNumber *)tries;

- (void)dispatchJsCall:(NSString *)method args:(NSArray *)args callback:(NSString *)callback;

- (void)returnJs:(NSString *)callback data:(NSObject *)data;

@end

typedef void (^JsHandler)(AMOAuctionWebView *wv, NSArray *args, NSString *callback);

@protocol AMOAuctionManagerDelegate <NSObject>
- (void)auctionManager:(AMOAuctionManager *)auctionManager started:(NSError *)error;

@optional
- (void)auctionManager:(AMOAuctionManager *)auctionManager error:(NSError *)error;
@end

