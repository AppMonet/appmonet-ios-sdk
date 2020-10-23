//
// Created by Jose Portocarrero on 11/3/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AMOBidResponse;


@interface AMOAdViewContext : NSObject
@property(nonatomic, strong, readonly) NSString *url;
@property(nonatomic, strong, readonly) NSString *userAgent;
@property(nonatomic, strong, readonly) NSNumber *width;
@property(nonatomic, strong, readonly) NSNumber *height;
@property(nonatomic, strong, readonly) NSString *adUnitId;
@property(nonatomic, strong, readonly) NSString *html;
@property(nonatomic, readonly) BOOL richMedia;
@property(nonatomic, readonly) BOOL explicitlyCreated;

- (instancetype)initWithUrl:(NSString *)url andUserAgent:(NSString *)userAgent andWidth:(NSNumber *)width
                  andHeight:(NSNumber *)height andAdUnitId:(NSString *)adUnitId andHtml:(NSString *)html
               andRichMedia:(BOOL)richMedia;

- (instancetype)initWithBidResponse:(AMOBidResponse *)bid;
- (NSDictionary *)toDictionary;
- (NSString *)toHash;
@end