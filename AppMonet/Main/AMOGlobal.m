//
//  AMGlobal.m
//  AppMonet_Bidder
//
//  Created by Jose Portocarrero on 12/10/19.
//  Copyright © 2019 AppMonet. All rights reserved.
//

#import "AMOGlobal.h"

UIInterfaceOrientationMask AMInterstitialOrientationTypeToUIInterfaceOrientationMask(AMInterstitialOrientationType type)
{
    switch (type) {
        case AMInterstitialOrientationTypePortrait: return UIInterfaceOrientationMaskPortrait;
        case AMInterstitialOrientationTypeLandscape: return UIInterfaceOrientationMaskLandscape;
        default: return UIInterfaceOrientationMaskAll;
    }
}

UIWindow *AMKeyWindow()
{
    return [UIApplication sharedApplication].keyWindow;
}

UIInterfaceOrientation AMInterfaceOrientation()
{
    return [UIApplication sharedApplication].statusBarOrientation;
}
