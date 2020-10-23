//
// Created by Jose Portocarrero on 1/9/20.
// Copyright (c) 2020 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AMOMoPubUtils : NSObject
+ (NSString *)getKeywords:(NSDictionary *)localExtras;

+ (NSMutableString *)mergeKeywords:(NSString *)viewKeywords withNewKeyWords:(NSString *)newKeywords;
@end