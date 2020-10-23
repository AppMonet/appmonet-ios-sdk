//
// Created by Jose Portocarrero on 10/26/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppMonetConfigurations.h"

@class DFPRequest;
@class DFPBannerView;
@class GADRequest;
@class GADBannerView;
@class DFPInterstitial;
@class GADInterstitial;
/**
 * The {@code AppMonet} class contains static methods that are entry points to the AppMonet library.
 * All interactions will happen through this class.
 */
@interface AppMonet : NSObject

/**
 * This method initializes the AppMonet library and all its internal components.
 *
 * <p/>
 * This must be called before your application can use the AppMonet library.
 * This will soon be deprecated. Refer to initialize instead.
 * </>
 *
 * @param appMonetConfigurations The application configurations needed to initialize the sdk.
 */
+ (void)init:(AppMonetConfigurations *)appMonetConfigurations;

+ (void)init:(AppMonetConfigurations *)appMonetConfigurations withBlock:(void (^)(NSError *))block;

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

+ (void)initialize:(AppMonetConfigurations *)appMonetConfigurations withBlock:(void (^)(NSError *))block;

/**
 * This method allows you to get back a {@code DFPRequest} instance that has bids attached to it.
 * Bids will only get attached if they associated with the view's ad unit id, If no bids are locally cached it will try
 * to get some within the timeout period provided. IF no bids return  you will get the original {@code DFPRequest} you
 * provided.
 * <p/>
 *
 * @param adView  The {@link DFPBannerView} instance that will load the {@link DFPRequest}.
 * @param adRequest  The {@link DFPRequest} request instance for the give adView.
 * @param timeout The wait time in milliseconds for a bid response.
 * @param dfpRequestBlock The block to receive the adRequest with bids attached to it.
 */
+ (void)   addBids:(DFPBannerView *)adView andDfpAdRequest:(DFPRequest *)adRequest andTimeout:(NSNumber *)timeout
andDfpRequestBlock:(void (^)(DFPRequest *dfpRequest))dfpRequestBlock;

/**
 * This method allows you to get back a {@code DFPRequest} instance that has bids attached to it.
 * Bids will only get attached if they associated with the view's ad unit id, If no bids are locally cached it will try
 * to get some within the timeout period provided. IF no bids return  you will get the original {@code DFPRequest} you
 * provided.
 * <p/>
 * The appMonetAdUnitId acts as an alias to a particular adUnitId which as to be configured on the AppMonet Dashboard.
 *
 * @param adView  The {@link DFPBannerView} instance that will load the {@link DFPRequest}.
 * @param adRequest  The {@link DFPRequest} request instance for the give adView.
 * @param appMonetAdUnitId The alias unit id to be set to the {@link DFPBannerView} instance.
 *                         This ad unit id is configured on the AppMonet Dashboard.
 * @param timeout The wait time in milliseconds for a bid response.
 * @param dfpRequestBlock The block to receive the adRequest with bids attached to it.
 */
+ (void)    addBids:(DFPBannerView *)adView andDfpAdRequest:(DFPRequest *)adRequest
andAppMonetAdUnitId:(NSString *)appMonetAdUnitId andTimeout:(NSNumber *)timeout
 andDfpRequestBlock:(void (^)(DFPRequest *dfpRequest))dfpRequestBlock;

/**
 * This method allows you to get back a {@code DFPRequest} instance that has bids attached to it.
 * Bids will only get attached if they associated with the view's ad unit id, and are locally cached. IF bids are not
 * cached, you will get the original {@code DFPRequest} you provided.
 *
 * @param adView The {@code DFPBannerView} where the ad will show.
 * @param adRequest The original DFPRequest created by the developer.
 * @return {@code DFPRequest} instance with bids attached to it.
 */
+ (DFPRequest *)addBids:(DFPBannerView *)adView andDfpAdRequest:(DFPRequest *)adRequest;

/**
 * This method allows you to get back a {@code DFPRequest} instance that has bids attached to it.
 * Bids will only get attached if they associated with the view's ad unit id, If no bids are locally cached it will try
 * to get some within the timeout period provided. IF no bids return  you will get the original {@code DFPRequest} you
 * provided.
 * <p/>
 *
 * The appMonetAdUnitId acts as an alias to a particular adUnitId which as to be configured on the AppMonet Dashboard.
 *
 * @param adRequest  The {@link DFPRequest} request instance for the give adView.
 * @param appMonetAdUnitId
 * @param timeout The wait time in milliseconds for a bid response.
 * @param dfpRequestBlock The block to receive the adRequest with bids attached to it.
 */
+ (void)   addBids:(DFPRequest *)adRequest andAppMonetAdUnitId:(NSString *)appMonetAdUnitId andTimeout:(NSNumber *)timeout
andDfpRequestBlock:(void (^)(DFPRequest *dfpRequest))dfpRequestBlock;

/**
 * This method allows you to get back a {@code DFPRequest} instance that has bids attached to it.
 * Bids will only get attached if they associated with the view's ad unit id, and are locally cached. IF bids are not
 * cached, you will get the original {@code DFPRequest} you provided.
 *
 * @param adRequest The original {@code DFPRequest} created by the developer.
 * @param appMonetAdUnitId The alias unit id to be set to the {@link DFPBannerView} instance.
 *                         This ad unit id is configured on the AppMonet Dashboard.
 * @return {@code DFPRequest} instance with bids attached to it.
 */
+ (DFPRequest *)addBids:(DFPRequest *)adRequest andAppMonetAdUnitId:(NSString *)appMonetAdUnitId;

/**
 * This method allows you to get back a {@code GADRequest} instance that has bids attached to it.
 * Bids will only get attached if they associated with the view's ad unit id, If no bids are locally cached it will try
 * to get some within the timeout period provided. IF no bids return  you will get the original {@code GADRequest} you
 * provided.
 *
 * @param adView The {@code GADBannerView} where the ad will show.
 * @param adRequest The original {@code GADRequest} created by the developer.
 * @param appMonetAdUnitId
 * @param timeout The wait time in milliseconds for a bid response.
 * @param gadRequestBlock The block to receive the adRequest with bids attached to it.
 */
+ (void)    addBids:(GADBannerView *)adView andGadRequest:(GADRequest *)adRequest
andAppMonetAdUnitId:(NSString *)appMonetAdUnitId andTimeout:(NSNumber *)timeout
 andGadRequestBlock:(void (^)(GADRequest *gadRequest))gadRequestBlock;

/**
 * This method allows you to get back a {@code GADRequest} instance that has bids attached to it.
 * Bids will only get attached if they associated with the view's ad unit id, and are locally cached. IF bids are not
 * cached, you will get the original {@code GADRequest} you provided.
 *
 * @param adView The {@code GADBannerView} where the ad will show.
 * @param adRequest The original {@code GADRequest} created by the developer.
 * @param appMonetAdUnitId
 * @return {@code GADRequest} instance with bids attached to it.
 */
+ (GADRequest *)addBids:(GADBannerView *)adView andGadRequest:(GADRequest *)adRequest
    andAppMonetAdUnitId:(NSString *)appMonetAdUnitId;

/**
 * This method allows you to get back a {@code DFPRequest} instance that has bids attached to it.
 * Bids will only get attached if they associated with the view's ad unit id, If no bids are locally cached it will try
 * to get some within the timeout period provided. IF no bids return  you will get the original {@code DFPRequest} you
 * provided.
 *
 * @param adView The {@code GADBannerView} where the ad will show.
 * @param adRequest The original DFPRequest created by the developer.
 * @param appMonetAdUnitId
 * @param timeout The wait time in milliseconds for a bid response.
 * @param dfpRequestBlock The block to receive the adRequest with bids attached to it.
 */
+ (void)    addBids:(GADBannerView *)adView andDfpRequest:(DFPRequest *)adRequest
andAppMonetAdUnitId:(NSString *)appMonetAdUnitId andTimeout:(NSNumber *)timeout
 andDfpRequestBlock:(void (^)(DFPRequest *dfpRequest))dfpRequestBlock;

/**
 * This method allows you to get back a {@code DFPRequest} instance that has bids attached to it.
 * Bids will only get attached if they associated with the view's ad unit id, and are locally cached. IF bids are not
 * cached, you will get the original {@code DFPRequest} you provided.
 *
 * @param adView The {@code GADBannerView} where the ad will show.
 * @param adRequest The original {@code DFPRequest} created by the developer.
 * @param appMonetAdUnitId
 * @return {@code DFPRequest} instance with bids attached to it.
 */
+ (DFPRequest *)addBids:(GADBannerView *)adView andDfpRequest:(DFPRequest *)adRequest
    andAppMonetAdUnitId:(NSString *)appMonetAdUnitId;

/**
 * Request bids for an interstitial
 * @param interstitial the DFP interstitial instance
 * @param adRequest the original DFPRequest
 * @param timeout how long (ms) to wait for a bid
 * @param requestBlock receive the request with data for bids
 */
+ (void)addInterstitialBids:(DFPInterstitial *)interstitial
            andDfpAdRequest:(DFPRequest *)adRequest
                 andTimeout:(NSNumber *)timeout
                  withBlock:(void (^)(DFPRequest *completeRequest))requestBlock;

/**
 * Request bids for an interstitial, using the given ad unit code instead
 * of the adUnitID on the interstitial. E.g. the "code" will match the code in
 * your AppMonet dashboard
 * @param interstitial a DFP interstitial instnace
 * @param appmonetAdUnitID the code in your appmonet dashboard
 * @param adRequest the current DFP request
 * @param timeout in ms; how long to wait for a bid
 * @param requestBlock receive the modified request
 */
+ (void)addInterstitialBids:(DFPInterstitial *)interstitial
        andAppMonetAdUnitId:(NSString *)appmonetAdUnitID
            andDfpAdRequest:(DFPRequest *)adRequest
                 andTimeout:(NSNumber *)timeout
                  withBlock:(void (^)(DFPRequest *completeRequest))requestBlock;

/**
* Request bids for an GADInterstitial using a provided GADRequest.
* @param interstitial a GAD interstitial instance
* @param adRequest the current DFP request
* @param timeout in ms; how long to wait for a bid
* @param requestBlock receive the modified request
*/
+(void)addInterstitialBids:(GADInterstitial *)interstitial
              andAdRequest:(GADRequest *)adRequest
                andTimeout:(NSNumber *)timeout
                 withBlock:(void (^)(GADRequest *))requestBlock;

/**
 * This method allows the SDK to get test demand that always fills. Use it only during development.
 */
+ (void) testMode;

/**
 * This method allows you to enable or disable verbose logging coming from the AppMonet library.
 *
 * @param verboseLogging This boolean indicates if verbose logging should be activated.
 */
+ (void)enableVerboseLogging:(BOOL)verboseLogging;


/**
 * Prefetch bids for a given ad unit
 */
+ (void)preload:(NSArray<NSString *> *)adUnitIDs;

/**
 * Remove all references to a given ad unit.
 *
 * @param adUnitID - this would be DFPBannerView.adUnitID, or the appMonetAdUnitID alias (if you supplied an appMonetAdUnitID in `addBids`)
 */
+ (void)clearAdUnit:(NSString *)adUnitID;

@end



