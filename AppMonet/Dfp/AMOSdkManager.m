//
// Created by Jose Portocarrero on 10/26/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMOAuctionWebView.h"
#import "AMOSdkManager.h"
#import "AppMonetConfigurations.h"
#import "AMODfpAdView.h"
#import "AMOAppMonetBidder.h"
#import "AMODfpAdRequest.h"
#import "AMOConstants.h"
#import "AMOAddBidsManager.h"
#import "AMOGADRequest.h"
@import GoogleMobileAds;

@interface AMOSdkManager ()
@property(nonatomic, strong) NSString *realDfpLabel;
@end

@implementation AMOSdkManager {
    NSUInteger _dfpLabelUseCount;
}
static AMOSdkManager *_instance;

- (id)initWithApplicationId:(AppMonetConfigurations *)appMonetConfigurations andAdServerWrapper:(id <AMOAdServerWrapper>)adServerWrapper andBlock:(InitializationBlock)block {
    self = [super initWithApplicationId:appMonetConfigurations andAdServerWrapper:adServerWrapper andBlock:block];
    return self;
}

+ (void)initializeSdk:(AppMonetConfigurations *)configurations
   andAdServerWrapper:(id <AMOAdServerWrapper>)adServerWrapper andBlock:(InitializationBlock)block {
    @synchronized (self) {
        if (_instance) {
            AMLogWarn(@"Sdk has already been initialized. No need to initialize it again.");
            return;
        }
        _instance = [[self alloc] initWithApplicationId:configurations andAdServerWrapper:adServerWrapper andBlock:block];
    }
}

+ (AMOSdkManager *)get {
    @synchronized (self) {
        return _instance;
    }
}

- (NSString *)currentLineItemLabel {
    if (_dfpLabelUseCount > 10) {
        return self.realDfpLabel;
    }
    return nil;
}

#pragma mark - AddBids with BannerView methods -

- (void)    addBids:(DFPBannerView *)dfpBannerView andDfpAdRequest:(DFPRequest *)adRequest
andAppMonetAdUnitId:(NSString *)appMonetAdUnitId andTimeout:(NSNumber *)timeout
 andDfpRequestBlock:(void (^)(DFPRequest *dfpRequest))dfpRequestBlock {
    self.isPublisherAdView = YES;
    __weak typeof(self) weakSelf = self;
    [self.addBidsManager onReady:timeout withBlock:^(NSNumber *remainingTime, BOOL timedOut) {
        typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            if (timedOut) {
                [strongSelf trackTimeoutEvent:appMonetAdUnitId withTimeout:timeout];
                dfpRequestBlock(adRequest);
                return;
            }
            AMODfpAdView *dfpAdView = [[AMODfpAdView alloc] initWithDfpBannerView:dfpBannerView];
            DFPRequest *__adRequest = adRequest;
            AMODfpAdRequest *__dfpAdRequest = [[AMODfpAdRequest alloc] initWithDfpRequest:__adRequest];
            [dfpAdView setAdUnitId:appMonetAdUnitId];
            [strongSelf bidderAddBids:__dfpAdRequest andTimeout:remainingTime andDfpAdView:dfpAdView
                         andAdRequest:adRequest andBlock:dfpRequestBlock];
        } else {
            dfpRequestBlock(adRequest);
        }
    }];

}

- (DFPRequest *)addBids:(DFPBannerView *)adView andDfpAdRequest:(DFPRequest *)adRequest {
    self.isPublisherAdView = YES;
    AMODfpAdView *dfpAdView = [[AMODfpAdView alloc] initWithDfpBannerView:adView];
    return [self getDFPSyncRequest:adRequest withDFPAdView:dfpAdView];
}

#pragma mark - AddBids with DFPRequest methods -

- (void)addBids:(DFPRequest *)adRequest andAppMonetAdUnitId:(NSString *)appMonetAdUnitId
     andTimeout:(NSNumber *)timeout andDfpRequestBlock:(void (^)(DFPRequest *dfpRequest))dfpRequestBlock {
    __weak typeof(self) weakSelf = self;
    self.isPublisherAdView = YES;
    [self.addBidsManager onReady:timeout withBlock:^(NSNumber *remainingTime, BOOL timedOut) {
        typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            if (timedOut) {
                [strongSelf trackTimeoutEvent:appMonetAdUnitId withTimeout:timeout];
                dfpRequestBlock(adRequest);
                return;
            }
            AMODfpAdView *dfpAdView = [[AMODfpAdView alloc] initWithAdUnitId:appMonetAdUnitId];
            DFPRequest *__adRequest = adRequest;
            AMODfpAdRequest *__dfpAdRequest = [[AMODfpAdRequest alloc] initWithDfpRequest:__adRequest];
            [dfpAdView setAdUnitId:appMonetAdUnitId];
            [strongSelf bidderAddBids:__dfpAdRequest andTimeout:remainingTime andDfpAdView:dfpAdView
                         andAdRequest:adRequest andBlock:dfpRequestBlock];
        } else {
            dfpRequestBlock(adRequest);
        }
    }];

}

- (DFPRequest *)addBids:(DFPRequest *)adRequest andAppMonetAdUnitId:(NSString *)appMonetAdUnitId {
    self.isPublisherAdView = YES;
    AMODfpAdView *dfpAdView = [[AMODfpAdView alloc] initWithAdUnitId:appMonetAdUnitId];
    [dfpAdView setAdUnitId:appMonetAdUnitId];
    return [self getDFPSyncRequest:adRequest withDFPAdView:dfpAdView];
}

#pragma mark - AddBids with GADBanner and DFPRequest methods -

- (void)addBidsGADBannerView:(GADBannerView *)gadBannerView andDfpAdRequest:(DFPRequest *)adRequest
         andAppMonetAdUnitId:(NSString *)appMonetAdUnitId andTimeout:(NSNumber *)timeout
          andDfpRequestBlock:(void (^)(DFPRequest *dfpRequest))dfpRequestBlock {
    __weak typeof(self) weakSelf = self;
    self.isPublisherAdView = YES;
    [self.addBidsManager onReady:timeout withBlock:^(NSNumber *remainingTime, BOOL timedOut) {
        typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            if (timedOut) {
                [strongSelf trackTimeoutEvent:appMonetAdUnitId withTimeout:timeout];
                dfpRequestBlock(adRequest);
                return;
            }
            AMODfpAdView *dfpAdView = [[AMODfpAdView alloc] initWithGadBannerView:gadBannerView];
            DFPRequest *__adRequest = adRequest;
            AMODfpAdRequest *__dfpAdRequest = [[AMODfpAdRequest alloc] initWithDfpRequest:__adRequest];
            [dfpAdView setAdUnitId:appMonetAdUnitId];
            [strongSelf bidderAddBids:__dfpAdRequest andTimeout:remainingTime andDfpAdView:dfpAdView
                         andAdRequest:adRequest andBlock:dfpRequestBlock];
        }
    }];

}

- (DFPRequest *)addBids:(GADBannerView *)gadBannerView andDfpAdRequest:(DFPRequest *)adRequest
    andAppMonetAdUnitId:(NSString *)appMonetAdUnitId {
    self.isPublisherAdView = YES;
    AMODfpAdView *dfpAdView = [[AMODfpAdView alloc] initWithGadBannerView:gadBannerView];
    [dfpAdView setAdUnitId:appMonetAdUnitId];
    DFPRequest *__adRequest = (adRequest == nil) ? [DFPRequest request] : adRequest;
    AMODfpAdRequest *__dfpAdRequest = [[AMODfpAdRequest alloc] initWithDfpRequest:__adRequest];
    AMODfpAdRequest *dfpAdRequest = (AMODfpAdRequest *) [self.appMonetBidder addBids:dfpAdView andAdServerAdRequest:__dfpAdRequest];
    return (dfpAdRequest != nil) ? [dfpAdRequest getDfpRequest] : __adRequest;
}

#pragma mark - AddBids with GADBanner and GADRequest methods -

- (void)    addBids:(GADBannerView *)gadBannerView andGadAdRequest:(GADRequest *)adRequest
andAppMonetAdUnitId:(NSString *)appMonetAdUnitId andTimeout:(NSNumber *)timeout
 andGadRequestBlock:(void (^)(GADRequest *gadRequest))gadRequestBlock {
    __weak typeof(self) weakSelf = self;
    self.isPublisherAdView = NO;
    [self.addBidsManager onReady:timeout withBlock:^(NSNumber *remainingTime, BOOL timedOut) {
        typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            if (timedOut) {
                [strongSelf trackTimeoutEvent:appMonetAdUnitId withTimeout:timeout];
                gadRequestBlock(adRequest);
                return;
            }
            AMODfpAdView *dfpAdView = [[AMODfpAdView alloc] initWithGadBannerView:gadBannerView];
            GADRequest *__adRequest = adRequest;
            AMOGADRequest *__dfpAdRequest = [[AMOGADRequest alloc] initWithGadRequest:__adRequest];
            [dfpAdView setAdUnitId:appMonetAdUnitId];
            [strongSelf.appMonetBidder addBids:dfpAdView andAdServerAdRequest:__dfpAdRequest
                                    andTimeout:remainingTime andExecutionQueue:strongSelf.backgroundQueue
                                 andValueBlock:^(id <AMServerAdRequest> adServerAdRequest) {
                                     if (adServerAdRequest == nil) {
                                         gadRequestBlock(__adRequest);
                                         return;
                                     }
                                     gadRequestBlock(((AMOGADRequest *) adServerAdRequest).getGadRequest);
                                 }];
        } else {
            gadRequestBlock(adRequest);
        }
    }];

}

- (GADRequest *)addBids:(GADBannerView *)gadBannerView andGadAdRequest:(GADRequest *)adRequest
    andAppMonetAdUnitId:(NSString *)appMonetAdUnitId {
    self.isPublisherAdView = NO;
    AMODfpAdView *dfpAdView = [[AMODfpAdView alloc] initWithGadBannerView:gadBannerView];
    [dfpAdView setAdUnitId:appMonetAdUnitId];
    GADRequest *__adRequest = (adRequest == nil) ? [GADRequest request] : adRequest;
    AMOGADRequest *__dfpAdRequest = [[AMOGADRequest alloc] initWithGadRequest:__adRequest];
    AMOGADRequest *gadAdRequest = (AMOGADRequest *) [self.appMonetBidder
            addBids:dfpAdView andAdServerAdRequest:__dfpAdRequest];
    return (gadAdRequest != nil) ? [gadAdRequest getGadRequest] : __adRequest;
}

#pragma mark - AddBids with DFPInterstitial and DFPRequest methods -

// the same as above, but with an interstitial instead...
- (void)    addBids:(DFPInterstitial *)interstitial withRequest:(DFPRequest *)adRequest
andAppMonetAdUnitId:(NSString *)appMonetAdUnitId andTimeout:(NSNumber *)timeout
 andDfpRequestBlock:(void (^)(DFPRequest *dfpRequest))dfpRequestBlock {
    __weak typeof(self) weakSelf = self;
    self.isPublisherAdView = YES;
    [self.addBidsManager onReady:timeout withBlock:^(NSNumber *remainingTime, BOOL timedOut) {
        typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            if (timedOut) {
                [strongSelf trackTimeoutEvent:appMonetAdUnitId withTimeout:timeout];
                dfpRequestBlock(adRequest);
                return;
            }
            AMODfpAdView *dfpAdView = [[AMODfpAdView alloc] initWithDfpInterstitial:interstitial];
            DFPRequest *__adRequest = adRequest;
            AMODfpAdRequest *__dfpAdRequest = [[AMODfpAdRequest alloc] initWithDfpRequest:__adRequest];
            // set this, so we can use alias
            [dfpAdView setAdUnitId:appMonetAdUnitId];
            [self bidderAddBids:__dfpAdRequest andTimeout:remainingTime andDfpAdView:dfpAdView
                   andAdRequest:adRequest andBlock:dfpRequestBlock];
        } else {
            dfpRequestBlock(adRequest);
        }
    }];
}

- (void)addBidsGADInterstitial:(GADInterstitial *)interstitial withRequest:(GADRequest *)adRequest
           andAppMonetAdUnitId:(NSString *)appMonetAdUnitId andTimeout:(NSNumber *)timeout
              andRequestBBlock:(void (^)(GADRequest *request))requestBlock {
    __weak typeof(self) weakSelf = self;
    self.isPublisherAdView = NO;
    [self.addBidsManager onReady:timeout withBlock:^(NSNumber *remainingTime, BOOL timedOut) {
        typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            if (timedOut) {
                [strongSelf trackTimeoutEvent:appMonetAdUnitId withTimeout:timeout];
                requestBlock(adRequest);
                return;
            }
            AMODfpAdView *dfpAdView = [[AMODfpAdView alloc] initWithGADInterstitial:interstitial];
            GADRequest *__adRequest = adRequest;
            AMOGADRequest *__dfpAdRequest = [[AMOGADRequest alloc] initWithGadRequest:__adRequest];
            [dfpAdView setAdUnitId:appMonetAdUnitId];
            [strongSelf.appMonetBidder addBids:dfpAdView andAdServerAdRequest:__dfpAdRequest
                                    andTimeout:remainingTime andExecutionQueue:strongSelf.backgroundQueue
                                 andValueBlock:^(id <AMServerAdRequest> adServerAdRequest) {
                                     if (adServerAdRequest == nil) {
                                         requestBlock(__adRequest);
                                         return;
                                     }
                                     NSLog(@"addBis block returned");
                                     NSLog(@"%@", [((AMOGADRequest *) adServerAdRequest).getGadRequest.keywords description]);
                                     requestBlock(((AMOGADRequest *) adServerAdRequest).getGadRequest);
                                 }];
        } else {
            requestBlock(adRequest);
        }
    }];
}

#pragma mark - Private methods -

- (void)removeForAdUnit:(NSString *)appMonetAdUnitId {
    [self.appMonetBidder removeAdUnit:appMonetAdUnitId];
}

- (DFPRequest *)getDFPSyncRequest:(DFPRequest *)adRequest withDFPAdView:(AMODfpAdView *)dfpAdView {
    DFPRequest *__adRequest = (adRequest == nil) ? [DFPRequest request] : adRequest;
    AMODfpAdRequest *__dfpAdRequest = [[AMODfpAdRequest alloc] initWithDfpRequest:__adRequest];
    AMODfpAdRequest *dfpAdRequest = (AMODfpAdRequest *) [self.appMonetBidder
            addBids:dfpAdView andAdServerAdRequest:__dfpAdRequest];
    return (dfpAdRequest != nil) ? [dfpAdRequest getDfpRequest] : __adRequest;
}

- (void)bidderAddBids:(AMODfpAdRequest *)dfpAdRequest andTimeout:(NSNumber *)timeout andDfpAdView:(AMODfpAdView *)dfpAdView
         andAdRequest:(DFPRequest *)adRequest andBlock:(void (^)(DFPRequest *dfpRequest))dfpRequestBlock {
    [self.appMonetBidder addBids:dfpAdView andAdServerAdRequest:dfpAdRequest
                      andTimeout:timeout andExecutionQueue:self.backgroundQueue
                   andValueBlock:^(id <AMServerAdRequest> adServerAdRequest) {
                       if (adServerAdRequest == nil) {
                           dfpRequestBlock(adRequest);
                           return;
                       }
                       dfpRequestBlock(((AMODfpAdRequest *) adServerAdRequest).getDfpRequest);
                   }];
}

@end
