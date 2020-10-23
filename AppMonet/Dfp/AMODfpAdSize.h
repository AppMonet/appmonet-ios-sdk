//
// Created by Jose Portocarrero on 11/6/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMOAdSize.h"
@import GoogleMobileAds;

@interface AMODfpAdSize : AMOAdSize
- (instancetype)initWithAdSize:(GADAdSize)adSize;

- (instancetype)initWithWidth:(NSNumber *)width andHeight:(NSNumber *)height;

- (NSNumber *)getWidthInPixels;

- (NSNumber *)getHeightInPixels;
@end
