//
// Created by Jose Portocarrero on 10/26/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

#ifndef Constants_h
#define Constants_h

extern NSString *const AMErrorDomain;
extern NSString *const AMAuctionURL;
extern NSString *const AMAuctionServer;
extern NSString *const AMSdkVersion;
extern NSString *const AMWebViewFooter;
extern NSString *const AMWebViewJSAgentGlobal;
extern NSString *const AMAuctionUrlKey;
extern NSString *const AMAuctionJsKey;
extern NSString *const AMAuctionHtmlKey;
extern NSString *const kAMCustomKwPrefixKey;
extern NSString *const kAMKwKeyPrefix;
extern NSString *const kAMPixelEventReplace;
extern NSString *const kAMAuctionManagerConfigUrl;

//Configurations
extern NSString *const AMSdkConfiguration;
extern NSString *const AMAdUnitTimeout;
extern NSString *const kAMORedirectUrl;

//JS Methods
extern NSString *const kAMFetchBids;
extern NSString *const kAMFetchBidsBlocking;
extern NSString *const kAMBidsUsed;
extern NSString *const kAMTrackRequest;
extern NSString *const kAMSetRequestData;

extern NSString *const kAMOWebViewJsCall;
extern NSString *const kAMOWebViewJsArgs;
extern NSString *const kAMOWebViewJsMethod;
extern NSString *const kAMOWebViewJsScheme;

// network conn. types
extern NSString *const AMNetworkUnknown;
extern NSString *const AMNetworkWifi;
extern NSString *const AMNetworkCell;
extern NSString *const AMNetworkNone;

extern NSString *const AMScriptMessageHandlerName;

extern CGFloat const kAMFlexibleAdSize;

extern NSString *const kAMLogPrefixInfo;
extern NSString *const kAMLogPrefixDebug;
extern NSString *const kAMLogPrefixWarn;
extern NSString *const kAMLogPrefixError;
extern NSString *const kAMJSLogPrefix;

//DFP
extern NSString *const kAMAdUnitKeywordKey;
extern NSString *const kAMAdSizeKey;
extern NSString *const kAMDefaultBidderKey;

//Mopub
extern NSString *const AMBidsKey;
extern NSString *const AMBidKey;

extern NSString *const AMEventPath;

//NSNotifications
extern NSString *const kAMDestroyNotification;
extern NSString *const kAMRespondNotification;
extern NSString *const kAMCleanUpBidsNotification;
extern NSString *const kAMBidsRemovedNotification;
extern NSString *const kAMBidsInvalidatedNotification;
extern NSString *const kAMDestroyHelperNotification;

extern NSString *const kAMBidNotificationKey;
extern NSString *const kAMRemoveCreativeNotificationKey;
extern NSString *const kAMDefaultExtrasLabel;

//bid error codes
extern NSString *const kAMOTestModeWarning;

//other
extern NSInteger kAMOInterstitialWidth;
extern NSInteger kAMOInterstitialHeight;

typedef enum {
    AMLogLevelAll = 0,
    AMLogLevelTrace = 1,
    AMLogLevelDebug = 2,
    AMLogLevelInfo = 3,
    AMLogLevelWarn = 4,
    AMLogLevelError = 5,
    AMLogLevelFatal = 6
} AMLogLevel;

void _AMLogInternal(AMLogLevel level, NSString *fmt, ...);

void AMSetLogLevel(AMLogLevel level);

void AMEnableLogging(BOOL enable);

NSString *logLevelToPrefix(AMLogLevel level);

AMLogLevel getSetLogLevel();


NSURL *eventURL(NSString *event, NSString *qs);

// logging macros
#define AMLog(level, fmt, ...) _AMLogInternal(level, fmt, ##__VA_ARGS__)
#define AMLogDebug(fmt, ...) AMLog(AMLogLevelDebug, fmt, ##__VA_ARGS__)
#define AMLogInfo(fmt, ...) AMLog(AMLogLevelInfo, fmt, ##__VA_ARGS__)
#define AMLogWarn(fmt, ...) AMLog(AMLogLevelWarn, fmt, ##__VA_ARGS__)
#define AMLogError(fmt, ...) AMLog(AMLogLevelError, fmt, ##__VA_ARGS__)
#define AMError(message) [NSError errorWithDomain:AMErrorDomain code:0 userInfo:nil]
#define AMErrorWithData(message, data) [NSError errorWithDomain:AMErrorDomain code:0 userInfo:data]
#define AMErrorWithCode(errorCode) [NSError errorWithDomain:AMErrorDomain code:errorCode userInfo:nil]


#endif /* Constants_h */

#define BASE_URL @"https://cdn.88-f.net"

