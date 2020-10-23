//
//  AMInterstitialCustomEvent.h
//  AppMonet_Mopub
//
//  Created by Jose Portocarrero on 3/27/18.
//  Copyright © 2018 AppMonet. All rights reserved.
//

#import "MoPub.h"

#import <Foundation/Foundation.h>
#import "AMOAdServerAdapter.h"
#if __has_include(<MoPub/MoPub.h>)
    #import <MoPub/MoPub.h>
#elif __has_include(<MoPubSDKFramework/MoPub.h>)
    #import <MoPubSDKFramework/MoPub.h>
#else
    #import "MPFullscreenAdAdapter.h"
#endif


@interface AMInterstitialCustomEvent : MPFullscreenAdAdapter <MPThirdPartyFullscreenAdAdapter>

@end
