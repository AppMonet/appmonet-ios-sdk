//
// Created by Jose Portocarrero on 11/2/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMOBidResponse.h"
#import "AMOConstants.h"

NSString *const kAMCodeKey = @"code";
NSString *const kAMAdmKey = @"adm";
NSString *const kAMWidthKey = @"width";
NSString *const kAMUrlKey = @"url";
NSString *const kAMHeightKey = @"height";
NSString *const kAMIdKey = @"id";
NSString *const kAMTsKey = @"ts";
NSString *const kAMCpmKey = @"cpm";
NSString *const kAMBidderKey = @"bidder";
NSString *const kAMUuidKey = @"uuid";
NSString *const kAMAdUnitIdKey = @"adUnitId";
NSString *const kAMFlexSizeKey = @"flexSize";
NSString *const kAMKeyWordsKey = @"keywords";
NSString *const kAMRenderPixelKey = @"renderPixel";
NSString *const kAMClickPixelKey = @"clickPixel";
NSString *const kAMCoolKey = @"cdown";
NSString *const kAMApplicationIdKey = @"appId";
NSString *const kAMQueueNextKey = @"queueNext";
NSString *const kAMNativeRenderKey = @"naRender";
NSString *const kAMExpirationKey = @"expiration";
NSString *const kAMWvUuidKey = @"wvUUID";
NSString *const kAMUKey = @"u";
NSString *const kAMOrientationKey = @"inst";
NSString *const kAMDurationKey = @"duration";
NSString *const kAMInterstitialKey = @"interstitial";
NSString *const kAMInterstitialCloseKey = @"close";

NSString *const kAMRefreshKey = @"refresh";

NSString *const kAMBidBundleKey = @"__bid__";
NSString *const kAMBidExtrasKey = @"extras";

//todo need to finish implementing methods from here.!!!!
@implementation AMOBidResponse



- (NSString *)description {
    return [NSString stringWithFormat:@"<BidResponse cpm=%@ bidder=%@ width=%@ height=%@ id=%@ auid=%@ code=%@ />",
                                      _cpm, _bidder, _width, _height, _id, _adUnitId, _code];
}

- (BOOL)needsInvalidation {
    return _nativeRender && !_nativeInvalidated;
}

- (void)markInvalidated {
    if ([self needsInvalidation]) {
        _nativeInvalidated = true;
    }

}

//todo - documentation


@end
