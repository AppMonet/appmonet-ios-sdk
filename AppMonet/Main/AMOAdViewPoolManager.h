//
// Created by Jose Portocarrero on 11/2/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIView.h>

@class AMOAdView;
@class AMOAppMonetContext;
@class AMOBidResponse;
@class AMOAdViewContext;


@interface AMOAdViewPoolManager : NSObject
- (instancetype)initWithRootContainer:(UIView *)rootContainer;

/**
 * This method checks if the provided {@link AdView} has a webview UUID, if the pool manager
 * ad view collection still has a reference to the {@link AdView}, and if there are any bid
 * references associated to the webview UUID.
 *
 * @param adView The Ad view we want to check if it can be released.
 * @return A boolean value which determines if an {@link AdView} can be released.
 */

- (BOOL)canRelease:(AMOAdView *)adView;

/**
  * This method checks if the {@link AMOAdViewPoolManager} still contains the given webview UUID
  * reference. If the adview associated to the UUID is null then a cleanup is triggered.
  *
  * @param wvUUID The UUID to check if it is still associated in the {@link AMOAdViewPoolManager}.
  * @return Boolean value that says if the webview UUID is still referenced.
  */
- (BOOL)containsView:(NSString *)wvUuid;

- (void)executeInContextVideo:(NSString *)wvUUID andMessage:(NSString *)message;

- (AMOAdView *)getAdViewByUuid:(NSString *)wvUUID;


/**
 * This method retrieves the state of a particular webview using the given UUID.
 *
 * @param wvUUID The webview UUID to retrieve state for.
 * @return The state value of the particular webview UUID reference.
 */
- (NSString *)getState:(NSString *)wvUUID;

/**
 * This method retrieves the reference bid count associated to the given webview UUID.
 *
 * @param wvUUID The webview UUID to find the reference count for.
 * @return The number of bid references associated to the given UUID.
 */
- (NSNumber *)getReferenceCount:(NSString *)wvUUID;

- (NSString *)getAdViewUrl:(NSString *)wvUUID;

- (BOOL)isAdViewReady:(NSString *)wvUUID;

- (void)logState;

- (void)markAdViewAsReady:(NSString *)wvUUID;

- (void)onAdViewReady:(NSString *)wvUUID andBlockCallback:(void (^)(void))block;

/**
  * Remove an AMOAdView from the pool
  *
  * @param adView       the adView instance to remove
  * @param destroyAdView    indicates whether the underlying instance should also be destroyed
  * @param forceDestroy force through safety checks (e.g. if bids are cached/ready in the specific view)
  * @return whether or not the AMOAdView was removed
  */
- (BOOL) removeAdView:(AMOAdView *)adView andShouldAdViewBeDestroyed:(BOOL)destroyAdView
andShouldForceDestroy:(BOOL)forceDestroy;

/**
 * Remove a MonetAdView based on it's UUID
 * see {remove(MonetAdView, boolean destroyWv, boolean force)}
 *
 * @param wvUUID    the UUID of the MonetAdView
 * @param destroyAdView should the AdView also be destroyed
 * @return if the MonetADView was successfully removed
 */
- (BOOL)removeViewWithUUID:(NSString *)wvUUID andShouldAdViewBeDestroyed:(BOOL)destroyAdView;

/**
 * If the webView is in a rendered state, we can expire all of the bids in the webView
 * and set it's ref count to 0, so when it's finished it will be destroyed.
 *
 * @param wvUUID the webView's UUID
 * @return if the destroy was requested correctly
 */
- (BOOL)requestDestroy:(NSString *)wvUUID;

/**
 * Find or create a webView for the given adViewContext. Most of the logic
 * around creating new contexts/managing contexts is in JavaScript.
 *
 * @param adViewContext The AMOAdViewContext which describes the new WebView's environment
 * @return The created {@link AMOAdView} (WebView)
 */
- (AMOAdView *)requestWithAdViewContext:(AMOAdViewContext *)adViewContext;

/**
  * Request an AMOAdView based on a AMOBidResponse. This generates the corresponding
  * AMOAdViewContext from the AMOBidResponse in order to match up the Bid to the correct AMOAdView
  *
  * @param bid a AMOBidResponse to be rendered into a AMOAdView
  * @return the AMOAdView instance
  */
- (AMOAdView *)requestWithBid:(AMOBidResponse *)bid;

- (void)triggerNotification:(NSString *)wvUUID andMessage:(NSString *)message andArguments:(NSDictionary *)args;
@end
