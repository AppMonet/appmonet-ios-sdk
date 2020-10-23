//
//  AMOAjaxRequest.m
//  AppMonet
//
//  Created by Jose Portocarrero on 3/22/18.
//  Copyright © 2018 AppMonet. All rights reserved.
//

#import "AMOAjaxRequest.h"
@interface AMOAjaxRequest()

@end


@implementation AMOAjaxRequest{
}

- (instancetype)initWithUrl:(NSString *)url andMethod:(NSString *)method andBody:(NSString *)body
                 andHeaders:(NSDictionary *)headers andCallback:(NSString *)callback   {
    self = [super init];
    if (self != nil) {
        _url = url;
        _method = method;
        _body = body;
        _headers = headers;
        _callback = callback;
    }
    return self;
}



@end
