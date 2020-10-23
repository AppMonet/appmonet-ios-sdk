//
// Created by Jose Portocarrero on 4/4/18.
// Copyright (c) 2018 AppMonet. All rights reserved.
//

#import "AMOAppAudienceViewController.h"

@interface AMOAppAudienceViewController ()

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation AMOAppAudienceViewController

@synthesize delegate = _delegate;

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
}

#pragma mark - Public

- (void)presentAppAudienceFromViewController:(UIViewController *)controller {
    [controller presentViewController:self animated:YES completion:nil];
    [_delegate appAudienceLoading:self];
}

- (void)close {
    UIViewController *presentingViewController = self.presentingViewController;
    [presentingViewController dismissViewControllerAnimated:YES completion:^{
        [_delegate appAudienceDismissing:self];
    }];
}

#pragma mark - StatusBar

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;

}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= MP_IOS_9_0

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#else
- (NSUInteger)supportedInterfaceOrientations
#endif
{
    return UIInterfaceOrientationMaskPortrait;

}

@end
