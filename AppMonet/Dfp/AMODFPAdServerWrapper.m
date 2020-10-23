//
// Created by Jose Portocarrero on 11/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMODFPAdServerWrapper.h"
#import "AMODfpAdRequest.h"
#import "AMODfpAdSize.h"
#import "AMOSdkManager.h"
#import  "AMOGADRequest.h"

@implementation AMODFPAdServerWrapper {

}
- (id <AMServerAdRequest>)newAdRequest:(AMOAuctionRequest *)auctionRequest {
    return [AMODfpAdRequest fromAuctionRequest:auctionRequest];
}

- (id <AMServerAdRequest>)newAdRequest:(AMOAuctionRequest *)auctionRequest andAdType:(AMType)type {
    if([AMOSdkManager get].isPublisherAdView){
        return [AMODfpAdRequest fromAuctionRequest:auctionRequest];
    }
    return [AMOGADRequest fromAuctionRequest:auctionRequest];
}

- (id <AMServerAdRequest>)newAdRequest {
    return [[AMODfpAdRequest alloc] init];
}

- (AMOAdSize *)newAdSize:(NSNumber *)width andHeight:(NSNumber *)height {
    return [[AMODfpAdSize alloc] initWithWidth:width andHeight:height];
}

@end
