//
//  AMOInterstitialViewController.m
//  AppMonet_Mopub
//
//  Created by Jose Portocarrero on 3/27/18.
//  Copyright © 2018 AppMonet. All rights reserved.
//


#import "AMOInterstitialViewController.h"
#import "AMOSdkManager.h"
#import "AMOAdViewPoolManager.h"
#import "AMOBidResponse.h"

#import "AMOGlobal.h"
#import "AMOConstants.h"


static const CGFloat kCloseButtonPadding = 5.0;
static const CGFloat kCloseButtonEdgeInset = 10.0;
static NSString *const kCloseButton = @"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACgAAAAoCAYAAACM/rhtAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAZhJREFUeNrsmNttgzAUhq1IVfsWXqq8MgIPVTZoFqiyRzZBSiZoFmCEiAlaOgFMAJnA9W/lRK7rBpsCslv/0lEi48uHD+f4wlhUVNQ04pynwnbCTsJa/l3t5RnqpHOCZcIKnaaua16WpbS26wy8sk02NVx+nR4B8Xo88pftlj+uVvzu/uGLoQzPUEcDzqcAS4S90Qj7w8EI9ZOhLtooQl/J6HBw49N6bQ2mG9qij1EhCe69qpxm7dZsoi+CHOWbw1uPAadCKjOZ/yZapXS34uN3cTXqoo1epigbAlhQQOhwFMU2kKhDUaxDKoFTDEnCsmPdteqAfZB9ddG3koJSF0Bkf5nDhgzs8iIY46KdC+DJ5BJbAJdZpk8GY7oAyrW1L3JNIC5w5GZanFwAZRqwjVAVyAWOjFKOiWVhWjnw2zSN1ctU1Qd73mxYdz6zZLmUhv8owzMb3RprEepeb1YXU5s/FSTepxnvE7XfS533m4Ugtlveb1iD2PIHcWjy/tgZxMHd5uoDEHT1obhx3quPIC6PoqL+mz4FGACIEQjJhTzglwAAAABJRU5ErkJggg==";

@interface AMOInterstitialViewController ()

@property(nonatomic, assign) BOOL applicationHasStatusBar;

- (void)setCloseButtonStyle:(AMInterstitialCloseButtonStyle)style;

- (void)closeButtonPressed;

- (void)dismissInterstitialAnimated:(BOOL)animated;

- (void)setApplicationStatusBarHidden:(BOOL)hidden;

@end


@implementation AMOInterstitialViewController

-(instancetype)init{
    if(self=[super init]){
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

- (void)presentInterstitialFromViewController:(UIViewController *)controller complete:(void (^)(NSError *))complete {
    if (self.presentingViewController) {
        if (complete != nil) {
            NSError *error = [NSError errorWithDomain:@"com.monet" code:-1 userInfo:@{@"Error reason": @"ViewController already presented"}];
            complete(error);
        }
        return;
    }

    [self willPresentInterstitial];

    self.applicationHasStatusBar = !([UIApplication sharedApplication].isStatusBarHidden);
    [self setApplicationStatusBarHidden:YES];
    AMOAdView *adView = [[[AMOSdkManager get] adViewPoolManager] getAdViewByUuid:self.delegate.adUnitId];
    adView.superview.frame = self.view.bounds;
    adView.frame = self.view.bounds;

    [self.view addSubview:adView.superview];
    if (adView.bid.interstitial == nil || adView.bid.interstitial[kAMInterstitialCloseKey]) {
        [self layoutCloseButton];
    }

    [controller presentViewController:self animated:AMO_ANIMATED completion:^{
        [self didPresentInterstitial];
        if (complete != nil) {
            complete(nil);
        }
    }];
}

- (void)willPresentInterstitial {
    [_delegate interstitialWillAppear:self];
}

- (void)didPresentInterstitial {
    [_delegate interstitialDidAppear:self];
}

- (void)willDismissInterstitial {
    [_delegate interstitialWillDisappear:self];

}

- (void)didDismissInterstitial {
    [_delegate interstitialDidDisappear:self];
}


- (BOOL)shouldDisplayCloseButton {
    return YES;
}

#pragma mark - Close Button

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];

        NSURL *url = [NSURL URLWithString:kCloseButton];
        NSData *imageData = [NSData dataWithContentsOfURL:url];
        UIImage *closeButtonBG = [UIImage imageWithData:imageData];
        [_closeButton setImage:closeButtonBG forState:UIControlStateNormal];
        _closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                UIViewAutoresizingFlexibleBottomMargin;

        [_closeButton sizeToFit];
        [_closeButton addTarget:self action:@selector(closeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        _closeButton.accessibilityLabel = @"Close Ad";
    }
    return _closeButton;
}

- (void)layoutCloseButton {
    [self.view addSubview:self.closeButton];
    CGFloat originX = self.view.bounds.size.width - kCloseButtonPadding -
            self.closeButton.bounds.size.width;
    self.closeButton.frame = CGRectMake(originX,
            kCloseButtonPadding,
            self.closeButton.bounds.size.width,
            self.closeButton.bounds.size.height);
    self.closeButton.contentEdgeInsets = UIEdgeInsetsMake(kCloseButtonEdgeInset, kCloseButtonEdgeInset, kCloseButtonEdgeInset, kCloseButtonEdgeInset);
    [self setCloseButtonStyle:self.closeButtonStyle];
    if (@available(iOS 11.0, *)) {
        self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
                [self.closeButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:kCloseButtonPadding],
                [self.closeButton.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-kCloseButtonPadding],
        ]];
    }
    [self.view bringSubviewToFront:self.closeButton];
}

- (void)setCloseButtonStyle:(AMInterstitialCloseButtonStyle)style {
    _closeButtonStyle = style;
    switch (style) {
        case AMInterstitialCloseButtonStyleAlwaysVisible:
            self.closeButton.hidden = NO;
            break;
        case AMInterstitialCloseButtonStyleAlwaysHidden:
            self.closeButton.hidden = YES;
            break;
        case AMInterstitialCloseButtonStyleAdControlled:
            self.closeButton.hidden = ![self shouldDisplayCloseButton];
            break;
        default:
            self.closeButton.hidden = NO;
            break;
    }
}

- (void)closeButtonPressed {
    [self dismissInterstitialAnimated:YES];
}

- (void)dismissInterstitialAnimated:(BOOL)animated {
    [self setApplicationStatusBarHidden:!self.applicationHasStatusBar];

    [self willDismissInterstitial];

    UIViewController *presentingViewController = self.presentingViewController;
    if (presentingViewController.presentedViewController == self) {
        [presentingViewController dismissViewControllerAnimated:AMO_ANIMATED completion:^{
            [self didDismissInterstitial];
        }];
    } else {
        [self didDismissInterstitial];
    }
}

#pragma mark - Hiding status bar (pre-iOS 7)

- (void)setApplicationStatusBarHidden:(BOOL)hidden {
    [[UIApplication sharedApplication] setStatusBarHidden:hidden];
}

#pragma mark - Hidding status bar (iOS 7 and above)

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Autorotation (iOS 6.0 and above)

- (BOOL)shouldAutorotate {
    return NO;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= MP_IOS_9_0

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#else
- (NSUInteger)supportedInterfaceOrientations
#endif
{
    NSUInteger applicationSupportedOrientations =
            [[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow:AMKeyWindow()];
    NSUInteger interstitialSupportedOrientations = applicationSupportedOrientations;
    NSString *orientationDescription = @"any";

    // Using the _orientationType, narrow down the supported interface orientations.

    if (_orientationType == AMInterstitialOrientationTypePortrait) {
        interstitialSupportedOrientations &=
                (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown);
        orientationDescription = @"portrait";
    } else if (_orientationType == AMInterstitialOrientationTypeLandscape) {
        interstitialSupportedOrientations &= UIInterfaceOrientationMaskLandscape;
        orientationDescription = @"landscape";
    }

    if (!interstitialSupportedOrientations) {
        AMLogDebug(@"Your application does not support this interstitial's desired orientation "
                   @"(%@).", orientationDescription);
        return applicationSupportedOrientations;
    } else {
        return interstitialSupportedOrientations;
    }
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    NSUInteger supportedInterfaceOrientations = [self supportedInterfaceOrientations];
    UIInterfaceOrientation currentInterfaceOrientation = AMInterfaceOrientation();
    NSUInteger currentInterfaceOrientationMask = (1 << currentInterfaceOrientation);

    if (supportedInterfaceOrientations & currentInterfaceOrientationMask) {
        return currentInterfaceOrientation;
    } else if (supportedInterfaceOrientations & UIInterfaceOrientationMaskPortrait) {
        return UIInterfaceOrientationPortrait;
    } else if (supportedInterfaceOrientations & UIInterfaceOrientationMaskPortraitUpsideDown) {
        return UIInterfaceOrientationPortraitUpsideDown;
    } else if (supportedInterfaceOrientations & UIInterfaceOrientationMaskLandscapeLeft) {
        return UIInterfaceOrientationLandscapeLeft;
    } else {
        return UIInterfaceOrientationLandscapeRight;
    }
}

@end
