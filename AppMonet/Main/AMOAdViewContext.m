//
// Created by Jose Portocarrero on 11/3/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMOAdViewContext.h"
#import "AMOBidResponse.h"


@implementation AMOAdViewContext {
}
- (instancetype)initWithUrl:(NSString *)url andUserAgent:(NSString *)userAgent andWidth:(NSNumber *)width
                  andHeight:(NSNumber *)height andAdUnitId:(NSString *)adUnitId andHtml:(NSString *)html
               andRichMedia:(BOOL)richMedia {
    self = [super init];
    if (self != nil) {
        _url = url;
        _userAgent = userAgent;
        _width = width;
        _height = height;
        _adUnitId = adUnitId;

        // the html doesn't really get used anyway..
        if (html) {
            _html = html;
        } else {
            _html = @"";
        }

        _richMedia = richMedia;
        _explicitlyCreated = TRUE;
    }
    return self;
}

- (NSDictionary *)toDictionary {
    return @{
        @"url": _url,
        @"userAgent": _userAgent,
        @"width": _width,
        @"height": _height,
        @"adUnitId": _adUnitId,
    };
}

- (instancetype)initWithBidResponse:(AMOBidResponse *)bid {
    self = [super init];
    if (self != nil) {
        _url = bid.url;
        _userAgent = bid.u;
        _width = bid.width;
        _height = bid.height;
        _adUnitId = bid.adUnitId;
        _html = nil;
        _richMedia = bid.nativeRender;
        _explicitlyCreated = FALSE;
    }
    return self;
}

- (NSString *)toHash {
    return [NSString stringWithFormat:@"%@%@%@%@%@", _url, _userAgent, _width, _height, _adUnitId];
}


@end
