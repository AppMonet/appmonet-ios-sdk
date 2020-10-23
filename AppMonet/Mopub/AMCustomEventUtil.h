//
// Created by Jose Portocarrero on 1/8/20.
// Copyright (c) 2020 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AMOAdSize;
@class AMOBidResponse;
@interface AMCustomEventUtil : NSObject
extern NSString *const kAMCpm;

+ (NSString *)getAdUnit:(NSDictionary *)eventInfo fromLocalExtras:(NSDictionary *)localExtras withAdSize:(AMOAdSize *)adSize;

+ (NSNumber *)getCpm:(NSDictionary *)eventInfo;

+ (nullable AMOBidResponse *)getBidFromLocalExtras:(nullable NSDictionary *)localExtras;

@end
