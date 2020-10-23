//
// Created by Jose Portocarrero on 10/27/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMOAdView.h"

uint64_t AMusableMemory(void);

uint64_t AMfreeMemory(void);

BOOL am_obj_isString(NSObject *obj);

BOOL am_obj_isNumber(NSObject *obj);

BOOL am_obj_isDictionary(NSObject *obj);

@class AMODeviceData;
@class AMOBidResponse;
@class AMODispatchState;

@interface AMOUtils : NSObject
+ (NSNumber *)asIntPixels:(NSNumber *)dips;

+ (id)parseJson:(NSData *)data;

+ (NSString *)toJson:(NSObject *)data;

+ (NSString *)encodeBase64:(NSString *)source;

+ (void)logFromJS:(NSString *)level message:(NSArray<NSString *> *)args;

+ (NSString *)uuid;

+ (NSString *)getCustomEventSourceType:(AMOAdType)adType;

+ (NSDictionary *)parseVastTracking:(NSString *)url withRegex:(NSRegularExpression *)regex;

+ (NSString *)hexStringForColor:(UIColor *)color;

+ (AMODispatchState *)cancelableDispatchAfter:(dispatch_time_t)when inQueue:(dispatch_queue_t)queue withState:(AMODispatchState *)cancelState withBlock:(void (^)(void))block;

+ (NSNumber *)getCurrentMillis;
@end
