//
//  AMOBasicValidityCallback.h
//  AppMonet
//
//  Created by Jose Portocarrero on 12/7/17.
//  Copyright © 2017 AppMonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMOBidValidity.h"

@class AMOBidManager;

@interface AMOBasicValidityCallback : NSObject<AMOBidValidity>

- (instancetype)initWithBidManager:(AMOBidManager *)bidManager;
@end
