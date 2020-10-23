//
// Created by Jose Portocarrero on 10/27/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

//
// Created by Nicholas Jacob on 1/20/17.
// Copyright (c) 2017 App Monet. All rights reserved.
//


#import <mach/vm_statistics.h>
#import <mach/mach_error.h>
#import <mach/host_info.h>
#import <mach/mach_host.h>
#import "AMOUtils.h"
#import "AMOConstants.h"
#import "AMODispatchState.h"

BOOL am_obj_isString(NSObject *obj) {
    return obj && [obj isKindOfClass:[NSString class]];
}

BOOL am_obj_isNumber(NSObject *obj) {
    return obj && [obj isKindOfClass:[NSNumber class]];
}

BOOL am_obj_isDictionary(NSObject *obj) {
    return obj && [obj isKindOfClass:[NSDictionary class]];
}

static bool AMVMStats(vm_statistics_data_t *const vmStats, vm_size_t *const pageSize) {
    kern_return_t kr;
    const mach_port_t hostPort = mach_host_self();

    if ((kr = host_page_size(hostPort, pageSize)) != KERN_SUCCESS) {
        AMLogError(@"host_page_size: %s", mach_error_string(kr));
        return false;
    }

    mach_msg_type_number_t hostSize = sizeof(*vmStats) / sizeof(natural_t);
    kr = host_statistics(hostPort,
            HOST_VM_INFO,
            (host_info_t) vmStats,
            &hostSize);
    if (kr != KERN_SUCCESS) {
        AMLogError(@"host_statistics: %s", mach_error_string(kr));
        return false;
    }
    return true;
}

uint64_t AMfreeMemory(void) {
    vm_statistics_data_t vmStats;
    vm_size_t pageSize;
    if (AMVMStats(&vmStats, &pageSize)) {
        return ((uint64_t) pageSize) * vmStats.free_count;
    }
    return 0;
}

uint64_t AMusableMemory(void) {
    vm_statistics_data_t vmStats;
    vm_size_t pageSize;
    if (AMVMStats(&vmStats, &pageSize)) {
        return ((uint64_t) pageSize) * (vmStats.active_count +
                vmStats.inactive_count +
                vmStats.wire_count +
                vmStats.free_count);
    }
    return 0;
}

@implementation AMOUtils


+ (NSString *)uuid {
    return [[NSUUID UUID] UUIDString];
}

+ (NSString *)toQueryString:(NSDictionary *)params {
    NSCharacterSet *urlCharSet = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSMutableArray *kvps = [NSMutableArray arrayWithCapacity:[params count]];
    for (NSString *k in params) {

        NSString *key;
        NSString *value;

        if (![params[k] isKindOfClass:[NSString class]]) {
            AMLogDebug(@"invalid argument passed to toQueryString: %@", params[k]);
            continue;
        }

        key = [k stringByAddingPercentEncodingWithAllowedCharacters:urlCharSet];
        value = [params[k] stringByAddingPercentEncodingWithAllowedCharacters:urlCharSet];

        [kvps addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
    }

    return [kvps componentsJoinedByString:@"&"];
}

+ (NSNumber *)asIntPixels:(NSNumber *)dips {
    CGFloat scale = [[UIScreen mainScreen] scale];
    return @([dips floatValue] * scale);
}

+ (id)parseJson:(NSData *)data {
    // convert to data

    if (!data) {
        return nil;
    }
    NSError *error = nil;

    id object = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
//    id object = [NSJSONSerialization mp_JSONObjectWithData:data options:NSJSONReadingMutableContainers clearNullObjects:YES error:nil];

    if (error) {
        AMLogError(@"Error parsing string to json");
        return nil;
    }

    return object;
}

+ (NSString *)getCustomEventSourceType:(AMOAdType)adType {
    NSString *adValueType = adTypeValueString(adType);
    return [NSString stringWithFormat:@"custom_event_%@", adValueType];
}

+ (NSString *)toJson:(NSObject *)data {
    NSError *error = nil;
    if (!data) {
        AMLogError(@"attempt to serparseJsonialize nil");
        return nil;
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
    if (error) {
        AMLogError(@"error stringifying: %@", [error localizedDescription]);
        return nil;
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+ (NSString *)encodeBase64:(NSString *)source {
    NSData *data = [source dataUsingEncoding:NSUTF8StringEncoding];
    return [data base64EncodedStringWithOptions:0];
}

+ (void)logFromJS:(NSString *)level message:(NSArray<NSString *> *)args {
    if (!level || !args) {
        return;
    }
    NSString *message = [args componentsJoinedByString:@" "];
    // figure out the correct log level to use
    if ([level isEqualToString:kAMLogPrefixInfo]) {
        AMLogInfo(kAMJSLogPrefix, message);
    } else if ([level isEqualToString:kAMLogPrefixDebug]) {
        AMLogDebug(kAMJSLogPrefix, message);
    } else if ([level isEqualToString:kAMLogPrefixWarn]) {
        AMLogWarn(kAMJSLogPrefix, message);
    } else if ([level isEqualToString:kAMLogPrefixError]) {
        AMLogError(kAMJSLogPrefix, message);
    }
}

+ (NSDictionary *)parseVastTracking:(NSString *)url withRegex:(NSRegularExpression *)regex {

    if ([url length] == 0) {
        return nil;
    }

    if (regex == nil) {
        return nil;
    }

    @autoreleasepool {
        NSMutableArray *arrayOfAllMatches = [[[NSArray alloc] initWithArray:[regex matchesInString:url options:0 range:NSMakeRange(0, [url length])]] mutableCopy];
        if ([arrayOfAllMatches count] == 0) {
            return nil;
        }
        NSTextCheckingResult *regexResult = arrayOfAllMatches[0];
        [arrayOfAllMatches removeAllObjects];
        if (regexResult && [regexResult rangeAtIndex:1].length != 0 && [regexResult rangeAtIndex:2].length != 0) {
            NSMutableDictionary *vastValues = [NSMutableDictionary dictionaryWithCapacity:2];
            NSString *trackingEvent = [[NSString alloc] initWithString:[url substringWithRange:[regexResult rangeAtIndex:1]]];
            NSString *trackingBidId = [[NSString alloc] initWithString:[url substringWithRange:[regexResult rangeAtIndex:2]]];
            vastValues[@"vastTrackingEvent"] = trackingEvent;
            vastValues[@"vastTrackingBidId"] = trackingBidId;
            return vastValues;
        }
        return nil;
    }
}

+ (NSNumber *)getCurrentMillis {
    return @((long long) ([[NSDate date] timeIntervalSince1970] * 1000.0));
}

+ (NSString *)hexStringForColor:(UIColor *)color {
      const CGFloat *components = CGColorGetComponents(color.CGColor);
      CGFloat r = components[0];
      CGFloat g = components[1];
      CGFloat b = components[2];
      NSString *hexString=[NSString stringWithFormat:@"%02X%02X%02X", (int)(r * 255), (int)(g * 255), (int)(b * 255)];
      return hexString;
}

+ (AMODispatchState *)cancelableDispatchAfter:(dispatch_time_t)when inQueue:(dispatch_queue_t)queue withState:(AMODispatchState *)cancelState withBlock:(void (^)(void))block {
    void (^newBlock)(void) = ^void() {
        if (cancelState.isCancelled == NO) {
            block();
        }
    };
    dispatch_after(when, queue, newBlock);
    return cancelState;
}

@end
