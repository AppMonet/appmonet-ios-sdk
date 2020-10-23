//
// Created by Jose Portocarrero on 10/27/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMOAuctionManager.h"
#import "AMODeviceData.h"
#import "AMOConstants.h"
#import "AMOPreferences.h"
#import "AMOAppMonetContext.h"
#import "AMOBidManager.h"
#import "AMOAuctionRequest.h"
#import "AMOAdServerAdRequest.h"
#import "AMOAdServerAdView.h"
#import "AMOBidResponse.h"
#import "AMORequestData.h"
#import "AMOUtils.h"
#import "AMOAdViewPoolManager.h"
#import "AMORemoteConfiguration.h"
#import "AMOAdSize.h"


@implementation AMOAuctionManager {
    AMOBidManager *_bidManager;
}
- (id)initWithDeviceData:(AMODeviceData *)deviceData andBidManager:(AMOBidManager *)bidManager
      andAppMonetContext:(AMOAppMonetContext *)applicationContext andPreferences:(AMOPreferences *)preferences
    andAdViewPoolManager:(AMOAdViewPoolManager *)adViewPoolManager andExecutionQueue:(dispatch_queue_t)executionQueue
             andDelegate:(id <AMOAuctionManagerDelegate>)delegate andRootContainer:(UIView *)rootContainer {
    if (self = [super init]) {
        _deviceData = deviceData;
        _bidManager = bidManager;
        _appMonetContext = applicationContext;
        _delegate = delegate;
        AMORemoteConfiguration *configuration = [[AMORemoteConfiguration alloc] initWithApplicationId:applicationContext.applicationId];
        [configuration getConfiguration:NO completion:nil];
        _auctionWebView = [[AMOAuctionWebView alloc] initWithDeviceData:_deviceData andRemoteConfiguration:configuration
                                                          andBidManager:_bidManager andPreferences:preferences
                                                     andAppMonetContext:_appMonetContext andAdViewPoolManager:adViewPoolManager
                                                      andExecutionQueue:executionQueue andCallback:^(AMOAuctionWebView *webView) {
                    [self startAuction];
                }];
        [rootContainer addSubview:_auctionWebView];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidateBids:)
                                                     name:kAMBidsRemovedNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (AMOAuctionRequest *)attachBid:(id <AMOAdServerAdView>)adView andAdServerAdRequest:(id <AMServerAdRequest>)adRequest
                  andBidResponse:(nullable AMOBidResponse *)bidResponse {
    AMOAuctionRequest *auctionRequest = [AMOAuctionRequest from:adView andAdServerAdRequest:adRequest];
    if (bidResponse != nil) {
        NSArray *kwStrings = @[bidResponse.keyWords];
        [self attachBidToNetworkExtras:auctionRequest.networkExtras andBid:bidResponse];
        auctionRequest.bid = bidResponse;
        NSDictionary *kwTargeting = [self keyWordStringtoDictionary:[kwStrings componentsJoinedByString:@","]];
        [auctionRequest.targeting addEntriesFromDictionary:kwTargeting];
    }
    return auctionRequest;
}

- (AMOAuctionRequest *)attachBid:(id <AMOAdServerAdView>)adView andAdServerAdRequest:(id <AMServerAdRequest>)adRequest {
    AMOBidResponse *bidResponse;
    if (!([self needsNewBids:adView andAdServerAdRequest:adRequest])) {
        AMLogDebug(@"request already has bids at equal/higher floor");
        bidResponse = [adRequest getBid];
    } else {
        bidResponse = [self getLocaBid:adView];
    }

    AMORequestData *data = [[AMORequestData alloc] initWithAdServerAdRequest:adRequest andAdServerAdView:adView];
    if (bidResponse != nil) {
        AMLogDebug(@"(sync) attaching bids to request");
        AMLogDebug(@"\t[sync/request] attaching: %@", [bidResponse description]);
        [self setRequestData:data];
        return [self attachBid:adView andAdServerAdRequest:adRequest andBidResponse:bidResponse];
    }

    NSMutableArray *args = [NSMutableArray array];
    [args addObject:adView.getAdUnitId];
    [args addObject:@"4000"];
    [args addObject:[AMOUtils toJson:data.toDictionary]];
    [args addObject:@"'addBids'"];

    [_auctionWebView callJsMethod:kAMFetchBids arguments:args waitForResponse:true callback:nil];

    AMOBidResponse *localBidResponse = [self getLocaBid:adView];
    return [self attachBid:adView andAdServerAdRequest:adRequest andBidResponse:localBidResponse];
}

- (void)setRequestData:(AMORequestData *)data {
    [_auctionWebView callJsMethod:kAMSetRequestData arguments:[[data toDictionary] mutableCopy] callback:nil];
}

- (void)attachBidAsync:(id <AMOAdServerAdView>)adView andAdServerAdRequest:(id <AMServerAdRequest>)adRequest
            andTimeout:(NSNumber *)timeout andValueBlock:(void (^)(AMOAuctionRequest *auctionRequest))block {

    NSString *adUnitId = adView.getAdUnitId;
    AMORequestData *data = [[AMORequestData alloc] initWithAdServerAdRequest:adRequest andAdServerAdView:adView];
    AMLogDebug(@"attaching bids asynchronously for adUnit: %@", adUnitId);

    if (![self needsNewBids:adView andAdServerAdRequest:adRequest]) {
        AMLogDebug(@"keeping current bids");
        if (block != nil) {
            block([self attachBid:adView andAdServerAdRequest:adRequest andBidResponse:adRequest.getBid]);
        } else {
            AMLogError(@"Auction manager attachBidAsync return block is null.");
        }
        return;
    }

    AMOBidResponse *bidResponse = [self getLocaBid:adView];

    if (bidResponse != nil) {
        AMLogDebug(@"attaching bids to request");
        AMLogDebug(@"\t[request] attaching: %@", bidResponse.description);

        block([self attachBid:adView andAdServerAdRequest:adRequest andBidResponse:bidResponse]);
        return;
    }

    AMLogDebug(@"bids are empty ... fetching more");
    NSMutableArray *args = [NSMutableArray array];
    [args addObject:(adUnitId) ? adUnitId : @""];
    [args addObject:[timeout stringValue]];
    [args addObject:[AMOUtils toJson:data.toDictionary]];
    [args addObject:@"'addBids'"];

    [_auctionWebView callJsMethod:kAMFetchBidsBlocking withTimeout:timeout arguments:args
                  waitForResponse:true callback:^(NSDictionary *response, NSError *error) {
                AMOBidResponse *localBidResponse;
                localBidResponse = [self getLocaBid:adView];
                if (localBidResponse != nil) {
                    AMLogDebug(@"attaching bids to request");
                    AMLogDebug(@"\t[request] attaching: %@", localBidResponse.description);

                    block([self attachBid:adView andAdServerAdRequest:adRequest andBidResponse:localBidResponse]);
                    return;
                }
                AMLogDebug(@"no bids received");
                block(nil);
            }];
}

- (AMOAuctionRequest *)addRawBid:(id <AMOAdServerAdView>)adView andServerAdRequest:(id <AMServerAdRequest>)baseRequest
                  andBidResponse:(AMOBidResponse *)bid {
    return [self attachBid:adView andServerAdRequest:baseRequest andBidResponse:bid];
}

- (AMOBidResponse *)getRawBid:(NSString *)adUnitId {
    AMOBidResponse *bid = [_bidManager getBidForAdUnit:adUnitId];

    if (bid == nil) {
        return nil;
    }

    [self markBidsUsed:adUnitId andBids:bid];

    return bid;
}

- (void)indicateRequest:(NSString *)adUnitId withAdSize:(AMOAdSize *)adSize forAdType:(AMOAdType)adType andFloorCpm:(NSNumber *)floorCpm {
    NSString *adTypeValue = adTypeValueString(adType);
    NSMutableArray *args = [NSMutableArray arrayWithArray:@[
            adUnitId, @"15000", @"{}", @"mediation", adTypeValue
    ]];

    if (adSize && ![adSize.height isEqualToNumber:@0] && ![adSize.width isEqualToNumber:@0]) {
        [args addObject:adSize.width];
        [args addObject:adSize.height];
    } else {
        [args addObject:@0];
        [args addObject:@0];
    }

    [args addObject:floorCpm];

    [_auctionWebView callJsMethod:kAMFetchBidsBlocking arguments:args callback:nil];
}

- (void)indicateRequestAsync:(NSString *)adUnitId andTimeout:(NSNumber *)timeout
                   andAdSize:(AMOAdSize *)adSize andAdType:(AMOAdType)adType andFloorCpm:(NSNumber *)floorCpm
              withValueBlock:(AMValueBlock)block {
    NSString *jsTimeout = (timeout.integerValue == 0) ? @"15000" : [timeout stringValue];
    NSString *adTypeValue = adTypeValueString(adType);
    NSMutableArray *args = [NSMutableArray arrayWithArray:@[
            adUnitId, jsTimeout, @"{}", @"iwait", adTypeValue
    ]];

    if (adSize && ![adSize.height isEqualToNumber:@0] && ![adSize.width isEqualToNumber:@0]) {
        [args addObject:adSize.width];
        [args addObject:adSize.height];
    } else {
        [args addObject:@0];
        [args addObject:@0];
    }
    [args addObject:floorCpm];

    JavascriptResponseHandler callback = (block) ? ^(NSDictionary *response, NSError *error) {
        block(response, error);
    } : nil;
    [_auctionWebView callJsMethod:kAMFetchBidsBlocking withTimeout:timeout arguments:args
                  waitForResponse:(block != nil) callback:callback];
}

- (void)syncLogger:(NSString *)logLevel {
    [_auctionWebView callJsMethod:@"setLogLevel" arguments:@[logLevel] callback:nil];
}

- (void)trackRequest:(NSString *)adUnitId andSource:(NSString *)source {
    NSMutableArray *args = [NSMutableArray array];
    [args addObject:adUnitId];
    [args addObject:source];
    [_auctionWebView callJsMethod:kAMTrackRequest arguments:args callback:^(NSDictionary *response, NSError *error) {
        if (error) {
            AMLogWarn(@"Error trying to track request. %@.", error);
        }
    }];
}


/*
 *  todo - documentation
 */
- (AMOAuctionRequest *)attachBid:(id <AMOAdServerAdView>)adView andServerAdRequest:(id <AMServerAdRequest>)adRequest
                  andBidResponse:(nullable AMOBidResponse *)bidResponse {
    AMOAuctionRequest *auctionRequest = [AMOAuctionRequest from:adView andAdServerAdRequest:adRequest];
    if (bidResponse != nil) {
        NSArray *kwStrings = @[bidResponse.keyWords];
        [self attachBidToNetworkExtras:auctionRequest.networkExtras andBid:bidResponse];
        auctionRequest.bid = bidResponse;
        NSMutableDictionary *kwTargeting = [self keyWordStringtoDictionary:[kwStrings componentsJoinedByString:@","]];
        [auctionRequest.targeting addEntriesFromDictionary:kwTargeting];
    }
    return auctionRequest;
}

- (void)attachBidToNetworkExtras:(nonnull NSMutableDictionary *)networkExtras andBid:(nonnull AMOBidResponse *)bid {
    [_bidManager addBid:bid toDictionary:networkExtras];
}

- (nullable AMOBidResponse *)getLocaBid:(nonnull id <AMOAdServerAdView>)adView {
    AMOBidResponse *bid = [_bidManager getBidForAdUnit:adView.getAdUnitId];
    [self markBidsUsed:adView.getAdUnitId andBids:bid];
    if (bid != nil) {
        AMLogDebug(@"found bid from local store. %@ bids remaining",
                @([_bidManager countBids:adView.getAdUnitId]));
    }
    return bid;
}

- (void)invalidateBids:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *messagePayload = notification.userInfo;
        if (!messagePayload) {
            return;
        }

        @try {
            [_auctionWebView callJsMethod:@"bidInvalidReason" arguments:@[messagePayload] callback:nil];
        } @catch (NSException *exception) {
            AMLogWarn(@"Failed to invalidate bids in js: %@", exception);
        }
    });
}

/**
 * Convert a formatted string into a bundle (of string:string mappings).
 * The input string should be in this format:
 * <p>
 * key1:value,key2:value2,key3:value3
 *
 * @param kwString a string of keywords in the expected format
 * @return a Bundle with string keys & String values
 */
- (NSMutableDictionary *)keyWordStringtoDictionary:(NSString *)kwString {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (NSString *kvp in [kwString componentsSeparatedByString:@","]) {
        NSArray *pair = [kvp componentsSeparatedByString:@":"];
        if (pair.count != 2) {
            continue;
        }
        dictionary[pair[0]] = pair[1];
    }
    return dictionary;
}

- (void)markBidsUsed:(nonnull NSString *)adUnitId andBids:(nullable AMOBidResponse *)bid {
    if (bid == nil) {
        return;
    }
    NSArray *jsonArray = @[@{@"id": bid.id}];
    [_auctionWebView callJsMethod:kAMBidsUsed arguments:jsonArray callback:nil];
}

- (void)testMode {
    [self.auctionWebView callJsMethod:@"testMode" arguments:@[] callback:nil];
}

- (void)startAuction {
    [self.auctionWebView callJsMethod:@"setLogLevel" arguments:@[logLevelToPrefix(getSetLogLevel())]
                             callback:^(NSDictionary *response, NSError *error) {
                                 if (error != nil) {
                                     //do nothing
                                 }
                             }];
    [self.auctionWebView callJsMethod:@"start" arguments:@[@"", _appMonetContext.applicationId]
                             callback:^(NSDictionary *response, NSError *error) {
                                 if (response && !error) {
                                     [self.delegate auctionManager:self started:nil];
                                 } else {
                                     [self.delegate auctionManager:self started:error];
                                 }
                             }];
}

- (void)trackEvent:(NSString *)eventName withDetail:(NSString *)detail andKey:(NSString *)key andValue:(NSNumber *)value
    andCurrentTime:(NSNumber *)currentTime {
    [self.auctionWebView                                                      callJsMethod:@"trackEvent" arguments:@[eventName, detail, (key) ? key : @"",
            (value != nil) ? value : @0, (currentTime != nil) ? currentTime : @0] callback:nil];
}

- (BOOL)needsNewBids:(id <AMOAdServerAdView>)adView andAdServerAdRequest:(id <AMServerAdRequest>)adRequest {
    AMOBidResponse *bid = [adRequest getBid];
    if (!adRequest.hasBids && bid == nil) {
        return true;
    }
    AMOBidResponse *newBid = [_bidManager peekBidForAdUnit:adView.getAdUnitId];
    if (newBid == nil) {
        AMLogDebug(@"no new bids. Leaving older bids");
        return false;
    }
    if ([_bidManager isValid:bid] && newBid.cpm > bid.cpm) {
        AMLogDebug(@"found newer bid @$%@. Need new bids", newBid.cpm);
        return true;
    }
    AMLogDebug(@"found bid, unneeded on request:  %@", newBid.description);
    AMLogDebug(@"no newer bids found");
    return false;
}


@end
