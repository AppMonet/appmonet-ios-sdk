//
// Created by Jose Portocarrero on 1/8/20.
// Copyright (c) 2020 AppMonet. All rights reserved.
//

#import "AMCustomEventUtil.h"
#import "AMOConstants.h"
#import "AMOAdSize.h"

static NSString const *kAdUnitId = @"adunitId";
static NSString const *kAMTagId = @"tagId";
static NSString const *kAMLTagId = @"tagid";

@implementation AMCustomEventUtil
NSString *const kAMCpm = @"cpm";

+ (NSString *)getAdUnit:(NSDictionary *)eventInfo fromLocalExtras:(NSDictionary *)localExtras withAdSize:(AMOAdSize *)adSize {
    if (localExtras[kAMAdUnitKeywordKey] != nil) {
        return localExtras[kAMAdUnitKeywordKey];
    }
    NSString *adUnitId = eventInfo[kAdUnitId];
    if (!adUnitId) {
        if (eventInfo[kAMTagId]) {
            adUnitId = eventInfo[kAMTagId];
        } else if (eventInfo[kAMLTagId]) {
            adUnitId = eventInfo[kAMLTagId];
        } else if (adSize != nil && ![adSize.height isEqualToNumber:@0] & ![adSize.width isEqualToNumber:@0]) {
            adUnitId = [NSString stringWithFormat:@"%@x%@", adSize.width, adSize.height];
        }
    }
    return adUnitId;
}

+ (NSNumber *)getCpm:(NSDictionary *)eventInfo {
    if ([eventInfo[kAMCpm] isKindOfClass:[NSString class]]) {
        return @(((NSString *) eventInfo[kAMCpm]).floatValue);
    }
    return (eventInfo[kAMCpm]) ? eventInfo[kAMCpm] : @0;
}

+ (nullable AMOBidResponse *)getBidFromLocalExtras:(nullable NSDictionary *)localExtras {
    return (localExtras && [localExtras valueForKey:AMBidsKey]) ? localExtras[AMBidsKey] : nil;
}

@end
