//
//  AMOBidRendererTest.m
//  AppMonet_DfpTests
//
//  Created by Jose Portocarrero on 4/23/20.
//  Copyright © 2020 AppMonet. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AMOBidRenderer.h"
#import "AMOBidResponse.h"
#import "AMOAdServerAdapter.h"
#import "AMOSdkManager.h"
#import "AMOBidManager.h"
#import "AMOAdViewPoolManager.h"
#import "AMOAdView.h"
#import "AMOAdSize.h"
#import "AMOAppMonetViewLayout.h"
@import OCHamcrest;
@import OCMockito;

@interface AMOBidRendererTest : XCTestCase
@property (nonatomic, strong) AMOBidResponse *bid;
@property (nonatomic, strong) AMOAdSize *adSize;
@property (nonatomic, strong) id <AMOAdServerAdapter> delegate;
@property (nonatomic, strong) AMOSdkManager* mockSdkManager;
@property (nonatomic, strong) AMOBidManager* bidManager;
@property (nonatomic, strong) AMOAuctionManager * auctionManager;
@property (nonatomic, strong) AMOAdViewPoolManager *adViewPoolManager;
@property (nonatomic, strong) AMOAdView *adView;

@end

@implementation AMOBidRendererTest

- (void)setUp {
    __strong Class mockSdkManagerClass = mockClass([AMOSdkManager class]);
    _bid = mock([AMOBidResponse class]);
    _delegate = mockProtocol(@protocol(AMOAdServerAdapter));
    _mockSdkManager = mock([AMOSdkManager class]);
    _bidManager = mock([AMOBidManager class]);
    _auctionManager = mock([AMOAuctionManager class]);
    _adViewPoolManager = mock([AMOAdViewPoolManager class]);
    _adView = mock([AMOAdView class]);
    stubSingleton(mockSdkManagerClass, get);
    [given([AMOSdkManager get]) willReturn:_mockSdkManager];
    [given([_mockSdkManager bidManager]) willReturn:_bidManager];
    [given([_mockSdkManager auctionManager]) willReturn:_auctionManager];
    [given([_mockSdkManager adViewPoolManager]) willReturn:_adViewPoolManager];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_Given_SdkManager_Is_Nil_Return_Nil_View_Layout {
    AMOAppMonetViewLayout *view = [AMOBidRenderer renderBid:_bid andAdSize:_adSize andAdServerAdapter:_delegate ];
    XCTAssertNil(view);
}

-(void)test_Given_Bid_Is_Invalid_Return_Nil_And_Verify_TrackEvent_Is_called {
    [given ([_bidManager isValid:anything()]) willReturnBool:NO];
    [AMOBidRenderer renderBid:_bid andAdSize:_adSize andAdServerAdapter:_delegate ];
    [verifyCount(_auctionManager, times(1)) trackEvent:is(@"bidRenderer") withDetail:is(@"invalid_bid") andKey:anything() andValue:anything() andCurrentTime:anything()];
}

- (void)test_Given_Bid_Is_Valid_And_AdView_Is_Nil_Return_Nil_And_Verify_Track_Event_Is_Called {
    [given ([_bidManager isValid:anything()]) willReturnBool:YES];
    [given([_adViewPoolManager requestWithBid:anything()]) willReturn:nil];
    [given ([_bidManager isValid:anything()]) willReturnBool:YES];
    [AMOBidRenderer renderBid:_bid andAdSize:_adSize andAdServerAdapter:_delegate ];
    [verifyCount(_auctionManager, times(1)) trackEvent:is(@"bidRenderer") withDetail:is(@"null_view") andKey:anything() andValue:anything() andCurrentTime:anything()];
}


- (void)test_Given_Bid_Is_Valid_And_AdView_Is_Not_Null_If_AdView_Is_Not_Loaded_Call_Load {
    [given ([_bidManager isValid:anything()]) willReturnBool:YES];
    [given([_adViewPoolManager requestWithBid:anything()]) willReturn:_adView];
    [given(_adView.getLoaded) willReturnBool:NO];
    [AMOBidRenderer renderBid:_bid andAdSize:_adSize andAdServerAdapter:_delegate ];
    [verifyCount(_adView, times(1)) load];
}


-(void) test_Given_AdView_Is_Not_Null_Make_Sure_Setup_Methods_Are_Called_For_Rendering {
    [given ([_bidManager isValid:anything()]) willReturnBool:YES];
    [given([_adViewPoolManager requestWithBid:anything()]) willReturn:_adView];
    [given(_adView.getLoaded) willReturnBool:NO];
    
    [AMOBidRenderer renderBid:_bid andAdSize:_adSize andAdServerAdapter:_delegate ];
    [verifyCount(_delegate, times(1)) setAdView:anything()];
    [verifyCount(_adView, times(1)) setBid:anything()];
    [verifyCount(_adView, times(1)) setTrackingBid:anything()];
    [verifyCount(_adView, times(1)) setState:AD_RENDERED andEventDelegate:anything()];
    [verifyCount(_adView, times(1)) inject:anything()];
    [verifyCount(_bidManager, times(1)) markUsed:anything()];
}

-(void) test_Given_AdView_Is_Not_Nil_And_A_Valid_AdSize_Is_Passed_And_FlexSize_Is_True_AdView_Resize_Is_Called {
    [given ([_bidManager isValid:anything()]) willReturnBool:YES];
    [given([_adViewPoolManager requestWithBid:anything()]) willReturn:_adView];
    [given(_adView.getLoaded) willReturnBool:YES];
    [given(_bid.flexSize) willReturnBool:YES];
    [AMOBidRenderer renderBid:_bid andAdSize:[[AMOAdSize alloc] initWithWidth:@300 andHeight:@250] andAdServerAdapter:_delegate];
    [verifyCount(_adView, times(1)) resize:anything()];
}

-(void) test_Given_Everything_Went_Well_We_Should_Get_The_AdView_Parent_AppMonetViewLayout {
    AMOAppMonetViewLayout *mockLayout = mock([AMOAppMonetViewLayout class]);
    [given ([_bidManager isValid:anything()]) willReturnBool:YES];
    [given([_adViewPoolManager requestWithBid:anything()]) willReturn:_adView];
    [given(_adView.adViewContainer) willReturn:mockLayout];
    AMOAppMonetViewLayout *view = [AMOBidRenderer renderBid:_bid andAdSize:_adSize andAdServerAdapter:_delegate];
    assertThat(view, is(mockLayout));
}


@end
