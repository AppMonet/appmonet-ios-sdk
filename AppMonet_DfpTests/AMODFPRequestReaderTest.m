//
//  AMODFPRequestReaderTest.m
//  AppMonet_DfpTests
//
//  Created by Jose Portocarrero on 4/23/20.
//  Copyright © 2020 AppMonet. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AMODFPRequestReader.h"
#import "AMOAdSize.h"
#import "AMOSdkManager.h"
#import "AMOBidManager.h"
#import "AMOBidResponse.h"
@import OCHamcrest;
@import OCMockito;
@import GoogleMobileAds;


@interface AMODFPRequestReaderTest : XCTestCase
@property(nonatomic, strong) GADCustomEventRequest *eventRequest;
@property(nonatomic, strong) AMOAdSize *adSize;
@end

@implementation AMODFPRequestReaderTest

- (void)setUp {
    _eventRequest = mock([GADCustomEventRequest class]);
    _adSize = mock([AMOAdSize class]);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExtractAdUnitIDWithKeyAsAdditionalParameter {
    [given(_eventRequest.additionalParameters) willReturn:@{@"__auid__": @"id"}];
    NSString *adUnitId = [AMODFPRequestReader extractAdUnitID:_eventRequest
                                               andServerLabel:@"" withServerValue:@"" andAdSize:anything()];
    assertThat(adUnitId, is(@"id"));
}

- (void)test_Given_Additional_Params_Is_Not_Present_And_ServerValue_is_Empty_Get_Ad_Size_As_AdUnit {
    AMOAdSize *adSize = [[AMOAdSize alloc] initWithWidth:@300 andHeight:@250];
    [given(_eventRequest.additionalParameters) willReturn:nil];
    NSString *adUnitId = [AMODFPRequestReader extractAdUnitID:_eventRequest
                                               andServerLabel:@"" withServerValue:@"" andAdSize:adSize];
    assertThat(adUnitId, is(@"300x250"));
}

- (void)test_Given_Additional_Params_Is_Empty_Do_Not_crash {
    AMOAdSize *adSize = [[AMOAdSize alloc] initWithWidth:@300 andHeight:@250];
    [given(_eventRequest.additionalParameters) willReturn:@{}];
    NSString *adUnitId = [AMODFPRequestReader extractAdUnitID:_eventRequest
                                               andServerLabel:@"" withServerValue:@"" andAdSize:adSize];
    assertThat(adUnitId, is(@"300x250"));
}

- (void)test_Given_Additional_Params_Is_Not_Present_And_ServerValue_Is_Not_Nil_And_It_Does_Not_Start_With_$_Sign_adunit_cpm_format {
    NSString *serverValue = @"test_interstitial@$100";
    NSString *adUnitId = [AMODFPRequestReader extractAdUnitID:nil
                                               andServerLabel:@"" withServerValue:serverValue andAdSize:anything()];
    assertThat(adUnitId, is(@"test_interstitial"));
}

- (void)test_Given_Additional_Params_Is_Not_Present_And_ServerValue_Is_Not_Nil_And_It_Does_Not_Start_With_$_Sign_normal_format {
    NSString *serverValue = @"only_ad_unit";
    AMOAdSize *adSize = [[AMOAdSize alloc] initWithWidth:@300 andHeight:@250];
    NSString *adUnitId = [AMODFPRequestReader extractAdUnitID:nil
                                               andServerLabel:@"" withServerValue:serverValue andAdSize:adSize];
    assertThat(adUnitId, is(serverValue));
}

- (void)test_Given_Additional_Params_Is_Not_Present_And_ServerValue_Is_Not_Nil_And_It_Starts_With_$_Sign {
    NSString *serverValue = @"$100";
    AMOAdSize *adSize = [[AMOAdSize alloc] initWithWidth:@300 andHeight:@250];
    NSString *adUnitId = [AMODFPRequestReader extractAdUnitID:nil
                                               andServerLabel:@"" withServerValue:serverValue andAdSize:adSize];
    assertThat(adUnitId, is(@"300x250"));
}

- (void)test_Given_ServerValue_Is_Empty_Or_Nil_Return_0_Cpm {
    assertThat([AMODFPRequestReader getCpm:@""], is(@0));
    assertThat([AMODFPRequestReader getCpm:nil], is(@0));
}

- (void)test_Given_ServerValue_Starts_With_$_Sign_Followed_By_A_Number {
    assertThat([AMODFPRequestReader getCpm:@"$5.20"], is(@([@"5.20" floatValue])));
}

- (void)test_Given_ServerValue_Starts_With_$_Sign_Followed_By_Not_A_Number {
    assertThat([AMODFPRequestReader getCpm:@"$anything"], is(@0));
}

- (void)test_Given_ServerValue_Has_AdUnitId_And_Cpm {
    NSNumber *cpm = [AMODFPRequestReader getCpm:@"test_adunit@$5.20"];
    NSNumber *expected = @([@"5.20" floatValue]);
    assertThat(cpm, is(expected));
}

- (void)test_Given_ServerValue_Has_AdUnitId_And_Cpm_Not_As_A_Number {
    NSNumber *cpm = [AMODFPRequestReader getCpm:@"test_adunit@$anything"];
    assertThat(cpm, is(@0));
}

- (void)test_Given_ServerValue_Is_Random_String_And_Not_A_Number_Return_0 {
    NSNumber *cpm = [AMODFPRequestReader getCpm:@"anything"];
    assertThat(cpm, is(@0));
}

- (void)test_Given_BidManager_Is_Nil_Return_Nil_BidResponse {
    AMOBidManager *sdkManager = mock([AMOSdkManager class]);
    AMOBidManager *bidManager = mock([AMOBidManager class]);
    [given(AMOSdkManager.get) willReturn:sdkManager];
    [given(AMOSdkManager.get.bidManager) willReturn:nil];
    AMOBidResponse *bid = [AMODFPRequestReader bidResponseFromMediation:_eventRequest andAdSize:_adSize andAdUnitID:@""
                                                            andCpmFloor:@0 andAdType:BANNER];
    XCTAssertNil(bid);
}

- (void)test_Given_There_Are_Not_Bids_Available_For_AdUnit_Return_Nil_BidResponse {
    __strong Class mockSdkManagerClass = mockClass([AMOSdkManager class]);
    stubSingleton(mockSdkManagerClass, get);
    AMOSdkManager *sdkManager = mock([AMOSdkManager class]);
    AMOBidManager *bidManager = mock([AMOBidManager class]);
    NSMutableArray *arr = [NSMutableArray array];
    [given(AMOSdkManager.get) willReturn:sdkManager];
    [given(AMOSdkManager.get.bidManager) willReturn:bidManager];
    [given([bidManager areBidsAvailableForAdUnit:@"" andAdSize:_adSize andFloorCpm:@0 andBidArrayReference:&arr andAdType:BANNER andShouldRequestMore:YES]) willReturn:@NO];
    AMOBidResponse *bid = [AMODFPRequestReader bidResponseFromMediation:_eventRequest andAdSize:_adSize andAdUnitID:@""
                                                              andCpmFloor:@0 andAdType:BANNER];
    XCTAssertNil(bid);
}



//- (void)test_Given_There_Are_Bids_Available_For_AdUnit_And_Is_Not_Attachable_Return_Nil_BidResponse {
//    AMOBidResponse *_validBid = mock([AMOBidResponse class]);
//    [given(_validBid.id) willReturn:@"valid"];
//    [given(_validBid.adm) willReturn:@"adm"];
//    [given(_validBid.nativeRender) willReturn:@(NO)];
//    [given(_validBid.bidder) willReturn:@"valid"];
//    
//    AMOSdkManager *sdkManager = mock([AMOSdkManager class]);
//
//    __strong Class mockSdkManagerClass = mockClass([AMOSdkManager class]);
//    stubSingleton(mockSdkManagerClass, get);
//    [given([AMOSdkManager get]) willReturn:sdkManager];
//
//    AMOBidManager *bidManager = mock([AMOBidManager class]);
//    [given(sdkManager.bidManager) willReturn:bidManager];
//
//    NSMutableArray *arr = [NSMutableArray array];
////    [given([bidManager getBidsForMediation:@"" andAdSize:_adSize andFloorCpm:@0 andAdType:BANNER andShouldIndicateRequest:YES]) willReturn:@[]];
//    [given([AMOSdkManager.get.bidManager areBidsAvailableForAdUnit:anything() andAdSize:_adSize andFloorCpm:anything() andBidArrayReference:&arr andAdType:BANNER andShouldRequestMore:anything()]) willReturnBool:YES];
//    AMOBidResponse *bid = [AMODFPRequestReader bidResponseFromMediation:_eventRequest andAdSize:_adSize andAdUnitID:@"" andAdType:BANNER];
//
//    XCTAssertNil(bid);
//}



@end
