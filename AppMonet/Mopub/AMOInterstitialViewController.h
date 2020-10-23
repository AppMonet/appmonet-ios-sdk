//
//  AMOInterstitialViewController.h
//  AppMonet_Mopub
//
//  Created by Jose Portocarrero on 3/27/18.
//  Copyright © 2018 AppMonet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AMInterstitialCustomEvent.h"
#import "AMOAdView.h"
#import "AMOGlobal.h"
@protocol AMInterstitialViewControllerDelegate;

@interface AMOInterstitialViewController : UIViewController
@property (nonatomic, assign) AMInterstitialCloseButtonStyle closeButtonStyle;
@property (nonatomic, assign) AMInterstitialOrientationType orientationType;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, weak) id<AMInterstitialViewControllerDelegate> delegate;

- (void)presentInterstitialFromViewController:(UIViewController *)controller complete:(void(^)(NSError *))complete;
- (void)dismissInterstitialAnimated:(BOOL)animated;
- (BOOL)shouldDisplayCloseButton;
- (void)willPresentInterstitial;
- (void)didPresentInterstitial;
- (void)willDismissInterstitial;
- (void)didDismissInterstitial;
- (void)layoutCloseButton;

@end


@protocol AMInterstitialViewControllerDelegate <NSObject>

- (NSString *)adUnitId;
- (void)interstitialWillAppear:(AMOInterstitialViewController *)interstitial;
- (void)interstitialDidAppear:(AMOInterstitialViewController *)interstitial;
- (void)interstitialWillDisappear:(AMOInterstitialViewController *)interstitial;
- (void)interstitialDidDisappear:(AMOInterstitialViewController *)interstitial;

@end
