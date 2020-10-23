//
// Created by Jose Portocarrero on 11/17/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class AMOAuctionWebView;

typedef enum {
    AMImpression = 0, AMRequest = 1, AMVastImpression = 2, AMVastFirstQuartile = 3, AMVastMidpoint = 4,
    AMVastThirdQuartile = 5, AMVastComplete = 6, AMVastError = 7, AMError = 8
} AMPixelEvents;

#define pixelEventValueString(enum) @[@"himp", @"hreq", @"vimp", @"vfq", @"vmp", @"vtq", @"vcmp", @"verr", @"herr"][enum];

@interface AMOHttpUtil : NSObject

+ (void)firePixel:(NSString *)pixelUrl;

+ (void)firePixel:(NSString *)pixelUrl andPixelEvents:(AMPixelEvents)event;

+ (void)makeRequest:(AMOAuctionWebView *)webview andRequestString:(NSDictionary *)request andCallback:(NSString *)callback;
@end
