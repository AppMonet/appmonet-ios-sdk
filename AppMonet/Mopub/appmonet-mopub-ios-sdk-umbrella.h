//
//  appmonet-bidder-ios-sdk-umbrella.h
//  AppMonet
//
//  Created by Jose Portocarrero on 3/13/20.
//  Copyright © 2020 AppMonet. All rights reserved.
//

  
#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif


FOUNDATION_EXPORT double AppMonetVersionNumber;

FOUNDATION_EXPORT const unsigned char AppMonetVersionString[];

#import "AppMonet.h"
