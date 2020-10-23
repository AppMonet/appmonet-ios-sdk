//
// Created by Jose Portocarrero on 10/26/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AMODeviceData : NSObject
@property (nonatomic, copy, nonnull) NSString *advertisingId;

- (NSDictionary *)buildData;
- (NSString *) getBundleName;
- (NSDictionary *)getAdvertisingInfo;
- (NSString *)getConnectionType;
@end
