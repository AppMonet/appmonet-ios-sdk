//
// Created by Jose Portocarrero on 11/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class AMOAdServerAdRequest;
@protocol AMOAdServerAdView;
@protocol AMServerAdRequest;


@interface AMORequestData : NSObject
@property (nonatomic, nullable, readonly) NSDate *birthday;
@property (nonatomic, nullable, readonly) NSString *adUnitId;
@property (nonatomic, nullable, readonly) NSString *gender;
@property (nonatomic, nullable, readonly) CLLocation *location;
@property (nonatomic, nullable, readonly) NSString *contentUrl;
@property (nonatomic, nullable, readonly) NSString *ppid;
@property (nonatomic, nonnull, readonly) NSMutableDictionary *additional;

-(instancetype) initWithAdServerAdRequest:(id<AMServerAdRequest>)request andAdServerAdView:(id<AMOAdServerAdView>)adView;
-(NSMutableDictionary * _Nonnull)toDictionary;
@end
