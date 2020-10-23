//
// Created by Jose Portocarrero on 9/5/19.
// Copyright (c) 2019 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface AMOMonetSchemaHandler : NSObject <WKURLSchemeHandler, WKURLSchemeTask>
@property(nonatomic, strong) NSURLResponse *response;
@property(nonatomic, strong) NSDictionary *vastTracking;
@property(nonatomic, strong) NSRegularExpression *regex;
@end