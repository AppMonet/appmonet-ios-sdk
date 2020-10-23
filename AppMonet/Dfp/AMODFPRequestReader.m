//
// Created by Nick Jacob on 2019-04-16.
// Copyright (c) 2019 AppMonet. All rights reserved.
//

#import "AMODFPRequestReader.h"
#import "AMOConstants.h"
#import "AMOBidResponse.h"
#import "AMOSdkManager.h"
#import "AMOBidManager.h"
#import "AMOUtils.h"
#import "AMODfpAdRequest.h"
#import "AMOAppMonetBidder.h"
#import "AMODfpAdSize.h"


@import GoogleMobileAds;

@implementation AMODFPRequestReader {

}

+ (NSString *)extractAdUnitID:(GADCustomEventRequest *)request andServerLabel:(NSString *)serverLabel
              withServerValue:(NSString *)serverValue andAdSize:(AMOAdSize *)adSize {
    if (request.additionalParameters[kAMAdUnitKeywordKey]) {
        return request.additionalParameters[kAMAdUnitKeywordKey];
    }

    NSString *adUnitId = nil;
    if (![serverValue hasPrefix:@"$"]) {
        adUnitId = [AMODFPRequestReader parseServerValue:serverValue][0];
    }
    if (adUnitId.length == 0) {
        adUnitId = [AMODFPRequestReader getWidthHeightAdUnit:adSize];
    }
    return adUnitId;
}

+ (NSString *)getWidthHeightAdUnit:(AMOAdSize *)adSize {
    NSString *adUnitId = nil;
    if (adSize && ![adSize.height isEqualToNumber:@0] && ![adSize.width isEqualToNumber:@0]) {
        adUnitId = [NSString stringWithFormat:@"%@x%@", adSize.width, adSize.height];
    }
    return adUnitId;
}

+ (NSNumber *)getCpm:(NSString *)serverParameter {
    if (serverParameter.length == 0) {
        return @0;
    }

    if ([serverParameter hasPrefix:@"$"]) {
        return @([serverParameter substringFromIndex:1].floatValue);
    }

    NSArray *values = [AMODFPRequestReader parseServerValue:serverParameter];

    if ([values count] == 2) {
        NSString *cpm = values[1];
        if (cpm) {
            return @(cpm.floatValue);
        }
    }
    return @0;
}

+ (NSArray *)parseServerValue:(NSString *)serverValue {
    return [serverValue componentsSeparatedByString:@"@$"];
}

+ (void)queueNextDemand:(AMOBidResponse *)bid adUnitID:(NSString *)adUnitID andRequest:(GADCustomEventRequest *)request {
    // should queue -- is the bid nil?
    BOOL shouldQueue = bid == nil || bid.queueNext;

    AMOAdServerAdRequest *internalRequest = [[AMODfpAdRequest alloc] initWithCustomEventRequest:request];

    // get the next bid
    AMOBidResponse *nextBid = nil;
    if (shouldQueue) {
        nextBid = [AMOSdkManager.get.auctionManager getRawBid:adUnitID];
    }

    [AMOSdkManager.get.appMonetBidder cancelRequest:adUnitID andAMServerAdRequest:internalRequest andBidResponse:nextBid];
}

+ (AMOBidResponse *)bidResponseFromMediation:(GADCustomEventRequest *)request andAdSize:(AMOAdSize *)adSize
                                 andAdUnitID:(NSString *)adUnitID andCpmFloor:(NSNumber *)cpm andAdType:(AMOAdType)adType {
    AMOBidManager *bidManager = AMOSdkManager.get.bidManager;
    if (bidManager == nil) {
        AMLogWarn(@"no bid manager!");
        return nil;
    }
    AMOBidResponse *bid;
    if (![bidManager areBidsAvailableForAdUnit:adUnitID andAdSize:adSize andFloorCpm:cpm andBidArrayReference:&bid
                                     andAdType:adType andShouldRequestMore:YES]) {
        AMLogWarn(@"no bids available for mediation");
        return nil;
    }

    // very weird that we do this...
    if (![bidManager isBidAttachable:&bid forAdUnitId:adUnitID]) {
        AMLogWarn(@"found a bid; not attachable");
        return nil;
    }

    return bid;
}

+ (AMOBidResponse *)bidResponseFromHeaderBidding:(GADCustomEventRequest *)request
                                  andServerLabel:(NSString *)serverLabel
                                     andAdUnitID:(NSString *)adUnitID {
    AMOBidManager *bidManager = [[AMOSdkManager get] bidManager];
    if (!bidManager) {
        AMLogWarn(@"No bid manager!");
        return nil;
    }

    if (!am_obj_isString(adUnitID)) {
        AMLogWarn(@"No ad unit ID!");
        return nil;
    }

    AMOBidResponse *potentialBid = [bidManager fromDictionary:request.additionalParameters];

    if (potentialBid == nil || potentialBid.id == nil) {
        // "clear" the request, which will enqueue another bid.. since we *kind* of won this one
        [AMODFPRequestReader queueNextDemand:nil adUnitID:adUnitID andRequest:request];
        return nil;
    }

    // 2. check if there is a higher bid than the one we just fetched..
    AMOBidResponse *peeked = [bidManager peekNextBid:adUnitID];
    if (peeked != nil && [potentialBid.cpm doubleValue] >= [peeked.cpm doubleValue]) {
        // returning nil here will go into "mediation" mode, which will return the correct bid
        // so it's better to just return nil...
        peeked = nil;
    }

    [AMODFPRequestReader queueNextDemand:potentialBid adUnitID:adUnitID andRequest:request];

    // peeked is valid
    if (peeked != nil && [bidManager isValid:peeked]) {
        AMLogInfo(@"Next bid is higher cpm & valid size. Falling into mediation;");
        return nil;
    }

    if (![bidManager isValid:potentialBid]) {
        AMLogInfo(@"Current bid is invalid - %@. Checking next bid", [bidManager invalidReason:potentialBid]);
        AMOBidResponse *nextBid = [AMOSdkManager.get.auctionManager getRawBid:adUnitID];
        if (nextBid == nil || ![bidManager isValid:nextBid]) {
            AMLogInfo(@"next bid is not good -- returning nothing");
            return nil;
        }

        // otherwise, our bid choice is good
        potentialBid = nextBid;
    }

    return potentialBid;
}
@end
