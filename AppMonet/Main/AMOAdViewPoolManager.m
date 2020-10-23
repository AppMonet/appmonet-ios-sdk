//
// Created by Jose Portocarrero on 11/2/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMOAdViewPoolManager.h"
#import "AMOConstants.h"
#import "AMOAdView.h"
#import "AMOBidResponse.h"
#import "AMOAdViewContext.h"
#import "AMOAppMonetContext.h"
#import "AMOSdkManager.h"
#import "AMOBidManager.h"
#import "AMOUtils.h"

static NSInteger const kMaxRenderThreshHold = 10;
static NSInteger const kRefMinThreshHold = 3;

@implementation AMOAdViewPoolManager {
    NSMutableDictionary *_adViewCollection;
    NSMutableDictionary *_adViewsByContext;
    NSMutableDictionary *_messageHandlers;
    NSMutableDictionary *_adViewsReadyState;
    NSMutableDictionary *_sAdViewRefCount;
    UIView *_rootContainer;

}
- (instancetype)initWithRootContainer:(UIView *)rootContainer {
    self = [super self];
    if (self) {
        _rootContainer = rootContainer;
        _adViewCollection = [NSMutableDictionary dictionary];
        _adViewsByContext = [NSMutableDictionary dictionary];
        _messageHandlers = [NSMutableDictionary dictionary];
        _adViewsReadyState = [NSMutableDictionary dictionary];
        _sAdViewRefCount = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addedBidNotification:)
                                                     name:@"AMBidAdded" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncWithBidManager:)
                                                     name:kAMCleanUpBidsNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeBid:)
                                                     name:kAMBidsInvalidatedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeHelperFrom:)
                                                     name:kAMDestroyHelperNotification object:nil];
    }
    return self;
}


- (BOOL)canRelease:(AMOAdView *)adView {
    NSString *wvUUID = [adView getUUID];
    if (wvUUID == nil) {
        return true;
    }

    if (!_adViewCollection[wvUUID]) {
        AMLogInfo(@"%@ is not in the collection?!", wvUUID);
        return true;
    }

    NSNumber *count = _sAdViewRefCount[wvUUID];
    return count == nil || [count intValue] <= 0;
}


- (BOOL)containsView:(NSString *)wvUUID {
    AMOAdView *adView = _adViewCollection[wvUUID];
    if (_adViewCollection[wvUUID] && adView == nil) {
        AMLogWarn(@"collection contains webView but it is null. Cleaning reference.");
        [self cleanUpOrphanReference:wvUUID];
    }

    return adView != nil;
}

- (void)executeInContextVideo:(NSString *)wvUUID andMessage:(NSString *)message {
    AMOAdView *adView = _adViewCollection[wvUUID];
    if (adView == nil) {
        AMLogWarn(@"adView not found for %@ in context video", wvUUID);
        return;
    }

    [adView callJsMethod:@"__a" arguments:@[message] callback:nil];
}

- (NSString *)getAdViewUrl:(NSString *)wvUUID {
    AMOAdView *adView = [self getAdViewByUuid:wvUUID];
    if (!adView || !adView.URL) {
        return @"";
    }
    return adView.URL.absoluteString;
}

- (NSNumber *)getReferenceCount:(NSString *)wvUUID {
    NSNumber *count = _sAdViewRefCount[wvUUID] == nil ? @0 : _sAdViewRefCount[wvUUID];
    return count;
}

- (BOOL)isAdViewReady:(NSString *)wvUUID {
    return [_adViewsReadyState[wvUUID] boolValue];
}

- (void)markAdViewAsReady:(NSString *)wvUUID {
    @synchronized (_adViewsReadyState) {
        _adViewsReadyState[wvUUID] = @true;
    }
}

- (void)onAdViewReady:(NSString *)wvUUID andBlockCallback:(void (^)(void))ready {
    @synchronized (_messageHandlers) {
        if ([self isAdViewReady:wvUUID]) {
            AMLogDebug(@"webView %@ is ready", wvUUID);
            if (ready != nil) {
                ready();
            } else {
                AMLogError(@"AdViewPoolManager onViewReady ready block is null");
            }
            return;
        }
        AMLogDebug(@"webView %@ is not ready", wvUUID);

        NSString *notificationName = [NSString stringWithFormat:@"%@%@", wvUUID, @"__ready__"];
        id observer = [[NSNotificationCenter defaultCenter] addObserverForName:notificationName object:nil
                                                                         queue:[NSOperationQueue mainQueue]
                                                                    usingBlock:^(NSNotification *notification) {
                                                                        ready();
                                                                    }];
        _messageHandlers[wvUUID] = observer;
    }
}

- (BOOL) removeAdView:(AMOAdView *)adView andShouldAdViewBeDestroyed:(BOOL)destroyAdView
andShouldForceDestroy:(BOOL)forceDestroy {
    if (adView == nil) {
        return false;
    }
    if (adView.state == AD_RENDERED && !forceDestroy) {
        AMLogWarn(@"attempt to remove webView in rendered state");
        return false;
    }

    NSString *adViewUUID = adView.uuid;

    if (!_adViewCollection[adViewUUID]) {
        AMLogWarn(@"AdView with uuid: %@ is not in the adViewCollection.", adViewUUID);
        return false;
    }

    NSInteger references = [_sAdViewRefCount[adViewUUID] integerValue];

    if (![self canPerformRemove:references andRenderCount:[adView.getRenderCount integerValue] andForce:forceDestroy]) {
        AMLogWarn(@"attempt to remove webView with references");
        return false;
    }

    NSString *hash = adView.getWVhash;
    NSMutableArray *adViews = _adViewsByContext[hash];
    if (adViews != nil && [adViews containsObject:adView]) {
        [adViews removeObject:adView];
    } else {
        AMLogWarn(@"could not find view in context list. Invalid state for removal!");
    }

    // indicate that we're about to destroy this webView
    // we can do this by sending a 'destroy' message to all of the handlers
    [[NSNotificationCenter defaultCenter] postNotificationName:kAMDestroyNotification object:nil];
    [[NSNotificationCenter defaultCenter]                               postNotificationName:[NSString
                    stringWithFormat:@"%@%@", adView.getUUID, kAMDestroyNotification] object:nil
                                                                                    userInfo:@{@"adViewUuid": adView.getUUID}];

    [self cleanUpOrphanReference:adViewUUID];
    if (destroyAdView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [adView cleanForDealloc];
        });
    }

    return true;
}

- (BOOL)removeViewWithUUID:(NSString *)wvUUID andShouldAdViewBeDestroyed:(BOOL)destroyAdView {
    return [self removeAdView:_adViewCollection[wvUUID] andShouldAdViewBeDestroyed:destroyAdView
        andShouldForceDestroy:YES];
}


- (BOOL)requestDestroy:(NSString *)wvUUID {
    AMOAdView *adView = _adViewCollection[wvUUID];
    if (adView == nil) {
        AMLogDebug(@"requested helper not present: %@", wvUUID);
        return false;
    }

    if (adView.state == AD_LOADING) {
        AMLogDebug(@"adView is in loading state. can be removed now");
        return [self removeViewWithUUID:adView.getUUID andShouldAdViewBeDestroyed:true];
    }

    if ([AMOSdkManager get] == nil) {
        AMLogWarn(@"Failed to destroy adView: SDK not initialized");
        return false;
    }

    [[[AMOSdkManager get] bidManager] invalidateForView:wvUUID];
    NSInteger referenceCount = [[self getReferenceCount:wvUUID] integerValue];
    if (referenceCount > 0) {
        AMLogWarn(@"request failed; still have: %@ references to view", @(referenceCount));
        return false;
    }
    return true;
}

- (AMOAdView *)requestWithAdViewContext:(AMOAdViewContext *)adViewContext {
    if (!adViewContext) {
        return nil;
    }

    if (!am_obj_isString(adViewContext.adUnitId)) {
        return nil;
    }

    if (!am_obj_isString(adViewContext.url)) {
        return nil;
    }

    if (!am_obj_isString(adViewContext.userAgent)) {
        return nil;
    }

    if (!am_obj_isNumber(adViewContext.height)) {
        return nil;
    }

    if (!am_obj_isNumber(adViewContext.width)) {
        return nil;
    }

    NSMutableArray *adViews = _adViewsByContext[adViewContext.toHash];
    if (adViews == nil) {
        adViews = [NSMutableArray array];
    }

    AMOAdView *found = nil;
    for (AMOAdView *adView in adViews) {
        if (adView.state != AD_RENDERED) {
            found = adView;
        }
    }

    if (found == nil) {
        AMLogDebug(@"building AdView helper with adViewContext (precaching initiated)\n\t %@", adViewContext.toHash);
        found = [self buildView:adViewContext];
        if (found != nil) {
            [_rootContainer addSubview:(id) found.adViewContainer];
            [adViews addObject:found];
            @synchronized (_adViewCollection) {
                _adViewCollection[found.getUUID] = found;
            }
            @synchronized (_adViewsByContext) {
                _adViewsByContext[adViewContext.toHash] = adViews;
            }
        }
    }
    return found;
}

- (AMOAdView *)requestWithBid:(AMOBidResponse *)bid {
    if (bid.nativeRender && _adViewCollection[bid.wvUUID]) {
        return _adViewCollection[bid.wvUUID];
    }
    return [self requestWithAdViewContext:[[AMOAdViewContext alloc] initWithBidResponse:bid]];
}

- (void)triggerNotification:(NSString *)wvUUID andMessage:(NSString *)message andArguments:(NSDictionary *)args {
    NSString *notificationName = nil;
    @try {
        notificationName = [NSString stringWithFormat:@"%@%@", wvUUID, message];
    } @catch (NSException *e) {
        AMLogError(@"MARKREADY ERROR");
        return;
    }
    @try {
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:args];
    } @catch (NSException *e) {
        AMLogDebug(@"postNotificationName ERROR  %@", notificationName);
        return;
    }

}

- (AMOAdView *)getAdViewByUuid:(NSString *)wvUUID {
    return _adViewCollection[wvUUID];
}

- (NSString *)getState:(NSString *)wvUUID {
    AMOAdView *adView;
    if (wvUUID == nil || !_adViewCollection[wvUUID] || (adView = _adViewCollection[wvUUID]) == nil) {
        return adViewStateValueString(NOT_FOUND);
    }
    return adViewStateValueString(adView.state);
}

- (void)logState {
    AMLogDebug(@"[Pool State Dump]");
    for (NSString *key in _sAdViewRefCount) {
        if (key == nil) {
            continue;
        }

        NSString *state = [self getState:key];
        state = state == nil ? @"UNKNOWN" : state;

        AMLogDebug(@"\t%@ => %@, %@", key, _sAdViewRefCount[key], state);
    }
    AMLogDebug(@"[End Pool State Dump]");
}

/**
 * Create a new AMOAdView instance based on an AMOAdViewContext
 *
 * @param adViewContext information about the new WebView's environment
 * @return the created AMOAdView
 */
- (AMOAdView *)buildView:(AMOAdViewContext *)adViewContext {
    if (AMOSdkManager.get == nil) {
        AMLogWarn(@"AppMonet has not been initialized. Failed to create AdView.");
        return nil;
    }

    if (!adViewContext) {
        return nil;
    }

    NSString *jsSource = [NSString stringWithFormat:@"%@/js/%@-sdk.v2.js?v=%@&",
                    BASE_URL, AMSdkVersion, AMSdkVersion];
    NSString *adViewHtml = [NSString stringWithFormat:
            @"<html><head><script src=\"%@aid=%@\"></script></head><body><span></body></html>", jsSource,
            [AMOSdkManager.get.appMonetContext applicationId]];

    return [[AMOAdView alloc] initWithAdViewContext:adViewContext andHtml:adViewHtml andUuid:[[NSUUID UUID] UUIDString]];
}

/**
 * This method is executed when a notification for AMBidAdded is received. This internally will call the addReference
 * method and update the _adViewRefCount.
 *
 * @param notification  The notification received for AMBidAdded which cotains the bid's webview UUID which we use to
 * retrieve the current count and update it.
 */
- (void)addedBidNotification:(NSNotification *)notification {
    [self addReference:notification.userInfo[@"wvUUID"]];
}

/**
 * This method adds a reference count a webview's UUID key.
 *
 * @param wvUUID the webview UUID to add a reference to.
 */
- (void)addReference:(NSString *)wvUUID {
    @synchronized (_sAdViewRefCount) {
        NSNumber *count = _sAdViewRefCount[wvUUID];
        _sAdViewRefCount[wvUUID] = (count == nil) ? @1 : @([count intValue] + 1);
    }
}

/**
     * Check to see if the WebView has either too many references, or has been rendered too many times
     * (e.g. is eligible for removal).
     *
     * @param references  the number of bids currently cached in the view
     * @param renderCount the number of times that ads have been rendered in this view
     * @param force       causes it to always return true
     * @return whether or not the view can be removed
     */
- (BOOL)canPerformRemove:(NSInteger)references andRenderCount:(NSInteger)renderCount andForce:(BOOL)force {
    if (force || references == 0) {
        return true;
    }
    return (renderCount > kMaxRenderThreshHold) || (references < kRefMinThreshHold);
}

/**
 * Remove any references to the given WebView. This will remove it from the pool.
 *
 * @param wvUUID The UUID to remove references.
 */
- (void)cleanUpOrphanReference:(NSString *)wvUUID {
    @synchronized (_adViewCollection) {
        [_adViewCollection removeObjectForKey:wvUUID];
    }
    @synchronized (_adViewsReadyState) {
        [_adViewsReadyState removeObjectForKey:wvUUID];
    }
    @synchronized (_sAdViewRefCount) {
        [_sAdViewRefCount removeObjectForKey:wvUUID];
    }
    @synchronized (_messageHandlers) {
        [[NSNotificationCenter defaultCenter] removeObserver:_messageHandlers[wvUUID]];
        [_messageHandlers removeObjectForKey:wvUUID];
    }
}

/**
 * Receive a request to remove the given webview (from a notification)
 * @param notification Notification containing the wvUUID to remove
 */
- (void)removeHelperFrom:(NSNotification *)notification {
    if (!notification.userInfo) {
        return;
    }

    NSString *wvUUID = notification.userInfo[kAMWvUuidKey];
    if (!wvUUID) {
        AMLogDebug(@"no wvUUID present for RHF");
        return;
    }

    [self removeViewWithUUID:wvUUID andShouldAdViewBeDestroyed:YES];
}


/**
 * This method removes a bid from the reference counter and if remove cache is true we also
 * invalidate the bid id.
 *
 * @param notification  Notification containing information about the removed bid.
 */
- (void)removeBid:(NSNotification *)notification {
    AMOBidResponse *bid = notification.userInfo[kAMBidNotificationKey];
    BOOL removeCached = [notification.userInfo[kAMRemoveCreativeNotificationKey] boolValue];
    AMOAdView *adView = _adViewCollection[bid.wvUUID];
    [self removeReference:bid.wvUUID];
    if (adView != nil && removeCached) {
        [adView markBidInvalid:bid.id];
    }
}

/**
 * This method decreases the bid reference counter associated to the give webview UUID.
 *
 * @param wvUUID The UUID to remove a bid reference from.
 */
- (void)removeReference:(NSString *)wvUUID {
    @synchronized (_sAdViewRefCount) {
        NSNumber *count = _sAdViewRefCount[wvUUID];
        NSNumber *updatedCount = count == nil ? @0 : @([count intValue] - 1);
        _sAdViewRefCount[wvUUID] = updatedCount;
        if ([updatedCount intValue] <= 0) {
            AMLogDebug(@"reference count <=0; can be removed");
        }
    }
}

/**
 * This method will update the adView reference count to match the size maintained by the {@link AMOBidManager}.
 *
 * @param notification This dictionary contains the bid ids of each adView. This value is used to sync up the adView
 * reference count.
 */
- (void)syncWithBidManager:(NSNotification *)notification {
    @autoreleasepool {
        NSDictionary *bidIdsByAdView = notification.userInfo;
        for (NSString *key in bidIdsByAdView) {
            NSMutableArray *bidIds = bidIdsByAdView[key];
            if (bidIds == nil || bidIds.count == 0) {
                continue;
            }

            NSInteger referenceCount = [[self getReferenceCount:key] integerValue];
            if (referenceCount != bidIds.count) {
                AMLogWarn(@"reference count mismatch. Updating reference count in adView: referenceCount=%@ / bidCount = %@",
                        @(referenceCount), @(bidIds.count));
                [self updateReferenceCount:key refCount:@(bidIds.count)];
            }
        }
    }
}

/**
 * This method updates the reference count of how many bids are associated to a particular webview UUID.
 *
 * @param wvUUID The UUID associated to a webview.
 * @param refCount  The number of bid references.
 */
- (void)updateReferenceCount:(NSString *)wvUUID refCount:(NSNumber *)refCount {
    @synchronized (_sAdViewRefCount) {
        AMLogDebug(@"updating reference count for %@ to count: %@", wvUUID, refCount);
        _sAdViewRefCount[wvUUID] = refCount;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
