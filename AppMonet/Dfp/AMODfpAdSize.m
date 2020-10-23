//
// Created by Jose Portocarrero on 11/6/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMODfpAdSize.h"
#import "AMOUtils.h"
@import GoogleMobileAds;

@implementation AMODfpAdSize

- (instancetype)initWithAdSize:(GADAdSize)adSize {
    self = [super init];
    if (self != nil) {
        self.width = @(adSize.size.width);
        self.height =@(adSize.size.height);
    }
    return self;
}

-(instancetype)initWithWidth:(NSNumber *)width andHeight:(NSNumber *)height {
    self = [super initWithWidth:width andHeight:height];
    return self;
}

- (NSNumber *)getWidthInPixels {
    return [AMOUtils asIntPixels:self.width];
}

- (NSNumber *)getHeightInPixels {
    return [AMOUtils asIntPixels:self.height];
}

@end
