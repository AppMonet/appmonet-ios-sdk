//
// Created by Jose Portocarrero on 11/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMOAuctionRequest.h"
#import "AMOAdServerAdView.h"
#import "AMOAdServerAdRequest.h"
#import "AMOConstants.h"
#import "AMORequestData.h"
#import "AMOBidResponse.h"


@implementation AMOAuctionRequest {

}
+ (AMOAuctionRequest *)from:(id <AMOAdServerAdView>)adServerAdView andAdServerAdRequest:(id <AMServerAdRequest>)request {
    AMOAuctionRequest *auctionRequest = [[AMOAuctionRequest alloc] init];

    auctionRequest.networkExtras = [NSMutableDictionary dictionary];
    auctionRequest.adMobExtras = [NSMutableDictionary dictionary];
    auctionRequest.targeting = [NSMutableDictionary dictionary];

    auctionRequest.networkExtras[kAMAdUnitKeywordKey] = adServerAdView.getAdUnitId;
    auctionRequest.requestData = [[AMORequestData alloc] initWithAdServerAdRequest:request
                                                                 andAdServerAdView:adServerAdView];

    auctionRequest.adUnitId = adServerAdView.getAdUnitId;

    return [request apply:auctionRequest andAdServerAdView:adServerAdView];
}

@end