//
//  AppMonet.h
//  AppMonet_Mopub
//
//  Created by Jose Portocarrero on 12/5/17.
//  Copyright © 2017 AppMonet. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "AppMonetConfigurations.h"

@class MPAdView;
@class AMOSdkManager;
#import "AMNativeAdRenderer.h"
@class MPNativeAdRequest;
@class MPInterstitialAdController;

@interface AppMonet : NSObject

/**
 * This method initializes the AppMonet library and all its internal components.
 *
 * <p/>
 * This must be called before your application can use the AppMonet library.
 * </>
 *
 * @param appMonetConfigurations The application configurations needed to initialize the sdk.
 */
+ (void)init:(AppMonetConfigurations *)appMonetConfigurations __attribute((deprecated("Use the initialize method instead.")));

/**
 * This method initializes the AppMonet library and all its internal components.
 *
 * <p/>
 * This must be called before your application can use the AppMonet library.
 * </>
 *
 * @param appMonetConfigurations The application configurations needed to initialize the sdk.
 */
+ (void)initialize:(AppMonetConfigurations *)appMonetConfigurations;

/**
 * This method allows you to attach bids to {@code MPAdView} instance.
 * Bids will only get attached if they associated with the view's ad unit id, If no bids are locally cached it will try
 * to get some within the timeout period provided. If no bids return you will not have anything attached on {@code MPAdView}.
 * <p/>
 *
 * @param adView The {@code MPAdView} you are trying to load an ad on.
 * @param timeout  The wait time in milliseconds for a bid response.
 * @param onReadyBlock The block notifying that addBids completed.
 */
+ (void)addBids:(MPAdView *)adView andTimeout:(NSNumber *)timeout :(void (^)(void))onReadyBlock;

/**
 * This method allows you to get back a modified {@code MPAdView} instance that has bids attached to it.
 * Bids will only get attached if they associated with the view's ad unit id, and are locally cached. IF bids are not
 * cached, nothing will be attached to {@code MPAdView}.
 * @param adView  {@code MPAdView} to attach bid to.
 * @return {@code MPAdView} with bids attached.
 */
+ (MPAdView *)addBids:(MPAdView *)adView;

/**
 * This method allows you to attach bids to {@code MPInterstitialAdController} instance.
 * Bids will only get attached if they associated with the view's ad unit id, If no bids are locally cached it will try
 * to get some within the timeout period provided. If no bids return you will not have anything attached on {@code MPInterstitialAdController}.
 * <p/>
 * @param interstitial The interstitial controller that will render the ad.
 * @param timeout The wait time in milliseconds for a bid response.
 * @param onReadyBlock The block notifying that addInterstitialBids completed.
 */
+ (void)addInterstitialBids:(MPInterstitialAdController *)interstitial andTimeout:(NSNumber *)timeout :(void (^)(void))onReadyBlock __attribute__((deprecated));

/**
 * This method allows you to attach bids to {@code MPNativeAdRequest} instance.
 * Bids will only get attached if they associated with the view's ad unit id, If no bids are locally cached it will try
 * to get some within the timeout period provided. If no bids return you will not have anything attached on {@code MPNativeAdRequest}.
 * <p/>
 * @param adRequest The {@code MPNativeAdRequest} object that will be used to attach bids.
 * @param adUnitId The ad unit id associated with ad the request.
 * @param timeout The wait time in milliseconds for a bid response.
 * @param onReadyBlock The block notifying that addNativeBids completed.
 */
+ (void)addNativeBids:(MPNativeAdRequest *)adRequest andAdUnitId:(NSString *)adUnitId andTimeout:(NSNumber *)timeout :(void (^)(void))onReadyBlock;

/**
 * This method allows the SDK to get test demand that always fills. Use it only during development.
 */
+ (void)testMode;

/**
 * Enables/disables verbose logging.
 * @param verboseLogging  Boolean to disable or enable verbose logging.
 */
+ (void)enableVerboseLogging:(BOOL)verboseLogging;

@end
