//
// Created by Jose Portocarrero on 11/17/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMOHttpUtil.h"
#import "AMOConstants.h"
#import "AMOAjaxRequest.h"
#import "AMOAuctionWebView.h"

@implementation AMOHttpUtil


+ (void)firePixel:(NSString *)pixelUrl {
    @autoreleasepool {
        if (pixelUrl.length == 0) {
            AMLogDebug(@"invalid pixel");
            return;
        }
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:pixelUrl]];
        [request setHTTPMethod:@"GET"];
        [request setValue:AMSdkVersion forHTTPHeaderField:@"X-Monet-Version"];
        [request setValue:@"ios-native" forHTTPHeaderField:@"X-Monet-Client"];
        NSURLSessionDataTask *sessionDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            [session finishTasksAndInvalidate];
        }];
        [sessionDataTask resume];
        session = nil;
    }
}

+ (void)firePixel:(NSString *)pixelUrl andPixelEvents:(AMPixelEvents)event {
    @autoreleasepool {
        if (!pixelUrl || ![pixelUrl isKindOfClass:[NSString class]]) {
            return;
        }

        if (pixelUrl.length == 0) {
            AMLogWarn(@"invalid pixel for bid");
            return;
        }

        if (![pixelUrl containsString:kAMPixelEventReplace]) {
            AMLogWarn(@"invalid pixel: no replace");
            return;
        }

        NSString *eventStringValue = pixelEventValueString(event);
        [self firePixel:[pixelUrl stringByReplacingOccurrencesOfString:kAMPixelEventReplace
                                                            withString:eventStringValue]];
    }
}

+ (void)makeRequest:(AMOAuctionWebView *)webview andRequestString:(NSDictionary *)request andCallback:(NSString *)callback {
    AMOAjaxRequest *ajax = [self requestFromJson:request andCallback: callback];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:ajax.url]];
    [urlRequest setHTTPMethod:ajax.method];
    
    for (NSString *key in ajax.headers) {
        [urlRequest setValue:ajax.headers[key] forHTTPHeaderField:key];
    }
    
    if ([ajax.method isEqualToString:@"POST"]) {
        NSData *jsonData = [ajax.body dataUsingEncoding:NSUTF8StringEncoding];
        [urlRequest setHTTPBody:jsonData];
    }

    NSURLSessionDataTask *sessionDataTask = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data,
            NSURLResponse *response, NSError *error) {
        if (error == nil) {
            NSString *body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [self respondWith:webview andAjaxRequest:ajax andUrlResponse:(NSHTTPURLResponse *) response andBody:body];
        }
        [session finishTasksAndInvalidate];
    }];
    [sessionDataTask resume];

}

+ (AMOAjaxRequest *)requestFromJson:(NSDictionary *)request andCallback:(NSString *)callback {
    if (request == nil) {
        return nil;
    }
    AMOAjaxRequest *ajaxRequest = [[AMOAjaxRequest alloc] initWithUrl:request[@"url"] andMethod:request[@"method"]
                                                              andBody:request[@"body"] andHeaders:request[@"headers"]
                                                          andCallback:callback];
    return ajaxRequest;
}

+ (void)respondWith:(AMOAuctionWebView *)webview andAjaxRequest:(AMOAjaxRequest *)ajax andUrlResponse:(NSHTTPURLResponse *)urlResponse
            andBody:(NSString *)body {
    NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
    NSDictionary *allHeaders = [urlResponse allHeaderFields];
    NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];
    for (NSString *key in allHeaders) {
        NSArray *value = @[allHeaders[key]];
        headers[key] = [value componentsJoinedByString:@","];
    }

    NSInteger statusCode = [urlResponse statusCode];
    if (statusCode > 299 && statusCode < 400) {
        statusCode = 204;
    }

    response[@"url"] = [[urlResponse URL] absoluteString];
    response[@"status"] = @(statusCode);
    response[@"headers"] = headers;
    response[@"body"] = body;

    [webview returnJs:ajax.callback data:response];
}

@end
