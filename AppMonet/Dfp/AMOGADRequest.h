//
//  AMOGADRequest.h
//  AppMonet
//
//  Created by Jose Portocarrero on 5/19/20.
//  Copyright © 2020 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMOAdServerAdRequest.h"

@class GADRequest;
@class GADCustomEventRequest;

NS_ASSUME_NONNULL_BEGIN

@interface AMOGADRequest : AMOAdServerAdRequest

- (instancetype)initWithGadRequest:(GADRequest *)adRequest;

- (GADRequest *)getGadRequest;

+ (AMOGADRequest *)fromAuctionRequest:(AMOAuctionRequest *)request;
@end

NS_ASSUME_NONNULL_END
