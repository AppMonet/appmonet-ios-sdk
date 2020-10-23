//
// Created by Jose Portocarrero on 10/26/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMODeviceData.h"
#import "AMOConstants.h"

#import <mach/mach.h>
#import <ifaddrs.h>
#import <sys/utsname.h>
#include <sys/sysctl.h>
#include <mach-o/dyld.h>
#include <mach-o/nlist.h>
#import <arpa/inet.h>
#import<CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
@import NetworkExtension;
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreLocation/CoreLocation.h>
#import <AdSupport/AdSupport.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

@implementation AMODeviceData
    
-(id)init {
     if (self = [super init])  {
       self.advertisingId = @"";
     }
     return self;
}

- (NSDictionary *)buildData {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    @try {
        dict[@"device"] = self.getDeviceData;
        dict[@"app"] = self.getApplicationData;
        dict[@"location"] = self.getLocationData;
        dict[@"network"] = self.getNetworkInfo;
        dict[@"screen"] = self.getScreenData;
        dict[@"locale"] = [[NSLocale preferredLanguages] firstObject];
        dict[@"os"] = self.getOSData;
        dict[@"advertising"] = self.getAdvertisingInfo;
    } @catch (NSException *exception) {

    }
    return dict;
}
    
- (NSArray *)getSkAdNetwork{
    NSMutableArray *skAdNetworkItems = [NSMutableArray array];
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    if(infoDict == nil){
        return skAdNetworkItems;
    }
    NSArray* adNetworkItems = [infoDict objectForKey:@"SKAdNetworkItems"];
    if(adNetworkItems == nil){
        return skAdNetworkItems;
    }
    for(NSDictionary* item in adNetworkItems){
        NSString *skAdNetworkIdentifier = item[@"SKAdNetworkIdentifier"];
        if(skAdNetworkIdentifier != nil){
            [skAdNetworkItems addObject:skAdNetworkIdentifier];
        }
    }
    return skAdNetworkItems;
}

// TODO implement this ... looking at js interface for now.
- (NSDictionary *)getDeviceData {
    UIDevice *device = [UIDevice currentDevice];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"manufacturer"] = @"Apple Inc.";
    dict[@"os_version"] = device.systemVersion;
    
    // c version
    struct utsname sysinfo;
    uname(&sysinfo);
    dict[@"rawModel"] = [NSString stringWithCString:sysinfo.machine encoding:NSUTF8StringEncoding];
    return dict;
}

- (NSDictionary *)getAdvertisingInfo {
    ASIdentifierManager *adManager = [ASIdentifierManager sharedManager];
    self.advertisingId = adManager.advertisingIdentifier.UUIDString;
    return @{
            @"isTrackingEnabled": @(adManager.isAdvertisingTrackingEnabled),
            @"advertisingId": self.advertisingId,
    };
}

- (NSDictionary *)getApplicationData {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSBundle *mainBundle = [NSBundle mainBundle];
    dict[@"version"] = [mainBundle infoDictionary][@"CFBundleShortVersionString"];
    dict[@"build"] = [mainBundle infoDictionary][(NSString *) kCFBundleVersionKey];
    dict[@"bundle"] = [mainBundle bundleIdentifier];
    dict[@"minSdkVersion"] = @(__IPHONE_OS_VERSION_MIN_REQUIRED);
    dict[@"name"] = [mainBundle objectForInfoDictionaryKey:@"CFBundleName"];
    dict[@"skadnetwork"] = [self getSkAdNetwork];
    NSString *idfv = [[UIDevice.currentDevice identifierForVendor] UUIDString];
    if(idfv != nil){
        dict[@"idfv"] = idfv;
    }
    return dict;
}

- (NSDictionary *)getLocationData {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways
            || [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedWhenInUse)
            && ![CLLocationManager locationServicesEnabled]) {
        return dict;
    }

    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    if (locationManager == nil) {
        return dict;
    }


    CLLocation *lastKnownLocation = [locationManager location];
    if (lastKnownLocation == nil) {
        return dict;
    }

    dict[@"lat"] = @(lastKnownLocation.coordinate.latitude);
    dict[@"long"] = @(lastKnownLocation.coordinate.longitude);
    dict[@"accuracy"] = @((lastKnownLocation.verticalAccuracy + lastKnownLocation.horizontalAccuracy) / 2);
    locationManager = nil;
    lastKnownLocation = nil;
    return dict;
}

- (NSDictionary *)getNetworkInfo {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];

    @try {
        CTCarrier *carrier = [netInfo subscriberCellularProvider];
        dict[@"mcc"] = carrier.mobileCountryCode ? carrier.mobileCountryCode : @"0";
        dict[@"mnc"] = carrier.mobileNetworkCode ? carrier.mobileNetworkCode : @"0";
        dict[@"carrier"] = carrier.carrierName ? carrier.carrierName : @"unknown";

    } @catch (NSException *exception) {
        AMLog(AMLogLevelError, @"unable to fetch carrier data");
    }
    @try{
        dict[@"connection"] = [self getConnectionType];
    } @catch (NSException *exception){
        AMLog(AMLogLevelError, @"unable to fetch connection type");
    }

    @try {
        dict[@"cell_type"] = [self getNetworkType:netInfo];
        dict[@"sim_country"] = netInfo.subscriberCellularProvider.isoCountryCode;
    } @catch (NSException *exception){
        AMLog(AMLogLevelError, @"unable to fetch tel/network data");
    }

    return dict;
}

- (NSString *)getConnectionType {
    SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithName(NULL, "8.8.8.8");
    SCNetworkReachabilityFlags flags;

    BOOL success = SCNetworkReachabilityGetFlags(ref, &flags);
    CFRelease(ref);

    if (!success) {
        return AMNetworkUnknown;
    }

    BOOL isConnected = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL needsConn = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL isNetReachable = (isConnected && !needsConn);

    if (!isNetReachable) {
        return AMNetworkNone;
    }

    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        return AMNetworkCell;
    }

    return AMNetworkWifi;
}

- (NSDictionary *)getScreenData {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    @try {
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        int screenWidth = (int) screenRect.size.width;
        int screenHeight = (int) screenRect.size.height;
        int density = (int) [[UIScreen mainScreen] scale];
        NSString *resolution = [NSString stringWithFormat:@"%ix%i", screenHeight, screenWidth];
        dict[@"resolution"] = resolution;
        dict[@"density"] = @(density);
        dict[@"height"] = @(screenHeight);
        dict[@"width"] = @(screenWidth);
    } @catch (NSException *exception) {

    }
    return dict;
}

- (NSDictionary *)getOSData {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    @try {
        NSOperatingSystemVersion systemVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
        NSString *version = [NSString stringWithFormat:@"%@.%@.%@", @(systemVersion.majorVersion),
                                                       @(systemVersion.minorVersion), @(systemVersion.patchVersion)];
        dict[@"name"] = @"iOS";
        dict[@"version"] = version;
        dict[@"build"] = self.getBuild;
    } @catch (NSException *exception) {
        return nil;
    }
    return dict;
}

- (NSString *)getBuild {
    NSString *ctlKey = @"kern.osversion";
    NSString *buildValue;
    size_t size = 0;
    if (sysctlbyname([ctlKey UTF8String], NULL, &size, NULL, 0) != -1) {
        char *machine = calloc(1, size);
        sysctlbyname([ctlKey UTF8String], machine, &size, NULL, 0);
        NSString *ctlValue = [NSString stringWithCString:machine encoding:[NSString defaultCStringEncoding]];
        free(machine);
        buildValue = ctlValue;
    }
    return buildValue;
}

- (NSString *)getBundleName {
    return [[NSBundle mainBundle] bundleIdentifier];
}

- (NSString *)getNetworkType: (CTTelephonyNetworkInfo *)telephonyInfo
{
    NSString *technologyString = telephonyInfo.currentRadioAccessTechnology;

    if ([technologyString isEqualToString:CTRadioAccessTechnologyLTE]) {
        return @"4g";
        // LTE (4G)
    } else if([technologyString isEqualToString:CTRadioAccessTechnologyWCDMA]){
        return @"3g";
        // 3G
    } else if([technologyString isEqualToString:CTRadioAccessTechnologyEdge]) {
        return @"2g";
        // EDGE (2G)
    }
    return @"undefined";
}

@end
