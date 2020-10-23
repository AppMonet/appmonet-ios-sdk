//
// Created by Jose Portocarrero on 10/26/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMOBaseManager.h"

@class AppMonetConfigurations;
@class DFPRequest;
@class DFPBannerView;
@class DFPInterstitial;
@class GADRequest;
@class GADBannerView;
@class GADInterstitial;
 
@interface AMOSdkManager : AMOBaseManager
@property (nonatomic, retain) AMOAddBidsManager *addBidsManager;
@property (nonatomic) BOOL isPublisherAdView;

+ (void)initializeSdk:(AppMonetConfigurations *)configurations
   andAdServerWrapper:(id <AMOAdServerWrapper>)adServerWrapper andBlock:(InitializationBlock)block;

+ (AMOSdkManager *)get;

- (void)    addBids:(DFPBannerView *)dfpBannerView andDfpAdRequest:(DFPRequest *)adRequest
andAppMonetAdUnitId:(NSString *)appMonetAdUnitId andTimeout:(NSNumber *)timeout
 andDfpRequestBlock:(void (^)(DFPRequest *dfpRequest))dfpRequestBlock;

- (void)addBidsGADBannerView:(GADBannerView *)gadBannerView andDfpAdRequest:(DFPRequest *)adRequest
         andAppMonetAdUnitId:(NSString *)appMonetAdUnitId andTimeout:(NSNumber *)timeout
          andDfpRequestBlock:(void (^)(DFPRequest *dfpRequest))dfpRequestBlock;

- (void)    addBids:(DFPInterstitial *)interstitial withRequest:(DFPRequest *)adRequest
andAppMonetAdUnitId:(NSString *)appMonetAdUnitId andTimeout:(NSNumber *)timeout
 andDfpRequestBlock:(void (^)(DFPRequest *dfpRequest))dfpRequestBlock;

-(void)addBidsGADInterstitial:(GADInterstitial *)interstitial withRequest:(GADRequest *)adRequest
andAppMonetAdUnitId:(NSString *)appMonetAdUnitId andTimeout:(NSNumber *)timeout
             andRequestBBlock:(void (^)(GADRequest *request)) requestBlock;

- (void)    addBids:(GADBannerView *)gadBannerView andGadAdRequest:(GADRequest *)adRequest
andAppMonetAdUnitId:(NSString *)appMonetAdUnitId andTimeout:(NSNumber *)timeout
 andGadRequestBlock:(void (^)(GADRequest *gadRequest))gadRequestBlock;

- (GADRequest *)addBids:(GADBannerView *)gadBannerView andGadAdRequest:(GADRequest *)adRequest
    andAppMonetAdUnitId:(NSString *)appMonetAdUnitId;

- (DFPRequest *)addBids:(GADBannerView *)gadBannerView andDfpAdRequest:(DFPRequest *)adRequest
    andAppMonetAdUnitId:(NSString *)appMonetAdUnitId;

- (void)addBids:(DFPRequest *)adRequest andAppMonetAdUnitId:(NSString *)appMonetAdUnitId
     andTimeout:(NSNumber *)timeout andDfpRequestBlock:(void (^)(DFPRequest *dfpRequest))dfpRequestBlock;

- (DFPRequest *)addBids:(DFPRequest *)adRequest andAppMonetAdUnitId:(NSString *)appMonetAdUnitId;

- (DFPRequest *)addBids:(DFPBannerView *)adView andDfpAdRequest:(DFPRequest *)adRequest;

- (NSString *)currentLineItemLabel;

- (void)removeForAdUnit:(NSString *)appMonetAdUnitId;

@end
