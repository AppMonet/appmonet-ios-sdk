//
//  CustomNativeAdView.h
//  App_Mopub
//
//  Created by Jose Portocarrero on 1/6/20.
//  Copyright © 2020 AppMonet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPNativeAdRendering.h"

NS_ASSUME_NONNULL_BEGIN

@interface CustomNativeAdView : UIView <MPNativeAdRendering>
@property (strong, nonatomic) UIImageView *mainImageView;
@end

NS_ASSUME_NONNULL_END
