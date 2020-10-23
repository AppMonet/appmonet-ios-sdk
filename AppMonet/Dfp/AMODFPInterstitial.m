//
// Created by Nick Jacob on 4/16/19.
// Copyright (c) 2019 AppMonet. All rights reserved.
//

#import "AMODFPInterstitial.h"
#import "AMOConstants.h"
#import "AMOAdView.h"
#import "AMOBidResponse.h"
#import "AMOAppMonetViewLayout.h"

static const CGFloat kCloseButtonPadding = 5.0;
static NSString *const kCloseButton = @"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACgAAAAoCAYAAACM/rhtAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAZhJREFUeNrsmNttgzAUhq1IVfsWXqq8MgIPVTZoFqiyRzZBSiZoFmCEiAlaOgFMAJnA9W/lRK7rBpsCslv/0lEi48uHD+f4wlhUVNQ04pynwnbCTsJa/l3t5RnqpHOCZcIKnaaua16WpbS26wy8sk02NVx+nR4B8Xo88pftlj+uVvzu/uGLoQzPUEcDzqcAS4S90Qj7w8EI9ZOhLtooQl/J6HBw49N6bQ2mG9qij1EhCe69qpxm7dZsoi+CHOWbw1uPAadCKjOZ/yZapXS34uN3cTXqoo1epigbAlhQQOhwFMU2kKhDUaxDKoFTDEnCsmPdteqAfZB9ddG3koJSF0Bkf5nDhgzs8iIY46KdC+DJ5BJbAJdZpk8GY7oAyrW1L3JNIC5w5GZanFwAZRqwjVAVyAWOjFKOiWVhWjnw2zSN1ctU1Qd73mxYdz6zZLmUhv8owzMb3RprEepeb1YXU5s/FSTepxnvE7XfS533m4Ugtlveb1iD2PIHcWjy/tgZxMHd5uoDEHT1obhx3quPIC6PoqL+mz4FGACIEQjJhTzglwAAAABJRU5ErkJggg==";

@interface AMODFPInterstitial ()
@property(nonatomic, strong) AMOBidResponse *bid;
@property(nonatomic, strong) AMOAppMonetViewLayout *viewLayout;
@end

@implementation AMODFPInterstitial {
}

@synthesize closeButton = _closeButton;
@synthesize delegate = _delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    if (self.viewLayout) {
        self.viewLayout.backgroundColor = [UIColor blackColor];
    }
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)presentFromViewController:(UIViewController *)controller withAdView:(AMOAppMonetViewLayout *)viewLayout {
    if (self.presentingViewController) {
        AMLogInfo(@"Already showing.. skipping");
        // TODO: return an NSError here
        return;
    }
    self.modalPresentationStyle = UIModalPresentationFullScreen;
    [self setStatusBarHiddenState:YES];

    self.viewLayout = viewLayout;
    [self layoutAdView:viewLayout];
    if (viewLayout.adView.bid.interstitial == nil || viewLayout.adView.bid.interstitial[kAMInterstitialCloseKey]) {
        [self layoutCloseButton];
    }

    [self willPresentInterstitial];
    [controller presentViewController:self animated:YES completion:^{
        [self didPresentInterstitial];
    }];
}

- (void)layoutAdView:(AMOAppMonetViewLayout *)adView {
    adView.frame = self.view.bounds;
    if (adView.subviews && adView.subviews.count > 0) {
        adView.subviews[0].frame = self.view.bounds;
    }
    adView.autoresizingMask = UIViewAutoresizingFlexibleHeight |
            UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:adView];
}

#pragma mark - Dismiss / Present

- (void)willPresentInterstitial {
    [_delegate interstitial:self willShow:_viewLayout];
}

- (void)didPresentInterstitial {
    [_delegate interstitial:self didShow:_viewLayout];
}

- (void)willDismissInterstitial {
    [_delegate interstitial:self willDismiss:_viewLayout];
}

- (void)didDismissInterstitial {
    [_delegate interstitial:self didDissmis:_viewLayout];
}

#pragma mark - View  Cycle

- (void)dismissInterstitialAnimated:(BOOL)animated {
    [self willDismissInterstitial];

    UIViewController *presentingViewController = self.presentingViewController;
    if (presentingViewController.presentedViewController == self) {
        [presentingViewController dismissViewControllerAnimated:YES completion:^{
            [self didDismissInterstitial];
        }];
    } else {
        [self didDismissInterstitial];
    }
}

- (void)dealloc {
    _delegate = nil;
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

    CGFloat originX = self.view.bounds.size.width -
            kCloseButtonPadding -
            self.closeButton.bounds.size.width;

    self.closeButton.frame =
            CGRectMake(originX,
                    kCloseButtonPadding,
                    self.closeButton.bounds.size.width,
                    self.closeButton.bounds.size.height);

    [self.closeButton setContentEdgeInsets:UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0)];

    // our close button is *always* visible
    self.closeButton.hidden = NO;

    if (@available(iOS 11.0, *)) {
        self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
                [self.closeButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:kCloseButtonPadding],
                [self.closeButton.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-kCloseButtonPadding],
        ]];
    }

    [self.view bringSubviewToFront:self.closeButton];
}

- (void)closeButtonPressed {
    [self dismissInterstitialAnimated:YES];
}

#pragma mark - Private

- (void)setStatusBarHiddenState:(BOOL)hidden {
    [[UIApplication sharedApplication] setStatusBarHidden:hidden];
}

#pragma mark - Orientation

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#else
- (NSUInteger)supportedInterfaceOrientations
#endif
{
    // the default orientation should be portrait...
    NSString *orientation = @"portrait";
    if (self.bid) {
        orientation = self.bid.orientation;
    }

    // if it's null, default to landscape.. right?
    if (!orientation) {
        orientation = @"portrait";
    }

    NSUInteger applicationSupportedOrientations =
            [[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow:[UIApplication.sharedApplication keyWindow]];

    NSUInteger interstitialSupportedOrientations = applicationSupportedOrientations;
    if ([orientation isEqualToString:@"portrait"]) {
        interstitialSupportedOrientations &=
                (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown);
    } else if ([orientation isEqualToString:@"landscape"]) {
        interstitialSupportedOrientations &= UIInterfaceOrientationMaskLandscape;
    }

    if (!interstitialSupportedOrientations) {
        AMLogInfo(@"Your application does not support this interstitial's desired orientation "
                  @"(%@).", orientation);
        return applicationSupportedOrientations;
    } else {
        return interstitialSupportedOrientations;
    }
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    AMLogInfo(@"checking supported/preferred orientation!");

    NSUInteger supportedInterfaceOrientations = [self supportedInterfaceOrientations];
    UIInterfaceOrientation currentInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
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
