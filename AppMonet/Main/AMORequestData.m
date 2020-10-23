//
// Created by Jose Portocarrero on 11/5/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMORequestData.h"
#import "AMOAdServerAdRequest.h"
#import "AMOAdServerAdView.h"

@implementation AMORequestData
    

- (instancetype)initWithAdServerAdRequest:(id <AMServerAdRequest>)request andAdServerAdView:(id <AMOAdServerAdView>)adView {
    self = [super init];
    if (self != nil) {
        _birthday = request.getBirthday;
        _adUnitId = adView.getAdUnitId;
        _gender = request.getGender;
        _location = request.getLocation;
        _contentUrl = request.getContentUrl;
        _ppid = request.getPublisherProvidedId;
        _additional = [self buildAdditional:request];

        if (_ppid == nil) {
            _ppid = @"";
        }

        if (_contentUrl == nil) {
            _contentUrl = @"";
        }
    }
    return self;
}


- (NSMutableDictionary *)toDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"dob"] = _birthday.description;
    dictionary[@"adunit_id"] = _adUnitId;
    dictionary[@"gender"] = _gender;
    dictionary[@"url"] = _contentUrl;
    dictionary[@"ppid"] = _ppid;
    dictionary[@"kvp"] = _additional;

    if (_location != nil) {
        //todo -- figure this out.
    }


    return dictionary;
}

- (NSMutableDictionary *)buildAdditional:(id <AMServerAdRequest>)adRequest {
    NSMutableDictionary *output = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *bundle = adRequest.getCustomTargeting;

    for (NSString *key in bundle) {
        NSObject *value = bundle[key];
        NSString *serialized = [self serializeBundleObject:value];
        if (serialized != nil) {
            output[key] = serialized;
        }
    }
    return output;
}

- (NSString *)serializeBundleObject:(NSObject *)value {
    if (value == nil) {
        return nil;
    }
    if ([value isKindOfClass:NSString.class]) {
        return (NSString *) value;
    } else if ([value isKindOfClass:NSNumber.class]) {
        return [(NSNumber *) value stringValue];
    } else if ([value isKindOfClass:NSArray.class]) {
        NSMutableArray *items = [NSMutableArray array];
        for (NSObject *listItem in (NSArray *) value) {
            NSString *serialized = [self serializeBundleObject:listItem];
            if (serialized != nil) {
                [items addObject:serialized];
            }
        }
        return [items componentsJoinedByString:@","];
    }
    return nil;
}


@end
