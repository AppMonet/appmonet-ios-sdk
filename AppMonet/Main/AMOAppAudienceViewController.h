//
// Created by Jose Portocarrero on 4/4/18.
// Copyright (c) 2018 AppMonet. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AMAppAudienceViewControllerDelegate;

@interface AMOAppAudienceViewController : UIViewController

@property(nonatomic, weak) id <AMAppAudienceViewControllerDelegate> delegate;

- (void)presentAppAudienceFromViewController:(UIViewController *)controller;
- (void)close;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol AMAppAudienceViewControllerDelegate <NSObject>

- (void)appAudienceLoading:(AMOAppAudienceViewController *)appAudience;
- (void)appAudienceDismissing:(AMOAppAudienceViewController *)appAudience;

@end


