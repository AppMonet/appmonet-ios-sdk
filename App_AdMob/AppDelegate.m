//
//  AppDelegate.m
//  App
//
//  Created by Jose Portocarrero on 11/28/17.
//  Copyright © 2017 AppMonet. All rights reserved.
//

#import "AppDelegate.h"
#import "AppMonet_Dfp/AppMonet.h"
@import GoogleMobileAds;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [[GADMobileAds sharedInstance] startWithCompletionHandler:nil];
    GADMobileAds.sharedInstance.requestConfiguration.testDeviceIdentifiers = @[ @"6b25b943ecef9a5f1a2b1142f7f90e87" ];
    AppMonetConfigurations *appMonetConfig = [AppMonetConfigurations configurationWithBlock:^(AppMonetConfigurations *builder) {
        builder.applicationId = @"qw9tp1sy";
    }];

    [AppMonet init:appMonetConfig withBlock:^(NSError *error) {
        NSLog(@"Initialized AppMonet SDK! - %@", error);
    }];
    [AppMonet testMode];
    return YES;
}

@end
