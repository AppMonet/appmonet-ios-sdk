//
// Created by Jose Portocarrero on 3/4/20.
// Copyright (c) 2020 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AMORemoteConfiguration : NSObject

- (instancetype)initWithApplicationId:(NSString *)applicationId;

- (void)getConfiguration:(BOOL)forceServer completion:(void (^)(NSString *response))completion;
@end