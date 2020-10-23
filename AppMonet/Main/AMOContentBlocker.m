//
//  AMOContentBlocker.m
//  AppMonet
//
//  Created by Jose Portocarrero on 3/31/20.
//  Copyright © 2020 AppMonet. All rights reserved.
//

#import "AMOContentBlocker.h"

@implementation AMOContentBlocker

+ (NSArray<NSString *> *)blockedResources:(NSString *)url {
    NSMutableString *domain = [url mutableCopy];
    if (url && [url containsString:@"http"]) {
        NSURL *nsUrl = [NSURL URLWithString:url];
        domain = [[nsUrl host] mutableCopy];
    }
    NSMutableSet<NSString *> *sBlockedResources = [NSMutableSet set];
    NSString *blockedMraidURLString = [NSString stringWithFormat:@"http.?://%@/mraid.js", domain];
    NSString *blockedFaviconURLString = [NSString stringWithFormat:@"http.?://%@/favicon.ico", domain];

    [sBlockedResources addObject:blockedMraidURLString];
    [sBlockedResources addObject:blockedFaviconURLString];
    return [sBlockedResources allObjects];
}

+ (NSDictionary *)blockPatternFromResource:(NSString *)resource {
    if (resource == nil) {
        return nil;
    }

    return @{@"action": @{@"type": @"block"},
            @"trigger": @{@"url-filter": resource}};
}

+ (NSString *)blockedResourcesList:(NSString *)url {
    NSString *blockedResourcesList = nil;
    NSInteger blockedResourcesListCount = 0;
    NSArray *blockedResources = [AMOContentBlocker blockedResources:url];

    blockedResourcesListCount = [blockedResources count];

    NSMutableArray *patterns = [NSMutableArray arrayWithCapacity:blockedResourcesListCount];
    [[AMOContentBlocker blockedResources:url] enumerateObjectsUsingBlock:^(NSString *resource, NSUInteger idx, BOOL *_Nonnull stop) {
        NSDictionary *blockPattern = [AMOContentBlocker blockPatternFromResource:resource];
        if (blockPattern != nil) {
            [patterns addObject:blockPattern];
        }
    }];

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:patterns options:0 error:&error];
    blockedResourcesList = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    return blockedResourcesList;
}

@end
