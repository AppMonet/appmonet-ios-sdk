//
// Created by Jose Portocarrero on 10/26/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AMOAuctionWebView.h"
#import "AMOBaseManager.h"
#import "AMODeviceData.h"
#import "AMOPreferences.h"
#import "AMOAppMonetContext.h"
#import "AMOBidManager.h"
#import "AMOAdServerWrapper.h"
#import "AMOAppMonetBidder.h"
#import "AMOAdViewPoolManager.h"
#import "AMOConstants.h"
#import "AppMonetConfigurations.h"
#import "AMOHoldingContainer.h"
#import "AMOReadyCallbackManager.h"
#import "AMOMediationManager.h"
#import "AMOAddBidsManager.h"
#import "AMOUtils.h"

@interface AMOBaseManager ()
@property(nonatomic) AMOReadyCallbackManager *auctionManagerReadyCallback;
@end

@implementation AMOBaseManager {
    NSString *_applicationId;
    AMOHoldingContainer *_rootContainer;
    id <AMOAdServerWrapper> adServerWrapper;
}
static BOOL testModeEnabled = NO;

- (id)initWithApplicationId:(AppMonetConfigurations *)appMonetConfigurations andAdServerWrapper:(id <AMOAdServerWrapper>)adServerWrapper andBlock:(InitializationBlock)block {
    if (self = [super init]) {
        if (@available(iOS 11, *)) {
            [self checkRequiredInitParameters:appMonetConfigurations.applicationId];
            _addBidsManager = [[AMOAddBidsManager alloc] init];
            _auctionManagerReadyCallback = [[AMOReadyCallbackManager alloc] init];
            self.backgroundQueue = dispatch_queue_create("com.monet.background.queue", DISPATCH_QUEUE_SERIAL);
            _rootContainer = [[AMOHoldingContainer alloc] initWithFrame:CGRectMake(-1000, -1000, 0, 0)];
            _sdkConfigurations = [[[self getSdkConfigurations] copy] mutableCopy];
            _applicationId = appMonetConfigurations.applicationId;
            _appMonetContext = [[AMOAppMonetContext alloc] init];
            _appMonetContext.applicationId = _applicationId;
            _appMonetContext.defaultDomain = appMonetConfigurations.defaultDomain;
            _bidManager = [[AMOBidManager alloc] initWithExecutionQueue:_backgroundQueue];
            _mediationManager = [[AMOMediationManager alloc] initWithSdkManager:self andBidManager:_bidManager];
            _deviceData = [[AMODeviceData alloc] init];
            _adViewPoolManager = [[AMOAdViewPoolManager alloc] initWithRootContainer:_rootContainer];
            _preferences = [[AMOPreferences alloc] init];
            _block = block;
            _auctionManager = [[AMOAuctionManager alloc] initWithDeviceData:_deviceData andBidManager:_bidManager
                                                         andAppMonetContext:_appMonetContext andPreferences:_preferences andAdViewPoolManager:_adViewPoolManager
                                                          andExecutionQueue:_backgroundQueue andDelegate:self andRootContainer:_rootContainer];
            _appMonetBidder = [[AMOAppMonetBidder alloc] initWithAuctionManager:_auctionManager andAdServerWrapper:adServerWrapper];
            _adServerWrapper = adServerWrapper;
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIApplication sharedApplication] keyWindow] addSubview:_rootContainer];
            });
            if (testModeEnabled) {
                [self testMode];
            }
//            [self attachRootContainerToUIWindow];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(attachToRootContainer:) name:@"rootContainer_attach" object:nil];
            [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:AMSdkConfiguration
                                                       options:NSKeyValueObservingOptionNew context:NULL];
        } else {
            AMLogError(@"IOS version not supported. Only iOS 11+");
        }
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqual:AMSdkConfiguration]) {
        _sdkConfigurations = [[_preferences getPref:AMSdkConfiguration
                                   dictDefaultValue:(_sdkConfigurations) ? _sdkConfigurations
                                           : [[NSDictionary dictionary] mutableCopy]] mutableCopy];
    }
}

- (void)indicateRequest:(NSString *)adUnitId withAdSize:(AMOAdSize *)adSize forAdType:(AMOAdType)adType andFloorCpm:(NSNumber *)floorCpm {
    [self logState];
    [self.auctionManager indicateRequest:adUnitId withAdSize:adSize forAdType:adType andFloorCpm:floorCpm];
}

- (void)indicateRequestAsync:(NSString *)adUnitId andTimeout:(NSNumber *)timeout andAdSize:(AMOAdSize *)adSize
                   andAdType:(AMOAdType)adType andFloorCpm:(NSNumber *)floorCpm withValueBlock:(AMValueBlock)block {
    [_auctionManager indicateRequestAsync:adUnitId andTimeout:timeout andAdSize:adSize andAdType:adType
                              andFloorCpm:floorCpm withValueBlock:block];
}

- (void)attachToRootContainer:(NSNotification *)notification {
    NSString *messagePayload = notification.object;
    AMOAdView *view = [_adViewPoolManager getAdViewByUuid:messagePayload];
    [_rootContainer addSubview:(id) view.adViewContainer];
    AMLogDebug(messagePayload);
}

- (void)preFetchBids:(NSArray<NSString *> *)adUnitIds {
    AMLogDebug(@"prefetching bids invoked");
    [self.appMonetBidder prefetchBids:adUnitIds];
}

- (NSDictionary *)getSdkConfigurations {
    if (_sdkConfigurations == nil) {
        _sdkConfigurations = [[_preferences getPref:AMSdkConfiguration dictDefaultValue:[NSDictionary dictionary]] mutableCopy];
    }
    AMLogDebug(@"getting sdk configurations", [_sdkConfigurations description]);
    return _sdkConfigurations;
}

- (void)testMode {
    [_auctionManagerReadyCallback onReady:^void(AMOAuctionManager *auctionManager) {
        [auctionManager testMode];
        AMLogWarn(@"\n\n########################################################################\n"
                  "APP MONET TEST MODE ENABLED. USE ONLY DURING DEVELOPMENT."
                  "\n########################################################################\n");
        self.isTestMode = YES;
    }];
}

+ (void)testModeEnabled {
    testModeEnabled = YES;
}

+ (void)enableVerboseLogging:(BOOL)state {
    AMEnableLogging(state);
    AMLogDebug(@"enable verbose logging: %s", state ? "true" : "false");
}

- (void)auctionManager:(AMOAuctionManager *)auctionManager started:(NSError *)error {
    if (error == nil) {
        [self setupIntervalExecution];
        [_addBidsManager executeReady];
        [_auctionManagerReadyCallback executeReady:_auctionManager];
    }


    @try {
        _block(error);
    } @catch (NSException *exp) {
        AMLogError(@"Error calling initialization block - %@", exp);
    }
}

- (void)checkRequiredInitParameters:(NSString *)applicationId {
    if (applicationId == nil) {
        NSException *exception = [NSException exceptionWithName:@"InternalInconsistencyException"
                                                         reason:@"applicationId is required." userInfo:nil];
        @throw exception;
    }
}

- (void)setupIntervalExecution {
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _backgroundQueue);

    if (!timer) {
        AMLogWarn(@"could not start cleaning timer. Non-fatal");
        return;
    }
    _cleanTimer = timer;
    uint64_t timerDelay = 7000 * NSEC_PER_MSEC;
    dispatch_source_set_timer(
            timer,
            dispatch_time(DISPATCH_TIME_NOW, timerDelay),
            timerDelay, (1ull * NSEC_PER_SEC) / 10);

    dispatch_source_set_event_handler(timer, ^{
        [_bidManager cleanBids];
    });
    dispatch_resume(timer);
}


-(void)trackTimeoutEvent:(NSString *) adUnitId withTimeout:(NSNumber *)timeout {
    NSNumber *currentTime = [AMOUtils getCurrentMillis];
    [_auctionManagerReadyCallback onReady:^void(AMOAuctionManager *auctionManager){
        [auctionManager trackEvent:@"addbids_nofill" withDetail:@"timeout" andKey:adUnitId
                          andValue:timeout andCurrentTime:currentTime];

    }];
}

- (void)logState {
    AMLogDebug(@"\n<<<[DNE|SdkManager State Dump]>>>");
    [self.bidManager logState];
    [self.adViewPoolManager logState];
    AMLogDebug(@"<<<[END|SdkManager State Dump]>>>\n");
}

- (void)stopTimer {
    if (!_cleanTimer) {
        return;
    }

    dispatch_source_cancel(_cleanTimer);
    _cleanTimer = nil;
}

- (void)dealloc {
    [self stopTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end


