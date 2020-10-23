//
// Created by Jose Portocarrero on 11/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AMOBidResponse;

@protocol AMOBidValidity <NSObject>
-(BOOL) isValid:(nullable AMOBidResponse *)bid;
@end
