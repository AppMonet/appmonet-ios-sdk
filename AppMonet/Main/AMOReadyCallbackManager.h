//
//  AMOReadyCallbackManager.h
//  AppMonet
//
//  Created by Jose Portocarrero on 4/3/20.
//  Copyright © 2020 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMOReadyCallbackManager<T> : NSObject

- (void)executeReady:(id)instance;

- (void)onReady:(void (^)(id instance))block;

@end

NS_ASSUME_NONNULL_END
