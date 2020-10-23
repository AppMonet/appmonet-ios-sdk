//
// Created by Jose Portocarrero on 2/13/20.
// Copyright (c) 2020 AppMonet. All rights reserved.
//

#import "AMODispatchState.h"


@implementation AMODispatchState

-(instancetype) init {
    if(self=[super init]){
       _isCancelled = NO;
    }
    return self;
}

@end