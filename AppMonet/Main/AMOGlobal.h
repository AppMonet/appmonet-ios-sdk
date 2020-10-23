//
//  AMGlobal.h
//  AppMonet_Bidder
//
//  Created by Jose Portocarrero on 12/10/19.
//  Copyright © 2019 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifndef AMO_ANIMATED
#define AMO_ANIMATED YES
#endif

typedef NS_ENUM(NSUInteger, AMInterstitialCloseButtonStyle) {
    AMInterstitialCloseButtonStyleAlwaysVisible,
    AMInterstitialCloseButtonStyleAlwaysHidden,
    AMInterstitialCloseButtonStyleAdControlled,
};

typedef NS_ENUM(NSUInteger, AMInterstitialOrientationType) {
    AMInterstitialOrientationTypePortrait,
    AMInterstitialOrientationTypeLandscape,
    AMInterstitialOrientationTypeAll,
};

UIWindow *AMKeyWindow(void);

UIInterfaceOrientation AMInterfaceOrientation(void);


