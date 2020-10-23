//
// Created by Jose Portocarrero on 10/26/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AppMonetConfigurations;

typedef void(^AppMonetConfigurationsBlock)(AppMonetConfigurations *configuration);

/*
  This provides the sdk the configurations it requires in order to initialize.
  <p/>
  Example of how to use.
  <pre>
  AppMonetConfigurations *appMonetConfig = [AppMonetConfigurations
    configurationWithBlock:^(AppMonetConfigurations *builder){
    builder.applicationId = <application_id_string>;
  }];
  </pre>
 */
@interface AppMonetConfigurations : NSObject

/*
 Holds the application id value given by the application.
 */
@property(nonatomic, readwrite, strong) NSString *applicationId;

/*
 This is to set a default url domain to be used until remote configuration is fetched.
 */
@property(nonatomic, readwrite, strong) NSString *defaultDomain;

@property(nonatomic, readwrite) BOOL disableBannerListener;


+ (instancetype)configurationWithBlock:(AppMonetConfigurationsBlock)block;

- (id)initWithBlock:(AppMonetConfigurationsBlock)block NS_DESIGNATED_INITIALIZER;

@end
