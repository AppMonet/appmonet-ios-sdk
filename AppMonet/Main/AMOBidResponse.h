//
// Created by Jose Portocarrero on 11/2/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kAMCodeKey;
extern NSString *const kAMAdmKey;
extern NSString *const kAMWidthKey;
extern NSString *const kAMUrlKey;
extern NSString *const kAMHeightKey;
extern NSString *const kAMIdKey;
extern NSString *const kAMTsKey;
extern NSString *const kAMCpmKey;
extern NSString *const kAMBidderKey;
extern NSString *const kAMUuidKey;
extern NSString *const kAMAdUnitIdKey;
extern NSString *const kAMFlexSizeKey;
extern NSString *const kAMKeyWordsKey;
extern NSString *const kAMRenderPixelKey;
extern NSString *const kAMClickPixelKey;
extern NSString *const kAMCoolKey;
extern NSString *const kAMApplicationIdKey;
extern NSString *const kAMQueueNextKey;
extern NSString *const kAMOrientationKey;
extern NSString *const kAMNativeRenderKey;
extern NSString *const kAMWvUuidKey;
extern NSString *const kAMUKey;
extern NSString *const kAMExpirationKey;
extern NSString *const kAMDurationKey;
extern NSString *const kAMRefreshKey;
extern NSString *const kAMBidExtrasKey;
extern NSString *const kAMInterstitialKey;
extern NSString *const kAMInterstitialCloseKey;

extern NSString *const kAMBidBundleKey;

@interface AMOBidResponse : NSObject
@property(nonatomic, strong) NSString *adm;
@property(nonatomic, strong) NSString *id;
@property(nonatomic, strong) NSString *code;
@property(nonatomic, strong) NSNumber *width;
@property(nonatomic, strong) NSNumber *height;
@property(nonatomic, strong) NSNumber *createdAt;
@property(nonatomic, strong) NSNumber *cpm;
@property(nonatomic, strong) NSString *bidder;
@property(nonatomic, strong) NSString *adUnitId;
@property(nonatomic, strong) NSString *keyWords;
@property(nonatomic, strong) NSString *renderPixel;
@property(nonatomic, strong) NSString *clickPixel;
@property(nonatomic, strong) NSString *u;
@property(nonatomic, strong) NSString *orientation;
@property(nonatomic, strong) NSString *uuid;
@property(nonatomic, strong) NSNumber *cool;
@property(nonatomic) BOOL nativeRender;
@property(nonatomic, strong) NSString *wvUUID;
@property(nonatomic, strong) NSNumber *duration;
@property(nonatomic, strong) NSNumber *expiration;
@property(nonatomic, strong) NSDictionary *extras;
@property(nonatomic, strong) NSString *url;
@property(nonatomic) BOOL nativeInvalidated;
@property(nonatomic) BOOL queueNext;
@property(nonatomic) BOOL flexSize;
@property(nonatomic, strong) NSDictionary *interstitial;
@property(nonatomic, strong) NSNumber *refresh;


- (NSString *)description;

- (void)markInvalidated;

- (BOOL)needsInvalidation;

@end
