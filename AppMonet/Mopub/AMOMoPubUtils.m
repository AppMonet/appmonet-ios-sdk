//
// Created by Jose Portocarrero on 1/9/20.
// Copyright (c) 2020 AppMonet. All rights reserved.
//

#import "AMOMoPubUtils.h"


@implementation AMOMoPubUtils

+ (NSString *)getKeywords:(NSDictionary *)localExtras {
    NSMutableString *buffer = [NSMutableString string];
    for (NSString *key in localExtras) {
        if ([localExtras[key] isKindOfClass:[NSString class]]) {
            [buffer appendString:key];
            [buffer appendString:@":"];
            [buffer appendString:localExtras[key]];
            [buffer appendString:@","];
        }
    }
    return buffer;
}

+ (NSMutableString *)mergeKeywords:(NSString *)viewKeywords withNewKeyWords:(NSString *)newKeywords {
    NSMutableDictionary *viewKVMap = [self keywordsToMap:viewKeywords];
    NSMutableDictionary *newKVMap = [self keywordsToMap:newKeywords];
    [viewKVMap addEntriesFromDictionary:newKVMap];
    return [[self getKeywords:(viewKVMap)] mutableCopy];
}

+ (NSMutableDictionary *)keywordsToMap:(NSString *)keyWords {
    NSMutableDictionary *kvMap = [NSMutableDictionary dictionary];
    NSArray *keyValueArr = [keyWords componentsSeparatedByString:@","];
    for (NSString *kv in keyValueArr) {
        NSArray *splitKV = [kv componentsSeparatedByString:@":"];
        if ([splitKV count] == 2) {
            kvMap[splitKV[0]] = splitKV[1];
        }
    }
    return kvMap;
}

@end