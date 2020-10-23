//
//  AMOMopubAdServerWrapper.m
//  AppMonet_Mopub
//
//  Created by Jose Portocarrero on 12/7/17.
//  Copyright © 2017 AppMonet. All rights reserved.
//


#import "AMOMopubAdServerWrapper.h"
#import "AMOAuctionRequest.h"
#import "AMOMopubAdRequest.h"
#import "AMOMopubNativeAdRequest.h"
#import "AMOMopubInterstitialAdRequest.h"
#import "AMOAdSize.h"

@protocol AMServerAdRequest;

@implementation AMOMopubAdServerWrapper {
}

- (id <AMServerAdRequest>)newAdRequest:(AMOAuctionRequest *)auctionRequest {
    return [AMOMopubAdRequest fromAuctionRequest:auctionRequest];
}

- (id <AMServerAdRequest>)newAdRequest:(AMOAuctionRequest *)auctionRequest andAdType:(AMType)type {
    if (type == kAMNative) {
        return [AMOMopubNativeAdRequest fromAuctionRequest:auctionRequest];
    }
    if(type == kAMInterstitial){
        return [AMOMopubInterstitialAdRequest fromAuctionRequest:auctionRequest];
    }
    return [AMOMopubAdRequest fromAuctionRequest:auctionRequest];
}

- (id <AMServerAdRequest>)newAdRequest {
    return [[AMOMopubAdRequest alloc] init];
}

- (AMOAdSize *)newAdSize:(NSNumber *)width andHeight:(NSNumber *)height {
    return [[AMOAdSize alloc] initWithWidth:width andHeight:height];
}

@end
