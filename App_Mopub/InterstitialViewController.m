//
//  InterstitialViewController.m
//  App_Mopub
//
//  Created by Jose Portocarrero on 3/27/18.
//  Copyright © 2018 AppMonet. All rights reserved.
//

#import "InterstitialViewController.h"
#import <MoPub/MPInterstitialAdController.h>
#import <AppMonet_Mopub/AppMonet.h>

@interface InterstitialViewController () <MPInterstitialAdControllerDelegate>
@property(nonatomic) MPInterstitialAdController *interstitial;

@end

@implementation InterstitialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blueColor];
    _interstitial = [MPInterstitialAdController interstitialAdControllerForAdUnitId:@"a49430ee57ee4401a9eda6098726ce54"];
    _interstitial.delegate = self;
    [AppMonet addInterstitialBids:_interstitial andTimeout:@(4000) :^{
        [_interstitial loadAd];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)interstitialDidLoadAd:(MPInterstitialAdController *)interstitial {
    NSLog(@"INTERSTITIAL");

    NSLog(@"interstitialDidLoadAd");
    [interstitial showFromViewController:self];

}


- (void)interstitialDidFailToLoadAd:(MPInterstitialAdController *)interstitial {
    NSLog(@"INTERSTITIAL");

    NSLog(@"interstitialDidFailToLoadAd");
}


- (void)interstitialWillAppear:(MPInterstitialAdController *)interstitial {
    NSLog(@"INTERSTITIAL");

    NSLog(@"interstitialWillAppear");
}


- (void)interstitialDidAppear:(MPInterstitialAdController *)interstitial {
    NSLog(@"INTERSTITIAL");

    NSLog(@"interstitialDidAppear");
}


- (void)interstitialWillDisappear:(MPInterstitialAdController *)interstitial {
    NSLog(@"INTERSTITIAL");

    NSLog(@"interstitialWillDisappear");
}


- (void)interstitialDidDisappear:(MPInterstitialAdController *)interstitial {
    NSLog(@"INTERSTITIAL");

    NSLog(@"interstitialDidDisappear");
}


- (void)interstitialDidExpire:(MPInterstitialAdController *)interstitial {
    NSLog(@"INTERSTITIAL");

    NSLog(@"interstitialDidExpire");
}


- (void)interstitialDidReceiveTapEvent:(MPInterstitialAdController *)interstitial {
    NSLog(@"INTERSTITIAL");

    NSLog(@"interstitialDidReceiveTapEvent");
}

- (void)dealloc {
    self.interstitial.delegate = nil;
}


@end
