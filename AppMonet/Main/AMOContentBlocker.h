//
//  AMOContentBlocker.h
//  AppMonet
//
//  Created by Jose Portocarrero on 3/31/20.
//  Copyright © 2020 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMOContentBlocker : NSObject
+ (NSString *)blockedResourcesList:(NSString *)url;

@end

NS_ASSUME_NONNULL_END
