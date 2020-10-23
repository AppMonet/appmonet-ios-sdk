//
//  CustomNativeAdView.m
//  App_Mopub
//
//  Created by Jose Portocarrero on 1/6/20.
//  Copyright © 2020 AppMonet. All rights reserved.
//

#import "CustomNativeAdView.h"


@interface CustomNativeAdView ()

@end


@implementation CustomNativeAdView

- (void)baseInit {
    self.mainImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300, 250)];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self baseInit];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.backgroundColor = [UIColor blueColor];
    self.frame = CGRectMake(0, 500, 400, 250);
    [self addSubview:_mainImageView];

}

- (UIImageView *)nativeMainImageView {
    return self.mainImageView;
}

- (void)layoutCustomAssetsWithProperties:(NSDictionary *)customProperties imageLoader:(MPNativeAdRenderingImageLoader *)imageLoader {

}


@end
