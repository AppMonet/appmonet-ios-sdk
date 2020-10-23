//
// Created by Jose Portocarrero on 11/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AMOAdServerWrapper;


@interface AMOAdSize : NSObject{
}
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, strong) NSNumber *width;

- (instancetype)init;

- (instancetype)initWithWidth:(NSNumber *)width andHeight:(NSNumber *)height;

+ (AMOAdSize *)from:(NSNumber *)width andHeight:(NSNumber *)height andAdServerWrapper:(id <AMOAdServerWrapper>)adServerWrapper;

- (NSNumber *)getWidthInPixels;

- (NSNumber *)getHeightInPixels;


@end