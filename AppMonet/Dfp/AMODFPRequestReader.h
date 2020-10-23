//
// Created by Nick Jacob on 2019-04-16.
// Copyright (c) 2019 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GoogleMobileAds/GADAdSize.h"
#import "AMOAdView.h"

@class GADCustomEventRequest;
@class AMOBidResponse;
@class AMOAdSize;

// this is really just a utility class
// for working with the DFP requests
@interface AMODFPRequestReader : NSObject

+ (NSString *)extractAdUnitID:(GADCustomEventRequest *)request andServerLabel:(NSString *)serverLabel
              withServerValue:(NSString *)serverValue andAdSize:(AMOAdSize *)adSize;

+ (NSNumber *)getCpm:(NSString *)serverParameter;

/**
 * Get the bid(s) attached via header bidding
 * @param request the request made
 * @param size our size (bids are segmented by size)
 * @param serverLabel  server label. Can be used for PMP/per-bidder.. although nobody does
 * @param adUnitID the ad unit ID
 * @return
 */
+ (AMOBidResponse *)bidResponseFromHeaderBidding:(GADCustomEventRequest *)request
                                  andServerLabel:(NSString *)serverLabel
                                     andAdUnitID:(NSString *)adUnitID;

/**
 * Get a potential bid based on mediation logic (e.g. when no bids are attached)
 * @param request  the incoming request
 * @param adUnitID our ad unit
 * @return a bid (or nil)
 */
+ (AMOBidResponse *)bidResponseFromMediation:(GADCustomEventRequest *)request
                                   andAdSize:(AMOAdSize *)adSize
                                 andAdUnitID:(NSString *)adUnitID
                                 andCpmFloor:(NSNumber *)cpm
                                   andAdType:(AMOAdType)adType;

/**
 * Queue the next bid based on our preferences & if there is demand.
 * @param bid the current bid (to get prefs)
 * @param adUnitID the adunit we're currently working on
 * @param request our request
 */
+ (void)queueNextDemand:(AMOBidResponse *)bid
               adUnitID:(NSString *)adUnitID
             andRequest:(GADCustomEventRequest *)request;
@end
