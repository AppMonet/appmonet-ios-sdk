//
// Created by Nick Jacob on 4/16/19.
// Copyright (c) 2019 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class AMOAdView;
@class AMOBidResponse;
@class AMOAppMonetViewLayout;
@protocol AMODFPInterstitialDelegate;

@interface AMODFPInterstitial : UIViewController
@property(nonatomic, strong) UIButton *closeButton;
@property(nonatomic, weak) id <AMODFPInterstitialDelegate> delegate;

- (void)presentFromViewController:(UIViewController *)controller withAdView:(AMOAppMonetViewLayout *)viewLayout;

@end

@protocol AMODFPInterstitialDelegate <NSObject>

- (void)interstitial:(AMODFPInterstitial *)interstitial willShow:(AMOAppMonetViewLayout *)adView;

- (void)interstitial:(AMODFPInterstitial *)interstitial willDismiss:(AMOAppMonetViewLayout *)adView;

- (void)interstitial:(AMODFPInterstitial *)interstitial didShow:(AMOAppMonetViewLayout *)adView;

- (void)interstitial:(AMODFPInterstitial *)interstitial didDissmis:(AMOAppMonetViewLayout *)adView;

- (void)interstitial:(AMODFPInterstitial *)interstitial willLeaveApplication:(NSURL *)url;

- (void)interstitial:(AMODFPInterstitial *)interstitial hasError:(NSError *)error;

// TODO: better 2nd argument
- (void)interstitial:(AMODFPInterstitial *)interstitial wasClicked:(NSURL *)url;

@end
