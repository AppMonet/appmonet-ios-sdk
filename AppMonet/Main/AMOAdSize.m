//
// Created by Jose Portocarrero on 11/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMOAdSize.h"
#import "AMOAdServerWrapper.h"
#import "AMOAdView.h"


@implementation AMOAdSize {

}
- (instancetype)init {
    self = [super init];
    if (self != nil) {
        _width = @0;
        _height = @0;
    }
    return self;
}

- (instancetype)initWithWidth:(NSNumber *)width andHeight:(NSNumber *)height {
    self = [super init];
    if (self != nil) {
        _width = width;
        _height = height;
    }
    return self;
}

+ (AMOAdSize *)from:(NSNumber *)width andHeight:(NSNumber *)height andAdServerWrapper:(id <AMOAdServerWrapper>)adServerWrapper {
    if (adServerWrapper == nil) {
        return nil;
    }
    return [adServerWrapper newAdSize:width andHeight:height];
}

- (NSNumber *)getWidthInPixels {
    return nil;
}

- (NSNumber *)getHeightInPixels {
    return nil;
}

- (NSNumber *)getWidth {
    return _width;
}

- (NSNumber *)getHeight {
    return _height;
}


@end