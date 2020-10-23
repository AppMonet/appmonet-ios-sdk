#import <Foundation/Foundation.h>

@class AMOAdServerAdRequest;
@class AMOAuctionRequest;
@class AMOAdSize;
@protocol AMServerAdRequest;
typedef enum {
    kAMInterstitial,
    kAMBanner,
    kAMNative
} AMType;

@protocol AMOAdServerWrapper <NSObject>
- (id <AMServerAdRequest>)newAdRequest:(AMOAuctionRequest *)auctionRequest;

- (id <AMServerAdRequest>)newAdRequest:(AMOAuctionRequest *)auctionRequest andAdType:(AMType)type;

- (id <AMServerAdRequest>)newAdRequest;

- (AMOAdSize *)newAdSize:(NSNumber *)width andHeight:(NSNumber *)height;

@end