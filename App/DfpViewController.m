//
//  ViewController.m
//  App
//
//  Created by Jose Portocarrero on 11/28/17.
//  Copyright © 2017 AppMonet. All rights reserved.
//

#import "DfpViewController.h"
#import "AppMonet_Dfp/AppMonet.h"


@interface DfpViewController () <GADAppEventDelegate, DFPBannerAdLoaderDelegate>
@property(retain, nonatomic) IBOutlet DFPBannerView *adView;
@property(retain, nonatomic) IBOutlet UIButton *showInterstitialButton;
@property(nonatomic, strong) DFPInterstitial *currentInterstitial;
@end

@implementation DfpViewController
#pragma mark - Life cycle

- (void)interstitial:(GADInterstitial *)interstitial didReceiveAppEvent:(NSString *)name withInfo:(nullable NSString *)info {
    NSLog(@"[INTERSTITIAL] Received %@ with: %@", name, info);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[GADMobileAds sharedInstance] startWithCompletionHandler:nil];
    self.adView.adSize = GADAdSizeFromCGSize(CGSizeMake(300, 250));
    self.adView.adUnitID = [self getKeyFromPlist:@"bannerAdUnit"];
    self.adView.backgroundColor = [UIColor blueColor];
    self.adView.rootViewController = self;
}

#pragma mark - Private Method

- (DFPRequest *)getDfpRequest {
    DFPRequest *dfpRequest = [DFPRequest request];
    return dfpRequest;
}

- (DFPInterstitial *)getInterstitial {
    return [[DFPInterstitial alloc] initWithAdUnitID:[self getKeyFromPlist:@"interstitialAdUnit"]];
}

- (IBAction)handleShowInterstitial {
    if (self.currentInterstitial && !self.currentInterstitial.hasBeenUsed && self.currentInterstitial.isReady) {
        [self.currentInterstitial presentFromRootViewController:self];
    }
}

- (IBAction) handleFetchInterstitial {
    DFPInterstitial *interstitial = [self getInterstitial];
    interstitial.appEventDelegate = self;
    DFPRequest *sampleRequest = [self getDfpRequest];

    [AppMonet addInterstitialBids:interstitial andDfpAdRequest:sampleRequest andTimeout:@4000
                        withBlock:^(DFPRequest *completeRequest) {
                            [interstitial loadRequest:completeRequest];
                        }];

    self.currentInterstitial = interstitial;
}

#pragma mark - Actions

- (IBAction)cleanView:(id)sender {
    NSLog(@"clicked clean view!");
    [AppMonet clearAdUnit:_adView.adUnitID];
}

- (IBAction)handleFetchAd:(id)sender {
    NSLog(@"fetch ad!!!");
    [AppMonet addBids:_adView andDfpAdRequest:self.getDfpRequest
           andTimeout:@4000 andDfpRequestBlock:^(DFPRequest *request) {
                [_adView loadRequest:request];
            }];
}

#pragma  mark - DFPBannerAdLoaderDelegate

- (NSArray<NSValue *> *)validBannerSizesForAdLoader:(GADAdLoader *)adLoader {

    return @[NSValueFromGADAdSize(kGADAdSizeMediumRectangle)];
}

- (void)adLoader:(GADAdLoader *)adLoader didReceiveDFPBannerView:(DFPBannerView *)bannerView {
    bannerView.frame = CGRectMake((self.view.bounds.size.width - bannerView.adSize.size.width) / 2,
            self.view.bounds.size.height - bannerView.adSize.size.height,
            bannerView.adSize.size.width, bannerView.adSize.size.height);
    [self.view addSubview:bannerView];
}

- (void)adLoader:(GADAdLoader *)adLoader didFailToReceiveAdWithError:(GADRequestError *)error {
    NSLog(@"Error %@", error.userInfo);
}

- (NSString *) getKeyFromPlist:(NSString *)key {
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"KEYS" ofType:@"plist"];
    NSDictionary *configuration = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    NSString *value = configuration[key];
    if(value == nil){
        return @"";
    }

    return value;
}


@end
