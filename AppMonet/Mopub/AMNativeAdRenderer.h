//
//  AMNativeAdRenderer.h
//  AppMonet_Mopub
//
//  Created by Jose Portocarrero on 1/3/20.
//  Copyright © 2020 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPNativeAdRendererConfiguration;
@protocol MPNativeAdRendererSettings;

@interface AMNativeAdRenderer : NSObject
+ (MPNativeAdRendererConfiguration *)rendererConfigurationWithRendererSettings:(id <MPNativeAdRendererSettings>)rendererSettings;
@end



