//
//  Call_C_Or_OC_MethodTests.m
//  TestDispatch
//
//  Created by qwkj on 2018/2/9.
//  Copyright © 2018年 qwkj. All rights reserved.
//

#import <XCTest/XCTest.h>

void doTest() {}

@interface Book : NSObject
- (void)doTest;
@end
@implementation Book
- (void)doTest {}
@end

@interface Call_C_Or_OC_MethodTests : XCTestCase
@end

@implementation Call_C_Or_OC_MethodTests

static int const FOR_NUM = 100000000;
- (void)testCallOCMethod {
    Book *abook = [[Book alloc] init];
    [self measureBlock:^{
        for (int i = 0; i < FOR_NUM; i++) {
            [abook doTest];
        }
    }];
}

- (void)testCallCMethod {
    [self measureBlock:^{
        for (int i = 0; i < FOR_NUM; i++) {
            doTest();
        }
    }];
}

@end
