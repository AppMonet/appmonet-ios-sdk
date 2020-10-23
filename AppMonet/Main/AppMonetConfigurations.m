//
// Created by Jose Portocarrero on 10/26/17.
// Copyright (c) 2017 AppMonet. All rights reserved.
//

#import "AppMonetConfigurations.h"


@implementation AppMonetConfigurations

#pragma mark - Builder Methods

+ (instancetype)configurationWithBlock:(AppMonetConfigurationsBlock)block; {
    return [[self alloc] initWithBlock:block];
}

- (id)init; {
    return [self initWithBlock:nil];
}

- (id)initWithBlock:(AppMonetConfigurationsBlock)block {
    NSParameterAssert(block);
    self = [super init];
    if (self) {
        block(self);
    }
    return self;
}
@end
