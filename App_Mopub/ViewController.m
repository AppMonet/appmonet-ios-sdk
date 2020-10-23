//
//  ViewController.m
//  App_Mopub
//
//  Created by Jose Portocarrero on 12/6/17.
//  Copyright © 2017 AppMonet. All rights reserved.
//

#import "ViewController.h"
#import "MPAdView.h"
#import <AppMonet_Mopub/AppMonet.h>
#import "MoPub.h"
#import "InterstitialViewController.h"

@interface ViewController () <MPAdViewDelegate>
@property(nonatomic, strong) MPAdView *adView;
@property(nonatomic) MPAdView *adView2;

@end

@implementation ViewController


#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    BOOL isRectangle = YES;
    NSString *current = @"b03e6dccfe9e4abab02470a39c88d5dc";
    self.adView = [[MPAdView alloc] initWithAdUnitId:current
                                                size:isRectangle ? MOPUB_MEDIUM_RECT_SIZE : MOPUB_BANNER_SIZE];

    self.adView.backgroundColor = [UIColor redColor];
    [self.adView startAutomaticallyRefreshingContents];
    self.adView.delegate = self;
    if (isRectangle) {
        // TODO: convert these to the correct size stuff!
        self.adView.frame = CGRectMake((self.view.bounds.size.width - MOPUB_MEDIUM_RECT_SIZE.width) / 2,
                self.view.bounds.size.height - MOPUB_MEDIUM_RECT_SIZE.height,
                MOPUB_MEDIUM_RECT_SIZE.width, MOPUB_MEDIUM_RECT_SIZE.height);
    } else {
        self.adView.frame = CGRectMake((self.view.bounds.size.width - MOPUB_BANNER_SIZE.width) / 2,
                self.view.bounds.size.height - MOPUB_BANNER_SIZE.height,
                MOPUB_BANNER_SIZE.width, MOPUB_BANNER_SIZE.height);
    }
    [self.view addSubview:self.adView];
}

- (void)dealloc {
    self.adView.delegate = nil;
}

#pragma mark - Actions

- (IBAction)fetchAd:(id)sender {
    [AppMonet addBids:_adView andTimeout:@(6500) :^{
        [self.adView loadAd];
    }];
}

- (IBAction)interstitial:(id)sender {
    InterstitialViewController *interstitial = [[InterstitialViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:interstitial animated:YES];
}

#pragma mark - <MPAdViewDelegate>

- (UIViewController *)viewControllerForPresentingModalView {
    return self;
}

- (void)adViewDidLoadAd:(MPAdView *)view adSize:(CGSize)adSize {

}

- (void)willLeaveApplicationFromAd:(MPAdView *)view {
}

@end
