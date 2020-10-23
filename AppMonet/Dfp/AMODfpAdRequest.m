//
// Created by Jose Portocarrero on 11/6/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMODfpAdRequest.h"
#import "AMOAuctionRequest.h"
#import "AMORequestData.h"
#import "AMOConstants.h"
#import "AMOSdkManager.h"
#import "AMOUtils.h"
@import GoogleMobileAds;

@implementation AMODfpAdRequest {
    GADRequest *_adRequest;
}

- (instancetype)initWithCustomEventRequest:(GADCustomEventRequest *)customEventRequest {
    self = [super init];
    if (self) {
        _adRequest = [[DFPRequest alloc] init];
        _adRequest.birthday = customEventRequest.userBirthday;
        _adRequest.gender = customEventRequest.userGender;
        [_adRequest setLocationWithLatitude:customEventRequest.userLatitude longitude:customEventRequest.userLongitude
                                   accuracy:customEventRequest.userLocationAccuracyInMeters];
    }

    return self;
}

- (instancetype)initWithDfpRequest:(DFPRequest *)adRequest {
    self = [super init];
    if (self) {
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
    if ([_adRequest isKindOfClass:[DFPRequest class]]) {
        [auctionRequest.targeting addEntriesFromDictionary:
                [self filterTargeting:[((DFPRequest *) _adRequest).customTargeting mutableCopy]]];
    }
    return auctionRequest;
}


- (NSMutableDictionary *)getCustomTargeting {
    NSDictionary *extras = [self getAdMobExtras];
    NSMutableDictionary *targeting = [NSMutableDictionary dictionary];

    if ([_adRequest isKindOfClass:[DFPRequest class]]) {
        [targeting addEntriesFromDictionary:((DFPRequest *) _adRequest).customTargeting];
    }

    NSMutableDictionary *merged = [[NSMutableDictionary alloc] init];
    [merged addEntriesFromDictionary:extras];
    [merged addEntriesFromDictionary:targeting];
    return merged;
}

- (NSDate *)getBirthday {
    return _adRequest.birthday;
}

- (DFPRequest *)getDfpRequest {
    return (DFPRequest *) _adRequest;
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

+ (AMODfpAdRequest *)fromAuctionRequest:(AMOAuctionRequest *)request {
    DFPRequest *dfpRequest = [DFPRequest request];
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
        [dfpRequest registerAdNetworkExtras:defaultExtras];
    }

    NSString *currentLabel = [self currentExtrasLabel];
    GADCustomEventExtras *addlExtras = [self extrasForRequest:request andLabel:currentLabel];
    if (addlExtras) {
        AMLogInfo(@"Detected additional extras @ %@", currentLabel);
        [dfpRequest registerAdNetworkExtras:addlExtras];
    }

    for (NSString *key in request.targeting) {
        NSObject *value = request.targeting[key];
        if (value == nil) {
            continue;
        }
        NSMutableDictionary *targetingCopy = (dfpRequest.customTargeting) ? [dfpRequest.customTargeting mutableCopy]
                : [[NSMutableDictionary alloc] init];
        if ([value isKindOfClass:NSMutableArray.class]) {
            targetingCopy[key] = value;
        } else {
            targetingCopy[key] = value.description;
            dfpRequest.customTargeting = targetingCopy;
        }
    }
    
    if(request.requestData != nil){
        dfpRequest = [self appendRequestData:request.requestData toDFPRequest:dfpRequest];
    }

    if (request.adMobExtras != nil) {
        NSMutableDictionary *completeExtras = request.adMobExtras;
        [completeExtras addEntriesFromDictionary:request.targeting];
        GADExtras *adMobExtras = [[GADExtras alloc] init];
        adMobExtras.additionalParameters = completeExtras;
        [dfpRequest registerAdNetworkExtras:adMobExtras];
    }
    return [[AMODfpAdRequest alloc] initWithDfpRequest:dfpRequest];
}

- (NSDictionary *)getAdMobExtras {
    GADExtras *extras = [_adRequest adNetworkExtrasFor:GADExtras.class];
    if (extras != nil) {
        return [extras.additionalParameters mutableCopy];
    }
    return [[NSDictionary alloc] init];
}

+ (DFPRequest *)appendRequestData:(AMORequestData *)requestData toDFPRequest:(DFPRequest *)dfpRequest{
    if(requestData.contentUrl && [requestData.contentUrl length] > 0){
        dfpRequest.contentURL = requestData.contentUrl;
    }
    if(requestData.birthday){
        dfpRequest.birthday = requestData.birthday;
    }
    if(requestData.additional){
        dfpRequest.customTargeting = requestData.additional;
    }
    return dfpRequest;
}

@end
