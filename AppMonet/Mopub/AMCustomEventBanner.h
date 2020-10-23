//
// Created by Jose Portocarrero on 12/6/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMOAdServerAdapter.h"
#if __has_include(<MoPub/MoPub.h>)
#import <MoPub/MoPub.h>
#elif __has_include(<MoPubSDKFramework/MoPub.h>)
#import <MoPubSDKFramework/MoPub.h>
#else
#import "MPInlineAdAdapter.h"
#endif
@interface AMCustomEventBanner : MPInlineAdAdapter <MPThirdPartyInlineAdAdapter>
@end
