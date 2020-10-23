//
// Created by Jose Portocarrero on 9/5/19.
// Copyright (c) 2019 AppMonet. All rights reserved.
//

#import "AMOMonetSchemaHandler.h"
#import "AMOConstants.h"
#import "AMOUtils.h"

@implementation AMOMonetSchemaHandler {
}
@synthesize request;

- (instancetype)init {
    self = [super init];
    if (self) {
        _regex = [[NSRegularExpression alloc] initWithPattern:@"monet://vast/(?:v2/)?([^/]+)/?([^/]+)?"
                                                      options:NSRegularExpressionCaseInsensitive error:nil];
    }
    return self;
}

- (void)webView:(WKWebView *)webView startURLSchemeTask:(AMOMonetSchemaHandler *)urlSchemeTask {
    NSMutableURLRequest *newRequest = [urlSchemeTask.request mutableCopy];
    _response = [[NSURLResponse alloc] initWithURL:[NSURL URLWithString:@"about:blank"] MIMEType:nil expectedContentLength:0 textEncodingName:nil];
    [urlSchemeTask didReceiveResponse:_response];
    [urlSchemeTask didReceiveData:[NSData data]];
    [urlSchemeTask didFinish];
//    [self.client URLProtocol:self didReceiveResponse:_response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
//    [self.client URLProtocol:self didLoadData:[NSData data]];
//    [self.client URLProtocolDidFinishLoading:self];
    _response = nil;
    _vastTracking = [AMOUtils parseVastTracking:newRequest.URL.absoluteString withRegex:_regex];
    AMLogDebug(urlSchemeTask.request.URL.absoluteString);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"vastEvent" object:nil userInfo:_vastTracking];
}

- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask {

}

@end
