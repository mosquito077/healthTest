//
//  healthTestTests.m
//  healthTestTests
//
//  Created by mosquito on 2017/6/2.
//  Copyright © 2017年 mosquito. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ViewController.h"

@interface healthTestTests : XCTestCase
@property (nonatomic, strong) ViewController * testVC;
@end

@implementation healthTestTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    _testVC = [[ViewController alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
