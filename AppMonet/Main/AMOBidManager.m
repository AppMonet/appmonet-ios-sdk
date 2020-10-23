//
// Created by Jose Portocarrero on 11/1/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMOBidManager.h"
#import "AMOConstants.h"
#import "AMOBidResponse.h"
#import "AMOBidValidity.h"
#import "AMOAdSize.h"
#import "AMOSdkManager.h"
#import "AMOAdViewPoolManager.h"
#import "AMOBasicValidityCallback.h"

@interface AMOBidManager ()
@property(nonatomic, strong) NSSortDescriptor *sortDescriptor;
@property(atomic, readwrite, strong) NSDictionary<NSString *, NSNumber *> *bidderExpiration;
@property(atomic, readwrite, strong) NSDictionary<NSString *, NSArray *> *store;
@property(atomic, readwrite, strong) NSDictionary <NSString *, NSString *> *adUnitNameMapping;
@property(atomic, readwrite, strong) NSDictionary<NSString *, NSArray *> *bidIdsByAdView;
@property(atomic, readwrite, strong) NSDictionary *usedBids;
@property(nonatomic, readonly, strong) dispatch_queue_t executionQueue;
@end

@implementation AMOBidManager

- (instancetype)initWithExecutionQueue:(dispatch_queue_t)executionQueue {
    self = [super init];
    if (self != nil) {
        _executionQueue = executionQueue;
        _bidderExpiration = [NSDictionary dictionary];
        _store = [NSDictionary dictionary];
        _adUnitNameMapping = [NSDictionary dictionary];
        _seenBids = [NSDictionary dictionary];
        _bidsById = [NSDictionary dictionary];
        _bidIdsByAdView = [NSDictionary dictionary];
        _usedBids = [NSDictionary dictionary];
        _sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"cpm" ascending:false];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanBids) name:kAMDestroyNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)addBids:(NSArray *)bids {
    for (AMOBidResponse *bidResponse in bids) {
        [self addBid:bidResponse];
    }
}

- (AMOBidResponse *)fromDictionary:(NSDictionary *)dictionary {
    if (dictionary == nil || !dictionary[kAMBidBundleKey]) {
        return nil;
    }
    return dictionary[kAMBidBundleKey];
}

- (void)addBid:(nullable AMOBidResponse *)bid toDictionary:(nullable NSMutableDictionary *)dictionary {
    if (dictionary == nil || bid == nil) {
        return;
    }
    dictionary[kAMBidBundleKey] = bid;
}

- (void)addBidsFromArray:(NSArray *)bids defaultUrl:(NSString *)defaultUrl {

    NSMutableArray *bidResponseArray = [NSMutableArray array];
    NSArray *bidsInArray = bids[1];
    for (NSDictionary *bidInformation in bidsInArray) {
        AMOBidResponse *bidResponse = [[AMOBidResponse alloc] init];
        bidResponse.adm = bidInformation[kAMAdmKey];
        bidResponse.id = bidInformation[kAMIdKey];
        bidResponse.code = (bidInformation[kAMCodeKey]) ? bidInformation[kAMCodeKey] : kAMDefaultBidderKey;
        bidResponse.width = bidInformation[kAMWidthKey];
        bidResponse.height = bidInformation[kAMHeightKey];
        bidResponse.createdAt = bidInformation[kAMTsKey];
        bidResponse.cpm = bidInformation[kAMCpmKey];
        bidResponse.bidder = bidInformation[kAMBidderKey];
        bidResponse.adUnitId = bidInformation[kAMAdUnitIdKey];
        bidResponse.keyWords = bidInformation[kAMKeyWordsKey];
        bidResponse.renderPixel = bidInformation[kAMRenderPixelKey];
        bidResponse.clickPixel = bidInformation[kAMClickPixelKey];
        bidResponse.u = bidInformation[kAMUKey];
        bidResponse.orientation = bidInformation[kAMOrientationKey];
        @autoreleasepool {
            bidResponse.uuid = [[NSUUID UUID] UUIDString];
        }
        bidResponse.cool = bidInformation[kAMCoolKey];
        bidResponse.nativeRender = [bidInformation[kAMNativeRenderKey] boolValue];
        bidResponse.wvUUID = bidInformation[kAMWvUuidKey];
        bidResponse.duration = bidInformation[kAMDurationKey];
        bidResponse.expiration = bidInformation[kAMExpirationKey];
        bidResponse.url = (bidInformation[kAMUrlKey] != [NSNull null]) ? bidInformation[kAMUrlKey] : defaultUrl;
        bidResponse.queueNext = (BOOL) bidInformation[kAMQueueNextKey];
        bidResponse.flexSize = (BOOL) bidInformation[kAMFlexSizeKey];
        bidResponse.refresh = (bidInformation[kAMRefreshKey]) ? bidInformation[kAMRefreshKey] : @0;
        bidResponse.interstitial = bidInformation[kAMInterstitialKey];
        bidResponse.extras = bidInformation[kAMBidExtrasKey];

        [bidResponseArray addObject:bidResponse];
    }
    [self addBids:bidResponseArray];
}

- (BOOL)areBidsAvailableForAdUnit:(nonnull NSString *)adUnitId andAdSize:(nullable AMOAdSize *)adSize
                      andFloorCpm:(nonnull NSNumber *)floorCpm andBidArrayReference:(AMOBidResponse **)bid
                        andAdType:(AMOAdType)adType andShouldRequestMore:(BOOL)requestMore {
    *bid = [self getBidForMediation:adUnitId andAdSize:adSize andFloorCpm:floorCpm andAdType:adType
           andShouldIndicateRequest:requestMore];
    if (*bid == nil) {
        AMLogDebug(@"no bid found");
        return NO;
    }
    return YES;
}

- (void)cleanBids {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.executionQueue, ^{
        if (weakSelf) {
            NSDictionary<NSString *, NSArray *> *localStore = [weakSelf.store copy];
            for (NSString *key in localStore) {
                [weakSelf cleanBidsForAdUnit:key];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kAMCleanUpBidsNotification object:nil
                                                              userInfo:weakSelf.bidIdsByAdView];
        }
    });
}

- (NSInteger)countBids:(nullable NSString *)adUnitId {
    NSInteger count = 0;
    if (adUnitId != nil) {
        NSArray *adUnitStore = [self.store[[self resolveAdUnitId:adUnitId]] copy];
        if (adUnitStore != nil) {
            count = [adUnitStore count];
        }
    }
    return count;
}

- (AMOBidResponse *)getBidForAdUnit:(NSString *)adUnitId {
    return [self getBidForAdUnit:adUnitId andBidValidity:[[AMOBasicValidityCallback alloc] initWithBidManager:self]];
}

- (nullable AMOBidResponse *)getBidForMediation:(NSString *)adUnitId andAdSize:(AMOAdSize *)adSize
                                    andFloorCpm:(NSNumber *)floorCpm andAdType:(AMOAdType)adType
                       andShouldIndicateRequest:(BOOL)indicateRequest {
    AMOBidResponse *mediationBid = [self peekNextBid:adUnitId];
    @autoreleasepool {
        if (indicateRequest) {
            [[AMOSdkManager get] indicateRequest:adUnitId withAdSize:adSize forAdType:adType andFloorCpm:floorCpm];
        }
    }

    if (mediationBid == nil || ![self isValid:mediationBid] || [mediationBid.cpm doubleValue] < [floorCpm doubleValue]) {
        if (mediationBid != nil) {
            AMLogDebug(@"next bid does not meet floor: %@ < %@", mediationBid.cpm, floorCpm);
        }
        AMLogDebug(@"no bid found for %@", adUnitId);
        return nil;
    }
    return mediationBid;
}

- (nullable AMOBidResponse *)getBidForAdUnit:(NSString *)adUnitId andBidValidity:(id <AMOBidValidity>)checker {
    @synchronized (self.store) {
        NSArray *store = [[self getStoreForAdUnit:adUnitId] copy];

        if (store == nil) {
            return nil;
        }

        NSMutableArray *sortedArray = [[store sortedArrayUsingDescriptors:@[self.sortDescriptor]] mutableCopy];
        AMOBidResponse *bid = nil;
        if (store.count > 0) {
            bid = [self filterBidsFromQueue:sortedArray andBidValidity:checker];
            [self putStoreForAdUnit:adUnitId andQueue:sortedArray];
        }
        return bid;
    }
}

- (void)invalidateForView:(NSString *)wvUUID {
    NSArray *bidIds = [self.bidIdsByAdView[wvUUID] copy];
    if (bidIds != nil) {
        AMLogDebug(@"invalidating all for: %@", wvUUID);
        for (NSString *id in bidIds) {
            [self removeBid:id];
        }
    } else {
        AMLogDebug(@"bid ids not found for %@", wvUUID);
    }
}

- (NSString *)invalidFlag:(AMOBidResponse *)bid {
    if ([self isBidUsed:bid]) {
        return @"USED_BID";
    }

    if ([self hasBidExpired:bid]) {
        return @"EXPIRED_BID";
    }

    if (![self renderWebViewExists:bid]) {
        return @"MISSING_WEBVIEW";
    }

    return @"INVALID_ADM";
}

- (NSString *)invalidReason:(AMOBidResponse *)bid {
    if ([self isBidUsed:bid]) {
        return @"bid used";
    }

    if ([self hasBidExpired:bid]) {
        return @"bid expired";
    }

    if (![self renderWebViewExists:bid]) {
        return @"missing render webView";
    }
    return [NSString stringWithFormat:@"invalid adm -%@", bid.adm];
}

- (BOOL)isBidAttachable:(AMOBidResponse **)bid forAdUnitId:(NSString *)adUnitId {
    if (![self isValid:*bid]) {
        AMOBidResponse *nextBid = [self peekNextBid:adUnitId];

        if (nextBid != nil && bid != nil) {
            if (![self isValid:*bid] && [nextBid.cpm doubleValue] >= [[*bid cpm] doubleValue]) {
                AMLogDebug(@"bid is not valid, using next bid. %@", [self invalidReason:*bid]);
                *bid = nextBid;
            } else {
                AMLogDebug(@"unable to attach next bid ...");
                return NO;
            }
        } else {
            AMLogDebug(@"bid is invalid -  %@", [self invalidReason:*bid]);
            return NO;
        }
    }
    return YES;
}

- (BOOL)isValid:(nullable AMOBidResponse *)bid {
    return bid != nil && ![self isBidUsed:bid] && bid.adm != nil && ![self hasBidExpired:bid]
            && (![bid.adm isEqualToString:@""]) && [self renderWebViewExists:bid];
}

- (void)logState {
#if DEBUG
    AMLogDebug(@"[Bid State Dump]");
    for (NSString *key in [self.store copy]) {
        AMLogDebug([NSString stringWithFormat:@"\t%@ => %@ bids", key, @([self countBids:key])]);
    }
    AMLogDebug(@"[End Bid State Dump]");
#endif
}

- (void)markUsed:(AMOBidResponse *)bid {

    @synchronized (self.usedBids) {
        NSMutableDictionary *mutableUsedBids = [self.usedBids mutableCopy];
        mutableUsedBids[bid.uuid] = bid.id;
        self.usedBids = [mutableUsedBids copy];
    }
}

- (AMOBidResponse *)peekBidForAdUnit:(NSString *)adUnitId {
    return [self peekBidForAdUnit:adUnitId andBidValidity:[[AMOBasicValidityCallback alloc] initWithBidManager:self]];
}

- (nullable AMOBidResponse *)peekBidForAdUnit:(nonnull NSString *)adUnitId andBidValidity:(nonnull id <AMOBidValidity>)checker {
    @synchronized (self.store) {
        NSMutableArray *store = [[self getStoreForAdUnit:adUnitId] mutableCopy];
        if (store == nil) {
            return nil;
        }
        AMOBidResponse *peekedBid = nil;
        NSMutableArray *sortedArray = [[store sortedArrayUsingDescriptors:@[self.sortDescriptor]] mutableCopy];
        for (AMOBidResponse *bid in sortedArray) {
            if ([checker isValid:bid]) {
                peekedBid = bid;
                break;
            }
        }
        return peekedBid;
    }
}

- (AMOBidResponse *)peekNextBid:(NSString *)adUnitId {
    return [self peekBidForAdUnit:adUnitId andBidValidity:[[[AMOBasicValidityCallback alloc] init]
            initWithBidManager:self]];
}

- (AMOBidResponse *)removeBid:(NSString *)bidId {
    return [self removeBid:bidId andShouldDestroyCreative:true];
}

- (BOOL)setAdUnitNames:(NSDictionary *)adUnits {
    @synchronized (self.adUnitNameMapping) {
        NSMutableArray *requested = adUnits[@"requested"];
        NSMutableArray *found = adUnits[@"found"];

        if (requested == nil || found == nil) {
            return false;
        }

        if (requested.count == 0) {
            return true;
        }
        NSMutableDictionary *mutableAdUnitNameMapping = [self.adUnitNameMapping mutableCopy];
        for (NSInteger i = 0, l = requested.count; i < l; i++) {
            NSString *req = requested[(NSUInteger) i];
            NSString *match = found[(NSUInteger) i];
            if (req != nil && match != nil) {
                mutableAdUnitNameMapping[req] = match;
            }
        }
        self.adUnitNameMapping = [mutableAdUnitNameMapping copy];
        return true;
    }
}

- (void)setBidderData:(NSArray *)bidderData {
    NSUInteger count = [bidderData count];
    @synchronized (self.bidderExpiration) {
        NSMutableDictionary *mutableBidderExpiration = [self.bidderExpiration mutableCopy];
        for (NSUInteger i = 0; i < count; i++) {
            if (![bidderData[i] isKindOfClass:[NSDictionary class]]) {
                return;
            }

            NSDictionary *adapters = bidderData[i];
            if (adapters[@"expiration"]) {
                for (NSString *key in adapters) {
                    for (NSString *innerKey in adapters[key]) {
                        mutableBidderExpiration[innerKey] = adapters[key][innerKey];
                    }
                }
            }
        }
        self.bidderExpiration = [mutableBidderExpiration copy];
        AMLogDebug(@"AMOBidManager | setBidderData | bidderExpirationDictionary count : %@", @([self.bidderExpiration count]));
    }
}

- (AMOBidResponse *)getBidWithId:(NSString *)bidId {
    return self.bidsById[bidId];
}


/**
 * todo  - documentation
 *
 * @param bid todo
 */

- (void)addBid:(AMOBidResponse *)bid {
    if (![self isValid:bid]) {
        AMLogWarn(@"attempt to add invalid bid. reason: %@", [self invalidReason:bid]);
        return;
    }
    @synchronized (self.store) {
        NSMutableDictionary *mutableSeenBids = [self.seenBids mutableCopy];
        NSMutableDictionary *mutableBidsById = [self.bidsById mutableCopy];
        NSMutableDictionary<NSString *, NSArray *> *mutableBidIdsByAdView = [self.bidIdsByAdView mutableCopy];
        NSMutableArray *queue = [[self getStoreForAdUnit:bid.adUnitId] mutableCopy];
        if (queue == nil) {
            queue = [NSMutableArray array];
            [self putStoreForAdUnit:bid.adUnitId andQueue:[queue copy]];
        }

        if (self.seenBids[bid.id]) {
            return;
        }

        NSString *bidId = [[NSString alloc] initWithString:bid.id];
        mutableSeenBids[bidId] = bidId;
        mutableBidsById[bidId] = bid;

        AMLogInfo(@"added bid: %@", [bid description]);

        if (bid.nativeRender && !bid.nativeInvalidated) {
            AMLogDebug(@"adding reference for bid.");
            NSMutableArray *bidIds = [mutableBidIdsByAdView[bid.wvUUID] mutableCopy];
            if (bidIds == nil) {
                bidIds = [NSMutableArray array];
            }
            [bidIds addObject:bidId];
            [mutableBidIdsByAdView removeAllObjects];
            mutableBidIdsByAdView[bid.wvUUID] = [bidIds copy];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AMBidAdded" object:nil
                                                              userInfo:@{@"wvUUID": bid.wvUUID}];
        }
        self.seenBids = [mutableSeenBids copy];
        self.bidsById = [mutableBidsById copy];
        self.bidIdsByAdView = [mutableBidIdsByAdView copy];
        [queue addObject:bid];
        [self putStoreForAdUnit:bid.adUnitId andQueue:[queue copy]];
    }
}

- (void)cleanBidsForAdUnit:(NSString *)adUnit {
    @autoreleasepool {
        NSMutableArray *removeBids = [NSMutableArray array];
        @synchronized (self.store) {
            NSArray *queue = [[self getStoreForAdUnit:adUnit] copy];

            if (queue == nil) {return;}
            NSMutableArray<AMOBidResponse *> *cleanedQueue = [NSMutableArray arrayWithCapacity:10];

            for (AMOBidResponse *bid in queue) {
                if (![self isValid:bid]) {
                    [removeBids addObject:bid];
                    AMLogDebug(@"Removing invalid bid:  %@", bid.description);
                } else {
                    [cleanedQueue addObject:bid];
                }
            }
            [self putStoreForAdUnit:adUnit andQueue:cleanedQueue];
            NSMutableDictionary *messagePayload = [NSMutableDictionary dictionary];
            NSMutableDictionary *mutableBidsById = [self.bidsById mutableCopy];
            @synchronized (self.bidsById) {
                for (AMOBidResponse *removedBid in removeBids) {
                    messagePayload[removedBid.id] = [self invalidFlag:removedBid];
                    [mutableBidsById removeObjectForKey:removedBid.id];
                    [self invalidateBid:removedBid andRemoveCreative:true];
                }
                self.bidsById = [mutableBidsById copy];
            }
            if (messagePayload.count != 0) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kAMBidsRemovedNotification object:nil
                                                                  userInfo:[messagePayload copy]];
            }
        }
    }
}

- (nonnull AMOBidResponse *)filterBidsFromQueue:(nullable NSMutableArray *)queue andBidValidity:(nonnull id <AMOBidValidity>)validator {
    if (queue == nil || [queue count] == 0) {
        return nil;
    }
    AMOBidResponse *bid = queue[0];
    while (![validator isValid:bid]) {
        if (bid != nil) {
            [queue removeObject:bid];
        }
        if ([queue count] == 0) {
            bid = nil;
            break;
        }
        bid = queue[0];
        if (bid == nil) {
            break;
        }
    }
    AMLogDebug(@"found bid @ top of queue: %@", bid.description);
    return bid;
}

- (NSNumber *)getBidExpiration:(AMOBidResponse *)bid {
    @synchronized (self.bidderExpiration) {
        NSNumber *expiration = self.bidderExpiration[bid.bidder];

        if (expiration == nil) {
            expiration = @120;
        }
        return @([expiration longValue] * 1000);
    }
}

- (NSArray *)getStoreForAdUnit:(NSString *)adUnitId {
    NSString *adUnitID = [self resolveAdUnitId:adUnitId];
    return self.store[adUnitID];
}

- (BOOL)hasBidExpired:(AMOBidResponse *)bid {
    double ttl = [self ttl:bid];
    NSNumber *expiration = [self getBidExpiration:bid];
    BOOL hasBidExpired = ttl > [expiration doubleValue];
    return hasBidExpired;
}

- (void)invalidateBid:(AMOBidResponse *)bid andRemoveCreative:(BOOL)removeCreative {
    @synchronized (self.bidIdsByAdView) {
        if (bid.needsInvalidation) {
            NSMutableDictionary<NSString *, NSArray *> *mutableBidIdsByAdView = [self.bidIdsByAdView mutableCopy];
            NSMutableArray *bidIds = [mutableBidIdsByAdView[bid.wvUUID] mutableCopy];
            if (bidIds != nil) {
                [bidIds removeObject:bid.id];
            }
            mutableBidIdsByAdView[bid.wvUUID] = [bidIds copy];
            self.bidIdsByAdView = [mutableBidIdsByAdView copy];
            NSMutableDictionary *messagePayload = [NSMutableDictionary dictionary];
            messagePayload[kAMBidNotificationKey] = bid;
            messagePayload[kAMRemoveCreativeNotificationKey] = @(removeCreative);
            [[NSNotificationCenter defaultCenter] postNotificationName:kAMBidsInvalidatedNotification object:nil
                                                              userInfo:[messagePayload copy]];
            [bid markInvalidated];
        }
    }
}

- (BOOL)isBidUsed:(AMOBidResponse *)bid {
    BOOL isBidUsed = self.usedBids[bid.uuid] != nil;
    // AMLogDebug(@"isBidUsed: %@", isBidUsed ? @"YES" : @"NO");
    return isBidUsed;
}

- (void)putStoreForAdUnit:(NSString *)adUnitId andQueue:(NSArray *)store {
    NSMutableDictionary *mutableStore = [self.store mutableCopy];
    mutableStore[[self resolveAdUnitId:adUnitId]] = store;
    self.store = [mutableStore copy];
}

- (BOOL)renderWebViewExists:(AMOBidResponse *)bid {
    if (!bid.nativeRender || bid.wvUUID == nil) return true;
    return ([[[AMOSdkManager get] adViewPoolManager] containsView:bid.wvUUID]);
}

- (NSString *)resolveAdUnitId:(NSString *)adUnitId {
    return ([[self.adUnitNameMapping allKeys] containsObject:adUnitId]) ? self.adUnitNameMapping[adUnitId] : adUnitId;
}

- (AMOBidResponse *)removeBid:(NSString *)bidId andShouldDestroyCreative:(BOOL)destroyCreative {
    AMLogDebug(@"removing bid %@", bidId);
    if (!self.bidsById[bidId]) {
        return nil;
    }
    AMOBidResponse *bid = self.bidsById[bidId];
    if (bid == nil) {
        AMLogWarn(@"attempt to remove an invalid bid %@", bidId);
        return nil;
    }

    [self markUsed:bid];
    @synchronized (self.store) {
        NSMutableArray *collections = [[self getStoreForAdUnit:bid.adUnitId] mutableCopy];
        if (collections != nil) {
            [collections removeObject:bid];
            [self putStoreForAdUnit:bid.adUnitId andQueue:[collections copy]];
        }
        [self invalidateBid:bid andRemoveCreative:destroyCreative];
        return bid;
    }
}

- (double)ttl:(AMOBidResponse *)bid {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    return (now * 1000) - [[bid createdAt] doubleValue];

}

@end
