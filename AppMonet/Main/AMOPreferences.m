//
// Created by Jose Portocarrero on 10/31/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMOPreferences.h"
#import "AMOConstants.h"

@interface AMOPreferences ()
@property(nonatomic) NSNull *nullObj;
@end

@implementation AMOPreferences
- (instancetype)init {
    self = [super init];
    if (self != nil) {
        _preferences = [NSUserDefaults standardUserDefaults];
        _nullObj = [NSNull null];

    }
    return self;
}

- (void)setPreference:(NSString *)key boolValue:(BOOL)value {
    [_preferences setBool:value forKey:key];
    [_preferences synchronize];

}

- (void)setPreference:(NSString *)key stringValue:(NSString *)value {
    if ([value isEqual:_nullObj]) {
        AMLogWarn(@"key: %@  is NSNull. Not saving any values. Check config if this was intended to have a value.", key);
        return;
    }
    [_preferences setObject:value forKey:key];
    [_preferences synchronize];
}

- (void)setPreference:(NSString *)key dictValue:(NSDictionary *)value {
    [_preferences setObject:value forKey:key];
    [_preferences synchronize];
}

- (NSString *)getPref:(NSString *)key stringDefaultValue:(NSString *)defaultValue {
    NSObject *value = [_preferences objectForKey:key];
    if (!value) {
        return defaultValue;
    }
    if (![value isKindOfClass:[NSString class]]) {
        AMLogWarn(@"Invalid type stored at %@. Removing.", key);
        [_preferences removeObjectForKey:key];
        [_preferences synchronize];
        return defaultValue;
    }

    NSString *str = (NSString *) value;
    return ([str length] > 0) ? str : defaultValue;
}

- (BOOL)getPref:(NSString *)key boolDefaultValue:(BOOL)defaultValue {
    BOOL value = [_preferences boolForKey:key];
    return value;
}

- (NSDictionary *)getPref:(NSString *)key dictDefaultValue:(NSDictionary *)defaultValue {
    NSObject *anyValue = [_preferences objectForKey:key];
    if (!anyValue) {
        return defaultValue;
    }
    if (![anyValue isKindOfClass:[NSDictionary class]]) {
        AMLogWarn(@"Invalid type stored at %@. Removing.", key);
        [_preferences removeObjectForKey:key];
        [_preferences synchronize];
        return defaultValue;
    }
    return (NSDictionary *) anyValue;
}


@end
