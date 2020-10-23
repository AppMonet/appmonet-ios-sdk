//
// Created by Jose Portocarrero on 10/26/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AppMonet.h"
#import "AppMonetConfigurations.h"
#import "AMOAuctionWebView.h"
#import "AMOSdkManager.h"
#import "AMOConstants.h"
#import "AMODFPAdServerWrapper.h"

@import GoogleMobileAds;

@implementation AppMonet

+ (void)init:(AppMonetConfigurations *)appMonetConfigurations {
    [AppMonet initialize:appMonetConfigurations];
}

+ (void)init:(AppMonetConfigurations *)appMonetConfigurations withBlock:(void (^)(NSError *))block {
    [AppMonet initialize:appMonetConfigurations withBlock:block];
}

+ (void)initialize:(AppMonetConfigurations *)appMonetConfigurations {
    AppMonetConfigurations *internalConfigurations = appMonetConfigurations;
    if (appMonetConfigurations == nil) {
        internalConfigurations = [AppMonetConfigurations configurationWithBlock:^(AppMonetConfigurations *builder) {
            // do nothing
        }];
    }

    [AMOSdkManager initializeSdk:internalConfigurations andAdServerWrapper:[[AMODFPAdServerWrapper alloc] init] andBlock:^(NSError *error) {
        if (error) {
            NSLog(@"Error initialization AppMonet SDK - %@", error);
        }
    }];
}

+ (void)initialize:(AppMonetConfigurations *)appMonetConfigurations withBlock:(void (^)(NSError *))block {
    AppMonetConfigurations *internalConfigurations = appMonetConfigurations;
    if (appMonetConfigurations == nil) {
        internalConfigurations = [AppMonetConfigurations configurationWithBlock:^(AppMonetConfigurations *builder) {
            // do nothing
        }];
    }
    [AMOSdkManager initializeSdk:internalConfigurations andAdServerWrapper:[[AMODFPAdServerWrapper alloc] init] andBlock:block];
}

+ (void)   addBids:(DFPBannerView *)adView andDfpAdRequest:(DFPRequest *)adRequest andTimeout:(NSNumber *)timeout
andDfpRequestBlock:(void (^)(DFPRequest *dfpRequest))dfpRequestBlock {
    AMLogDebug(@"AppMonet | addBids | executed");
    [self  addBids:adView andDfpAdRequest:adRequest andAppMonetAdUnitId:adView.adUnitID andTimeout:timeout
andDfpRequestBlock:dfpRequestBlock];
}

+ (void)   addBids:(DFPRequest *)adRequest andAppMonetAdUnitId:(NSString *)appMonetAdUnitId andTimeout:(NSNumber *)timeout
andDfpRequestBlock:(void (^)(DFPRequest *dfpRequest))dfpRequestBlock {
    AMOSdkManager *sdkManager = AMOSdkManager.get;
    if (sdkManager == nil) {
        dfpRequestBlock(adRequest);
        return;
    }
    [sdkManager addBids:adRequest andAppMonetAdUnitId:appMonetAdUnitId andTimeout:timeout andDfpRequestBlock:dfpRequestBlock];
}

+ (DFPRequest *)addBids:(DFPRequest *)adRequest andAppMonetAdUnitId:(NSString *)appMonetAdUnitId {
    AMOSdkManager *sdkManager = [AMOSdkManager get];
    if (sdkManager == nil) {
        return adRequest;
    }
    return [sdkManager addBids:adRequest andAppMonetAdUnitId:appMonetAdUnitId];
}

+(DFPRequest *)addBids:(DFPBannerView *)adView andDfpAdRequest:(DFPRequest *)adRequest {
    AMOSdkManager *sdkManager = [AMOSdkManager get];
    if (sdkManager == nil) {
        return adRequest;
    }
    return [sdkManager addBids:adView andDfpAdRequest: adRequest];
}

+ (void)    addBids:(DFPBannerView *)adView andDfpAdRequest:(DFPRequest *)adRequest
andAppMonetAdUnitId:(NSString *)appMonetAdUnitId andTimeout:(NSNumber *)timeout
 andDfpRequestBlock:(void (^)(DFPRequest *dfpRequest))dfpRequestBlock {
    AMOSdkManager *sdkManager = AMOSdkManager.get;
    if (sdkManager == nil) {
        dfpRequestBlock(adRequest);
        return;
    }
    [sdkManager addBids:adView andDfpAdRequest:adRequest andAppMonetAdUnitId:appMonetAdUnitId andTimeout:timeout
     andDfpRequestBlock:dfpRequestBlock];
}

+ (void)    addBids:(GADBannerView *)adView andGadRequest:(GADRequest *)adRequest
andAppMonetAdUnitId:(NSString *)appMonetAdUnitId andTimeout:(NSNumber *)timeout
 andGadRequestBlock:(void (^)(GADRequest *gadRequest))gadRequestBlock {
    AMOSdkManager *sdkManager = AMOSdkManager.get;
    if (sdkManager == nil) {
        gadRequestBlock(adRequest);
        return;
    }
    [sdkManager addBids:adView andGadAdRequest:adRequest andAppMonetAdUnitId:appMonetAdUnitId andTimeout:timeout
     andGadRequestBlock:gadRequestBlock];
}

+ (GADRequest *)addBids:(GADBannerView *)adView andGadRequest:(GADRequest *)adRequest
    andAppMonetAdUnitId:(NSString *)appMonetAdUnitId{
    AMOSdkManager *sdkManager = AMOSdkManager.get;
    if (sdkManager == nil) {
        return adRequest;
    }
    return [sdkManager addBids:adView andGadAdRequest:adRequest andAppMonetAdUnitId:appMonetAdUnitId];
}

+ (DFPRequest *)addBids:(GADBannerView *)adView andDfpRequest:(DFPRequest*)adRequest
    andAppMonetAdUnitId:(NSString *)appMonetAdUnitId{
    AMOSdkManager *sdkManager = AMOSdkManager.get;
    if (sdkManager == nil) {
        return adRequest;
    }
    return [sdkManager addBids:adView andDfpAdRequest:adRequest andAppMonetAdUnitId:appMonetAdUnitId];
}

+ (void)    addBids:(GADBannerView *)adView andDfpRequest:(DFPRequest *)adRequest
andAppMonetAdUnitId:(NSString *)appMonetAdUnitId andTimeout:(NSNumber *)timeout
 andDfpRequestBlock:(void (^)(DFPRequest *dfpRequest))dfpRequestBlock {
    AMOSdkManager *sdkManager = AMOSdkManager.get;
    if (sdkManager == nil) {
        dfpRequestBlock(adRequest);
        return;
    }
    [sdkManager addBidsGADBannerView:adView andDfpAdRequest:adRequest andAppMonetAdUnitId:appMonetAdUnitId andTimeout:timeout
                  andDfpRequestBlock:dfpRequestBlock];
}

+ (void)addInterstitialBids:(DFPInterstitial *)interstitial andDfpAdRequest:(DFPRequest *)ad_request
                 andTimeout:(NSNumber *)timeout withBlock:(void (^)(DFPRequest *completeRequest))request_block {
    AMOSdkManager *sdkManager = AMOSdkManager.get;
    if (sdkManager == nil) {
        request_block(ad_request);
        return;
    }

    // same as other method, but the ad unit ID should just be the one on
    // the interstitial..
    [sdkManager addBids:interstitial withRequest:ad_request
    andAppMonetAdUnitId:interstitial.adUnitID andTimeout:timeout andDfpRequestBlock:request_block];
}

+ (void)preload:(NSArray<NSString *> *)adUnitIDs {
    AMOSdkManager *manager = AMOSdkManager.get;
    if (manager == nil) {
        return;
    }

    [manager preFetchBids:adUnitIDs];
}

+ (void)addInterstitialBids:(DFPInterstitial *)interstitial andAppMonetAdUnitId:(NSString *)appmonet_ad_unit_id
            andDfpAdRequest:(DFPRequest *)ad_request andTimeout:(NSNumber *)timeout withBlock:(void (^)(
        DFPRequest *completeRequest))request_block {
    AMOSdkManager *sdkManager = AMOSdkManager.get;
    if (sdkManager == nil) {
        request_block(ad_request);
        return;
    }

    [sdkManager addBids:interstitial withRequest:ad_request
    andAppMonetAdUnitId:appmonet_ad_unit_id andTimeout:timeout andDfpRequestBlock:request_block];
}

+(void)addInterstitialBids:(GADInterstitial *)interstitial andAdRequest:(GADRequest *)adRequest andTimeout:(NSNumber *)timeout withBlock:(void (^)(GADRequest *))requestBlock {
    AMOSdkManager *sdkManager = AMOSdkManager.get;
       if (sdkManager == nil) {
           requestBlock(adRequest);
           return;
       }
    [sdkManager addBidsGADInterstitial:interstitial withRequest:adRequest
                   andAppMonetAdUnitId:interstitial.adUnitID
                            andTimeout:timeout andRequestBBlock:requestBlock];
}

+ (void)testMode {
    AMOSdkManager *manager = [AMOSdkManager get];
    if (manager == nil) {
        [AMOSdkManager testModeEnabled];
        return;
    }
    [manager testMode];
}

+ (void)enableVerboseLogging:(BOOL)verboseLogging {
    [AMOSdkManager enableVerboseLogging:verboseLogging];
}

+ (void)clearAdUnit:(NSString *)appMonetAdUnitId {
    AMOSdkManager *manager = AMOSdkManager.get;
    if (manager == nil) {
        return;
    }

    [manager removeForAdUnit:appMonetAdUnitId];
}


@end

