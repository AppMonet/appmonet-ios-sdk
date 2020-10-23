//
// Created by Jose Portocarrero on 10/26/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMOConstants.h"

NSString *const AMErrorDomain = @"appmonet";
NSString *const AMAuctionURL = @"https://ads.appmonet.com";
NSString *const AMAuctionServer = @"dev.appmonet.com:32564";
NSString *const AMSdkVersion = @"ios-4.0.7";
NSString *const AMWebViewFooter = @"</script></head><body></body></html>";
NSString *const AMWebViewJSAgentGlobal = @"monet";
NSString *const AMAuctionUrlKey = @"auction_url";
NSString *const AMAuctionJsKey = @"auction_js";
NSString *const AMAuctionHtmlKey = @"mhtml";
NSString *const kAMCustomKwPrefixKey = @"mm_ckey_prefix";
NSString *const kAMKwKeyPrefix = @"mm_";
NSString *const kAMPixelEventReplace = @"__event__";
NSString *const kAMAuctionManagerConfigUrl = @"https://config.88-f.net";

//Configurations
NSString *const AMSdkConfiguration = @"amSdkConfiguration";
NSString *const AMAdUnitTimeout = @"d_adUnitTimeouts";
NSString *const kAMORedirectUrl = @"s_redirectUrl";

NSString *const kAMDefaultExtrasLabel = @"default";

//JS MEthods
NSString *const kAMFetchBids = @"fetchBids";
NSString *const kAMFetchBidsBlocking = @"fetchBidsBlocking";
NSString *const kAMBidsUsed = @"bidsUsed";
NSString *const kAMTrackRequest = @"trackRequest";
NSString *const kAMSetRequestData = @"setRequestData";

NSString *const kAMOWebViewJsCall = @"fn";
NSString *const kAMOWebViewJsArgs = @"args";
NSString *const kAMOWebViewJsMethod = @"method";
NSString *const kAMOWebViewJsScheme = @"monet";

// network conn. types
NSString *const AMNetworkUnknown = @"unknown";
NSString *const AMNetworkWifi = @"wifi";
NSString *const AMNetworkCell = @"cell";
NSString *const AMNetworkNone = @"none";

NSString *const kAMLogPrefix = @"<AppMonet:%@> %@";
NSString *const kAMLogPrefixInfo = @"info";
NSString *const kAMLogPrefixDebug = @"debug";
NSString *const kAMLogPrefixWarn = @"warn";
NSString *const kAMLogPrefixError = @"error";
NSString *const kAMJSLogPrefix = @"(js) %@";

// DFP
NSString *const kAMAdUnitKeywordKey = @"__auid__";
NSString *const kAMAdSizeKey = @"ad_size";
NSString *const kAMDefaultBidderKey = @"default";

//Mopub
NSString *const AMBidsKey = @"bids";
NSString *const AMBidKey = @"bid";

NSString *const AMEventPath = @"/hbx/";

CGFloat const kAMFlexibleAdSize = -1.0f;


//NSNotifications
NSString *const kAMDestroyNotification = @"__DESTROY__";
NSString *const kAMRespondNotification = @"helperRespond";
NSString *const kAMCleanUpBidsNotification = @"__CLEAN_BIDS__";
NSString *const kAMBidsRemovedNotification = @"__REMOVED_BIDS__";
NSString *const kAMBidsInvalidatedNotification = @"__INVALIDATE_BIDS__";
NSString *const kAMBidNotificationKey = @"bidNotificationKey";
NSString *const kAMRemoveCreativeNotificationKey = @"removeCreativeNotificationKey";
NSString *const kAMDestroyHelperNotification = @"__DESTROY_HELPER__";


//Bid error codes
NSString *const kAMOTestModeWarning = @"\n\n#######################################################################\n"
                                      "APPMONET TEST MODE IS ENABLED\n"
                                      "To disable remove [AppMonet testMode]\n"
                                      "Rendering test demand only"
                                      "\n#######################################################################\n";

NSInteger kAMOInterstitialWidth = 320;
NSInteger kAMOInterstitialHeight = 480;

static AMLogLevel AMActiveLogLevel = AMLogLevelDebug;
static BOOL AMAEnabledLogging = YES;

NSString *logLevelToPrefix(AMLogLevel level) {
    switch (level) {
        case AMLogLevelDebug:
            return kAMLogPrefixDebug;
        case AMLogLevelInfo:
            return kAMLogPrefixInfo;
        case AMLogLevelWarn:
            return kAMLogPrefixWarn;
        case AMLogLevelError:
            return kAMLogPrefixError;
        default:
            return kAMLogPrefixInfo;
    }
}

AMLogLevel getSetLogLevel() {
    return AMActiveLogLevel;
};

void AMSetLogLevel(AMLogLevel level) {
    AMActiveLogLevel = level;
}

void AMEnableLogging(BOOL enable) {
    AMAEnabledLogging = enable;
}

void _AMLogInternal(AMLogLevel level, NSString *fmt, ...) {
    // drop messages that aren't above the level
    if (level < AMActiveLogLevel || !AMAEnabledLogging) {
        return;
    }
    fmt = [NSString stringWithFormat:kAMLogPrefix, logLevelToPrefix(level), fmt];
    va_list args;
    va_start(args, fmt);
    NSLogv(fmt, args);
    va_end(args);

}
