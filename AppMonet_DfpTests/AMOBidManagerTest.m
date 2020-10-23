//
//  AMOBidManagerTest.m
//  AppMonet_DfpTests
//
//  Created by Jose Portocarrero on 4/22/20.
//  Copyright © 2020 AppMonet. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AMOBidManager.h"
#import "AMOBidValidity.h"
#import "AMOBasicValidityCallback.h"
#import "AMOBidResponse.h"
#import "AMOAdViewPoolManager.h"
#import "AMOSdkManager.h"
#import "AMOAdSize.h"
@import OCHamcrest;
@import OCMockito;

@interface AMOBidManager (Testing)
@property(atomic, readwrite, strong) NSDictionary *bidderExpiration;
@property(atomic, readwrite, strong) NSDictionary *usedBids;
@property(atomic, readwrite, strong) NSDictionary *adUnitNameMapping;
@property(atomic, readwrite, strong) NSDictionary<NSString *, NSMutableArray *> *store;
@property(nonatomic, readwrite, strong) NSDictionary *seenBids;
@property(atomic, readwrite, strong) NSDictionary *bidIdsByAdView;

- (nonnull AMOBidResponse *)filterBidsFromQueue:(nullable NSMutableArray *)queue andBidValidity:(nonnull id <AMOBidValidity>)validator;

- (BOOL)renderWebViewExists:(AMOBidResponse *)bid;

- (NSString *)resolveAdUnitId:(NSString *)adUnitId;

- (void)cleanBidsForAdUnit:(NSString *)adUnit;

- (void)putStoreForAdUnit:(NSString *)adUnitId andQueue:(NSMutableArray *)store;

- (NSMutableArray *)getStoreForAdUnit:(NSString *)adUnitId;
@end

@interface AMOBidManagerTest : XCTestCase
@property(nonatomic, strong) AMOBidManager *bidManager;
@property(nonatomic, strong) AMOBidResponse *bid1;
@property(nonatomic, strong) AMOBidResponse *bid2;
@property(nonatomic, strong) AMOBidResponse *invalidBid;
@property(nonatomic, strong) AMOBidResponse *validBid;
@property(nonatomic, strong) AMOBasicValidityCallback *validityCallback;


@end

@implementation AMOBidManagerTest

- (void)setUp {
    _bidManager = [[AMOBidManager alloc] initWithExecutionQueue:dispatch_queue_create("com.monet.background.queue", DISPATCH_QUEUE_SERIAL)];
    _bidManager.bidderExpiration = @{ @"valid" : @100000000000000};
    _validityCallback = mock([AMOBasicValidityCallback class]);
    _bid1 = mock([AMOBidResponse class]);
    [given(_bid1.id) willReturn:@"bid1"];
    [given(_bid1.uuid) willReturn:@"uuid"];

    _bid2 = mock([AMOBidResponse class]);
    [given(_bid2.id) willReturn:@"bid2"];

    _invalidBid = mock([AMOBidResponse class]);
    [given(_invalidBid.adm) willReturn:nil];
    [given(_invalidBid.id) willReturn:@"valid"];

    _validBid = mock([AMOBidResponse class]);
    [given(_validBid.id) willReturn:@"valid"];
    [given(_validBid.adm) willReturn:@"adm"];
    [given(_validBid.nativeRender) willReturn:@(NO)];
    [given(_validBid.bidder) willReturn:@"valid"];
    [given(_validBid.cpm) willReturn:@2];
    __strong Class mockSdkManagerClass = mockClass([AMOSdkManager class]);
    stubSingleton(mockSdkManagerClass, get);
    AMOSdkManager *sdkManager = mock([AMOSdkManager class]);
    [given(AMOSdkManager.get) willReturn:sdkManager];

}

- (void)tearDown {
    _bidManager.usedBids = [NSDictionary dictionary];
    _bidManager.seenBids = [NSDictionary dictionary];
    _bidManager.store = [NSDictionary dictionary];
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_Given_Queue_Is_Nil_Then_Bid_Is_Nill {
    AMOBidResponse *bid = [_bidManager filterBidsFromQueue:nil andBidValidity:[[AMOBasicValidityCallback alloc] initWithBidManager:_bidManager]];
    XCTAssertNil(bid);
}

- (void)test_Given_Queue_Is_Empty_Then_Bid_Is_Nill {
    NSMutableArray *queue = [NSMutableArray array];
    AMOBidResponse *bid = [_bidManager filterBidsFromQueue:queue andBidValidity:[[AMOBasicValidityCallback alloc] initWithBidManager:_bidManager]];
    XCTAssertNil(bid);
}

- (void)test_Given_Queue_Has_Bids_And_They_Are_All_Valid_Then_Return_First_Valid_Bid {
    NSMutableArray *originalExpected = [@[_bid1] mutableCopy];
    NSMutableArray *queue = [@[_bid1, _bid2] mutableCopy];
    [given([_validityCallback isValid:anything()]) willReturnBool:YES];
    AMOBidResponse *bid = [_bidManager filterBidsFromQueue:queue andBidValidity:_validityCallback];
    assertThat([bid id], is([originalExpected[0] id]));
}

- (void)test_Given_First_Bid_Is_Invalid_And_Second_Bid_Is_Valid_Return_Second_Bid {
    NSMutableArray *queue = [@[_invalidBid, _validBid] mutableCopy];
    AMOBidResponse *bid = [_bidManager filterBidsFromQueue:queue
                                            andBidValidity:[[AMOBasicValidityCallback alloc] initWithBidManager:_bidManager]];
    assertThat([bid id], is([_validBid id]));
}

- (void)test_Given_Queue_Has_Bids_And_They_Are_All_Invalid_Then_Return_nil {
    NSMutableArray *queue = [@[_bid1, _bid2] mutableCopy];
    [given([_validityCallback isValid:anything()]) willReturnBool:NO];
    AMOBidResponse *bid = [_bidManager filterBidsFromQueue:queue andBidValidity:_validityCallback];
    XCTAssertNil(bid);
}

- (void)test_Given_Bid_Is_Not_Valid_Return_NO {
    BOOL isValid = [_bidManager isValid:_invalidBid];
    assertThatBool(isValid, is(@NO));
}

- (void)test_Given_Bid_Is_Not_Valid_Return_YES {
    BOOL isValid = [_bidManager isValid:_validBid];
    assertThatBool(isValid, is(@YES));
}

- (void)test_Given_Bid_Is_markedUsed_Then_It_Will_Be_Added_To_Used_Bids_Dictionary {
    assertThatBool([_bidManager.usedBids count] == 0, is(@YES));
    [_bidManager markUsed:_bid1];
    assertThatBool([_bidManager.usedBids count] == 1, is(@YES));
}

- (void)test_Given_AdUnitNameMapping_Contains_AdUnit_Return_Mapped_Value {
    _bidManager.adUnitNameMapping = @{@"adUnit": @"mapped_value"};
    NSString *mappedValue = [_bidManager resolveAdUnitId:@"adUnit"];
    assertThat(mappedValue, is(@"mapped_value"));
}

- (void)test_Given_AdUnitNameMapping_Does_Not_Contain_AdUnit_Return_Original_AdUnit {
    NSString *adUnit = [_bidManager resolveAdUnitId:@"adUnit"];
    assertThat(adUnit, is(@"adUnit"));
}

- (void)test_Given_AddBids_With_One_Invalid_Bid_Then_Store_Should_Be_Empty {
    [given(_invalidBid.adUnitId) willReturn:@"adUnitId"];
    NSArray *bids = @[_invalidBid];
    [_bidManager addBids:bids];

    assertThat(@([_bidManager.store count]), is(@0));
}


- (void)test_Given_AddBids_With_Valid_Bid_But_It_Was_Already_Seen_Return_And_Store_Should_Empty_Array {
    [given(_validBid.adUnitId) willReturn:@"adUnitId"];
    _bidManager.seenBids = [@{_validBid.id: _validBid.id} mutableCopy];
    NSArray *bids = @[_validBid];
    [_bidManager addBids:bids];
    assertThat(@([_bidManager.store count]), is(@1));
    assertThat(@([_bidManager.store[@"adUnitId"] count]), is(@0));
}

- (void)test_Given_AddBids_With_Valid_Bid_And_Is_Not_NativeRender_And_Not_NativeInvalidated_Store_Should_Contain_Bid {
    [given(_validBid.adUnitId) willReturn:@"adUnitId"];
    NSArray *bids = @[_validBid];
    [_bidManager addBids:bids];
    assertThat(@([_bidManager.seenBids count]), is(@1));
    assertThat(@([_bidManager.bidsById count]), is(@1));
    assertThat(@([_bidManager.store count]), is(@1));
    assertThat(@([_bidManager.store[@"adUnitId"] count]), is(@1));
}

- (void)test_Given_AddBids_With_Valid_Bid_And_Is__NativeRender_And_NativeInvalidated_Store_Should_Call_Additional_Methods {
    AMOBidResponse *bid = mock([AMOBidResponse class]);
    AMOAdViewPoolManager *pool = mock([AMOAdViewPoolManager class]);
    [given([pool containsView:anything()]) willReturn:@(YES)];
    [given(bid.id) willReturn:@"valid"];
    [given(bid.adm) willReturn:@"adm"];
    [given(bid.nativeRender) willReturn:@(YES)];
    [given(bid.bidder) willReturn:@"valid"];
    [given(bid.adUnitId) willReturn:@"adUnitId"];
    [given(bid.nativeInvalidated) willReturn:@(NO)];
    [given(bid.wvUUID) willReturn:@"wvuuid"];
    [given([AMOSdkManager.get adViewPoolManager]) willReturn:pool];
    NSArray *bids = @[bid];
    [_bidManager addBids:bids];
    assertThat(@([_bidManager.bidIdsByAdView[bid.wvUUID] count]), is(@(1)));
}

- (void)test_Given_cleanBids_Remove_Invalid_Bids {
    NSMutableArray *queue = [@[_validBid, _invalidBid] mutableCopy];
    _bidManager.store = @{@"adUnit" : queue};
    [_bidManager cleanBidsForAdUnit:@"adUnit"];
    assertThat(@([_bidManager.store[@"adUnit"] count]), is(@1));
}

- (void)test_Given_cleanBids_And_AdUnit_Is_Not_In_The_Store_just_return {
    NSMutableArray *queue = [@[_validBid, _invalidBid] mutableCopy];
    _bidManager.store = @{@"test" : queue};
    [_bidManager cleanBidsForAdUnit:@"adUnit"];
    assertThat(@([_bidManager.store[@"test"] count]), is(@2));
}

- (void)test_Given_CountBids_And_AdUnitId_Is_Nil_Return_Zero {
    NSNumber *bidsAmount = @([_bidManager countBids:nil]);
    assertThat(bidsAmount, is(@0));
}

- (void)test_Given_CountBids_And_Return_Amount_Of_Bids_For_AdUnit {
    NSMutableArray *queue = [@[_validBid, _invalidBid] mutableCopy];
    _bidManager.store = @{@"adUnit" :  queue};
    NSNumber *bidCountAdUnitNotThere =@([_bidManager countBids:@"test"]);
   NSNumber *bidCount = @([_bidManager countBids:@"adUnit"]);
    assertThat(bidCount, is(@2));
    assertThat(bidCountAdUnitNotThere, is(@0));
}

- (void)test_Given_NextBid_Is_Lower_Than_Floor_Then_Return_Nil{
    NSArray *queue = @[_validBid] ;
    _bidManager.store = @{@"test" : queue};
    AMOAdSize *adSize = mock([AMOAdSize class]);
    AMOBidResponse *bid = [_bidManager getBidForMediation:@"test" andAdSize:adSize andFloorCpm:@4 andAdType:BANNER andShouldIndicateRequest:NO];
    XCTAssertNil(bid);
}

- (void)test_Given_NextBid_Is_Higher_Or_Equal_Than_Floor_Then_Return_NextBid{
    NSArray *queue = @[_validBid] ;
    _bidManager.store = @{@"test" : queue};
    AMOAdSize *adSize = mock([AMOAdSize class]);
    AMOBidResponse *bid = [_bidManager getBidForMediation:@"test" andAdSize:adSize andFloorCpm:@2 andAdType:BANNER andShouldIndicateRequest:NO];
    assertThat(bid, is(_validBid));
}


@end
