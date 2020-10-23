//
//  ViewController.m
//  App
//
//  Created by Jose Portocarrero on 11/28/17.
//  Copyright © 2017 AppMonet. All rights reserved.
//

#import "DfpViewController.h"
#import "AppMonet_Dfp/AppMonet.h"


@interface DfpViewController () <GADAppEventDelegate, DFPBannerAdLoaderDelegate, GADInterstitialDelegate>
@property(retain, nonatomic) IBOutlet GADBannerView *adView;
@property(retain, nonatomic) IBOutlet UIButton *showInterstitialButton;
@property(strong, nonatomic) GADRequest *adRequest;
@property(nonatomic, strong) GADInterstitial *currentInterstitial;
@property(nonatomic, strong) GADAdLoader *adLoader;
@end

@implementation DfpViewController

#pragma mark - Life cycle

- (void)interstitial:(GADInterstitial *)interstitial didReceiveAppEvent:(NSString *)name withInfo:(nullable NSString *)info {
    NSLog(@"[INTERSTITIAL] Received %@ with: %@", name, info);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.adView.adSize = GADAdSizeFromCGSize(CGSizeMake(300, 250));
    self.adView.adUnitID = @"ca-app-pub-2737306441907340/6000815573";
    self.adView.backgroundColor = [UIColor blueColor];
    self.adView.rootViewController = self;
    _adRequest = [self getDfpRequest];
}

#pragma mark - Private Method

- (GADRequest *)getDfpRequest {
    GADRequest *adRequest = [GADRequest request];
    return adRequest;
}

- (GADInterstitial *)getInterstitial {
    // NOTE: put in the ad unit ID here!
    return [[GADInterstitial alloc] initWithAdUnitID:@"ca-app-pub-2737306441907340/6437791663"];
}

- (IBAction)handleShowInterstitial {
    if (self.currentInterstitial && !self.currentInterstitial.hasBeenUsed && self.currentInterstitial.isReady) {
        [self.currentInterstitial presentFromRootViewController:self];
    }
}

- (IBAction) handleFetchInterstitial {
    GADInterstitial *interstitial = [self getInterstitial];
    interstitial.delegate = self;
    GADRequest *sampleRequest = [self getDfpRequest];

    self.currentInterstitial = interstitial;

    [AppMonet addInterstitialBids:self.currentInterstitial andAdRequest:sampleRequest andTimeout:@4000 withBlock:^(GADRequest *req) {
        [interstitial loadRequest:req];
    }];

}

#pragma mark - Actions

- (IBAction)cleanView:(id)sender {
    NSLog(@"clicked clean view!");
    [AppMonet clearAdUnit:_adView.adUnitID];
}

- (IBAction)handleFetchAd:(id)sender {
    NSLog(@"fetch ad!!!");

    [AppMonet addBids:_adView andGadRequest:_adRequest andAppMonetAdUnitId:@"ca-app-pub-2737306441907340/6000815573" andTimeout:@4000 andGadRequestBlock:^(GADRequest *gadRequest) {
        [_adView loadRequest:gadRequest];
    }];
}

#pragma  mark - DFPBannerAdLoaderDelegate

- (NSArray<NSValue *> *)validBannerSizesForAdLoader:(GADAdLoader *)adLoader {

    return @[NSValueFromGADAdSize(kGADAdSizeMediumRectangle)];
}

- (void)adLoader:(GADAdLoader *)adLoader didReceiveDFPBannerView:(DFPBannerView *)bannerView {
    NSLog(@"THIS WORKED");
    bannerView.frame = CGRectMake((self.view.bounds.size.width - bannerView.adSize.size.width) / 2,
            self.view.bounds.size.height - bannerView.adSize.size.height,
            bannerView.adSize.size.width, bannerView.adSize.size.height);
    [self.view addSubview:bannerView];
}

- (void)adLoader:(GADAdLoader *)adLoader didFailToReceiveAdWithError:(GADRequestError *)error {
    NSLog(@"Error %@", error.userInfo);
}

@end
