//
//  AMOGADRequest.m
//  AppMonet
//
//  Created by Jose Portocarrero on 5/19/20.
//  Copyright © 2020 AppMonet. All rights reserved.
//

#import "AMOGADRequest.h"


#import "AMOAuctionRequest.h"
#import "AMORequestData.h"
#import "AMOConstants.h"
#import "AMOSdkManager.h"
#import "AMOUtils.h"
@import GoogleMobileAds;

@implementation AMOGADRequest {
    GADRequest *_adRequest;
}

- (instancetype)initWithGadRequest:(GADRequest *)adRequest {
    if (self=[super init]) {
        _adRequest = adRequest;
    }
    return self;
}

- (AMOAuctionRequest *)apply:(AMOAuctionRequest *)auctionRequest andAdServerAdView:(id <AMOAdServerAdView>)adView {
    if (auctionRequest.adMobExtras == nil) {
        auctionRequest.adMobExtras = [NSMutableDictionary dictionary];
    }
    if (auctionRequest.targeting == nil) {
        auctionRequest.targeting = [NSMutableDictionary dictionary];
    }

    GADExtras *admobExtras = [_adRequest adNetworkExtrasFor:GADExtras.class];
    [auctionRequest.adMobExtras addEntriesFromDictionary:[self filterTargeting:[admobExtras.additionalParameters mutableCopy]]];

    if (auctionRequest.requestData == nil) {
        auctionRequest.requestData = [[AMORequestData alloc] initWithAdServerAdRequest:self andAdServerAdView:adView];
    }
    return auctionRequest;
}


- (NSMutableDictionary *)getCustomTargeting {
    NSDictionary *extras = [self getAdMobExtras];
    NSMutableDictionary *targeting = [NSMutableDictionary dictionary];

    NSMutableDictionary *merged = [[NSMutableDictionary alloc] init];
    [merged addEntriesFromDictionary:extras];
    [merged addEntriesFromDictionary:targeting];
    return merged;
}

- (NSDate *)getBirthday {
    return _adRequest.birthday;
}

- (GADRequest *)getGadRequest {
    return _adRequest;
}

- (NSString *)getGender {
    if (_adRequest.gender == kGADGenderMale) {
        return @"male";
    }
    if (_adRequest.gender == kGADGenderFemale) {
        return @"female";
    } else {
        return @"unknown";
    }
}

- (CLLocation *)getLocation {
    //todo - - seems that ios can't get this? need to research.
    return nil;
}

- (NSString *)getContentUrl {
    return _adRequest.contentURL;
}

- (NSString *)getPublisherProvidedId {
    if ([_adRequest isKindOfClass:[DFPRequest class]]) {
        return ((DFPRequest *) _adRequest).publisherProvidedID;
    }
    return @"";
}

+ (NSString *)currentExtrasLabel {
    AMOSdkManager *manager = AMOSdkManager.get;
    if (!manager) {
        return nil;
    }

    return manager.currentLineItemLabel;
}

+ (GADCustomEventExtras *)extrasForRequest:(AMOAuctionRequest *)request andLabel:(NSString *)label {
    if (!label) {
        return nil;
    }

    GADCustomEventExtras *extras = [[GADCustomEventExtras alloc] init];

    // copy the source each time.. JIC
    [extras setExtras:[NSDictionary dictionaryWithDictionary:request.networkExtras] forLabel:label];
    return extras;
}

+ (AMOGADRequest *)fromAuctionRequest:(AMOAuctionRequest *)request {
    GADRequest *gadRequest = [GADRequest request];
    NSString *defaultLabel = kAMDefaultExtrasLabel;
    if([AMOSdkManager get]){
        NSDictionary *config  = [[AMOSdkManager get] sdkConfigurations];
        NSString *serverLabel;
        if(config && am_obj_isString([config objectForKey:@"s_adserverLabel"])){
            serverLabel = [config objectForKey:@"s_adserverLabel"];
        }
        if(serverLabel != nil){
            defaultLabel= serverLabel;
        }
    }

    GADCustomEventExtras *defaultExtras = [self extrasForRequest:request andLabel:defaultLabel];
    if (defaultExtras) {
        [gadRequest registerAdNetworkExtras:defaultExtras];
    }

    NSString *currentLabel = [self currentExtrasLabel];
    GADCustomEventExtras *addlExtras = [self extrasForRequest:request andLabel:currentLabel];
    if (addlExtras) {
        AMLogInfo(@"Detected additional extras @ %@", currentLabel);
        [gadRequest registerAdNetworkExtras:addlExtras];
    }

    for (NSString *key in request.targeting) {
        NSObject *value = request.targeting[key];
        if (value == nil) {
            continue;
        }
    }
    
    if(request.requestData){
        gadRequest = [self appendRequestData:request.requestData toDFPRequest:gadRequest];
    }
    
    if (request.adMobExtras != nil) {
        NSMutableDictionary *completeExtras = request.adMobExtras;
        [completeExtras addEntriesFromDictionary:request.targeting];
        GADExtras *adMobExtras = [[GADExtras alloc] init];
        adMobExtras.additionalParameters = completeExtras;
        [gadRequest registerAdNetworkExtras:adMobExtras];
    }
    return [[AMOGADRequest alloc] initWithGadRequest:gadRequest];
}


/**
 * todo - documentation.
 * @return extras dictionary
 */
- (NSDictionary *)getAdMobExtras {
    GADExtras *extras = [_adRequest adNetworkExtrasFor:GADExtras.class];
    if (extras != nil) {
        return [extras.additionalParameters mutableCopy];
    }
    return [[NSDictionary alloc] init];
}

+ (GADRequest *)appendRequestData:(AMORequestData *)requestData toDFPRequest:(GADRequest *)gadRequest{
    if(requestData.contentUrl && [requestData.contentUrl length] > 0){
        gadRequest.contentURL = requestData.contentUrl;
    }
    if(requestData.birthday){
        gadRequest.birthday = requestData.birthday;
    }

    return gadRequest;
}

@end

