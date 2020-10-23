//
// Created by Jose Portocarrero on 11/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMOAdServerAdRequest.h"
#import "AMOAuctionRequest.h"
#import "AMOAdServerAdView.h"
#import "AMOConstants.h"
#import "AMOBidResponse.h"

@implementation AMOAdServerAdRequest {

}
- (AMOAuctionRequest *)apply:(AMOAuctionRequest *)auctionRequest andAdServerAdView:(id <AMOAdServerAdView>)adView {
    return auctionRequest;
}

- (NSMutableDictionary *)filterTargeting:(NSMutableDictionary *)targeting {
    if (targeting == nil) {
        return [[NSMutableDictionary alloc] init];
    }

    NSMutableDictionary *filteredDicitionary = [[NSMutableDictionary alloc] initWithDictionary:targeting];
    NSString *dynamicKeyPrefix = targeting[kAMCustomKwPrefixKey];
    for (NSString *key in targeting) {
        if ([self shouldRemoveKey:dynamicKeyPrefix andKey:key]) {
            [filteredDicitionary removeObjectForKey:key];
        }
    }
    return filteredDicitionary;
}

- (AMOBidResponse *)getBid {
    return nil;
}

- (NSDate *)getBirthday {
    return nil;
}

- (NSString *)getContentUrl {
    return nil;
}

- (NSMutableDictionary *)getCustomTargeting {
    return nil;
}

- (NSString *)getGender {
    return nil;
}

- (CLLocation *)getLocation {
    return nil;
}

- (NSString *)getPublisherProvidedId {
    return nil;
}

- (BOOL)hasBids {
    return false;
}

- (BOOL)shouldRemoveKey:(NSString *)dynamicKeyPrefix andKey:(NSString *)key {
    if (key == nil) {
        return false;
    }

    return [key hasPrefix:kAMKwKeyPrefix] || (dynamicKeyPrefix != nil && [key hasPrefix:dynamicKeyPrefix]);
}


@end
