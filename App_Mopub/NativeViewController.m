//
//  NativeViewController.m
//  App_Mopub
//
//  Created by Jose Portocarrero on 1/3/20.
//  Copyright © 2020 AppMonet. All rights reserved.
//

#import "NativeViewController.h"
#import <MoPub/MoPub.h>
#import "AMNativeAdRenderer.h"
#import "CustomNativeAdView.h"
#import <AppMonet_Mopub/AppMonet.h>

@interface NativeViewController ()

@end

@implementation NativeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)getAd:(id)sender {

    MPStaticNativeAdRendererSettings *settings = [[MPStaticNativeAdRendererSettings alloc] init];
    settings.renderingViewClass = [CustomNativeAdView class];
    settings.viewSizeHandler = ^(CGFloat maxWidth) {
        return CGSizeMake(300, 312.0f);
    };
    MPNativeAdRendererConfiguration *config = [AMNativeAdRenderer rendererConfigurationWithRendererSettings:settings];
    MPNativeAdRequest *adRequest = [MPNativeAdRequest requestWithAdUnitIdentifier:@"46fc06141d664130857cc6af0448d4b9" rendererConfigurations:@[config]];
    MPNativeAdRequestTargeting *targeting = [MPNativeAdRequestTargeting targeting];
    adRequest.targeting = targeting;
    [AppMonet addNativeBids:adRequest andAdUnitId:@"46fc06141d664130857cc6af0448d4b9" andTimeout:@10000 :^{
        [adRequest startWithCompletionHandler:^(MPNativeAdRequest *request, MPNativeAd *response, NSError *error) {
            if (error) {
                NSLog(@"Error requesting ad%@", error.description);
            } else {
                UIView *nativeAdView = [response retrieveAdViewWithError:nil];
                nativeAdView.frame = self.view.bounds;
                [self.view addSubview:nativeAdView];
            }
        }];
    }];
}


@end
