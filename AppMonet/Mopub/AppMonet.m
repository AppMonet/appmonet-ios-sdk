//
//  AppMonet.m
//  AppMonet_Mopub
//
//  Created by Jose Portocarrero on 12/5/17.
//  Copyright © 2017 AppMonet. All rights reserved.
//

#import "AppMonet.h"
#import "AMOSdkManager.h"
#import "AMOMopubAdServerWrapper.h"
#import "MPNativeAdRequest.h"
#import <MoPub/MPAdView.h>
#import <MPInterstitialAdController.h>

@implementation AppMonet

+ (void)init:(AppMonetConfigurations *)appMonetConfigurations {
    [AppMonet initialize:appMonetConfigurations];
}

+ (void)initialize:(AppMonetConfigurations *)appMonetConfigurations {
    AppMonetConfigurations *internalConfigurations = appMonetConfigurations;
    if (appMonetConfigurations == nil) {
        internalConfigurations = [AppMonetConfigurations configurationWithBlock:^(AppMonetConfigurations *builder) {
        }];
    }

    [AMOSdkManager initializeSdk:internalConfigurations andAdServerWrapper:[[AMOMopubAdServerWrapper alloc] init] andBlock:^(NSError *error) {
        if (error) {
            NSLog(@"Error initialization AppMonet SDK - %@", error);
        }
    }];
}

+ (void)addBids:(MPAdView *)adView andTimeout:(NSNumber *)timeout :(void (^)(void))onReadyBlock {
    AMOSdkManager *manager = [AMOSdkManager get];
    if (manager == nil) {
        onReadyBlock();
        return;
    }
    [manager addBids:adView andAdUnitId:[adView adUnitId] andTimeout:timeout andOnReady:onReadyBlock];
}

+ (MPAdView *)addBids:(MPAdView *)adView {
    AMOSdkManager *manager = [AMOSdkManager get];
    if (manager == nil) {
        return adView;
    }
    return [manager addBids:adView andAdUnitId:[adView adUnitId]];
}
+ (void)addNativeBids:(MPNativeAdRequest *)adRequest andAdUnitId:(NSString *)adUnitId andTimeout:(NSNumber *)timeout :(void (^)(void))onReadyBlock {
    AMOSdkManager *manager = [AMOSdkManager get];
    if (manager == nil) {
        onReadyBlock();
        return;
    }
    [manager addNativeBids:adRequest andAdUnitId:adUnitId andTimeout:timeout :onReadyBlock];
}

+ (void)addInterstitialBids:(MPInterstitialAdController *)interstitial andTimeout:(NSNumber *)timeout :(void (^)(void))onReadyBlock {
    AMOSdkManager *manager = [AMOSdkManager get];
    if (manager == nil) {
        onReadyBlock();
        return;
    }
    [manager addInterstitialBids:interstitial andAdUnitId:[interstitial adUnitId] andTimeout:timeout :onReadyBlock];
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
@end
