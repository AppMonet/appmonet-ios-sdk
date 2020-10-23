//
// Created by Jose Portocarrero on 10/31/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AMOPreferences : NSObject
@property(nonatomic, readonly) NSUserDefaults *preferences;

- (instancetype)init;

- (void)setPreference:(NSString *)key boolValue:(BOOL)value;

- (void)setPreference:(NSString *)key stringValue:(NSString *)value;

- (void)setPreference:(NSString *)key dictValue:(NSDictionary *)value;

- (NSString *)getPref:(NSString *)key stringDefaultValue:(NSString *)defaultValue;

- (BOOL)getPref:(NSString *)key boolDefaultValue:(BOOL)defaultValue;

- (NSDictionary *)getPref:(NSString *)key dictDefaultValue:(NSDictionary *)defaultValue;

@end