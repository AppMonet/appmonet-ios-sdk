//
//  AMOAjaxRequest.h
//  AppMonet
//
//  Created by Jose Portocarrero on 3/22/18.
//  Copyright © 2018 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AMOAjaxRequest : NSObject
@property(nonatomic) NSString *url;
@property(nonatomic) NSString *method;
@property (nonatomic) NSString *body;
@property(nonatomic) NSDictionary *headers;
@property(nonatomic) NSString *callback;

- (instancetype)initWithUrl:(NSString *)url andMethod:(NSString *)method andBody:(NSString *)body
                 andHeaders:(NSDictionary *)headers andCallback:(NSString *)callback;
@end
