//
//  LockTests.m
//  TestDispatch
//
//  Created by qwkj on 2018/2/9.
//  Copyright © 2018年 qwkj. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <libkern/OSAtomic.h>
#import <pthread.h>
#import <objc/objc-sync.h>

#if __has_include (<os/lock.h>)
#define Os_Unfair_Lock_Enabled 1
#import <os/lock.h>
#endif

@interface LockTests : XCTestCase

@end

@implementation LockTests

static int const FOR_NUM = 100000000;

#define _measeure(_code) \
[self measureBlock:^{\
for (int i = 0; i < FOR_NUM; i++) {\
    _code\
}\
}];

- (void)testOSSpinLock {
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    __block OSSpinLock _spinLock = OS_SPINLOCK_INIT;
    _measeure({
        OSSpinLockLock(&_spinLock);
        OSSpinLockUnlock(&_spinLock);
    });
#pragma clang diagnostic pop
}

#ifdef Os_Unfair_Lock_Enabled
- (void)testUnfairLock {
    os_unfair_lock_t _unfairLock = &OS_UNFAIR_LOCK_INIT;
    _measeure({
        os_unfair_lock_lock(_unfairLock);
        os_unfair_lock_unlock(_unfairLock);
    });
}
#endif

- (void)testDispatchSemaphore {
    dispatch_semaphore_t _semaphporeLock = dispatch_semaphore_create(1);
    _measeure({
        dispatch_semaphore_wait(_semaphporeLock, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_signal(_semaphporeLock);
    });
}

- (void)testPthreadMutexT {
    __block pthread_mutex_t _mutexLock;
    pthread_mutex_init(&_mutexLock, NULL);
    _measeure({
        pthread_mutex_lock(&_mutexLock);
        pthread_mutex_unlock(&_mutexLock);
    });
}

- (void)testNSLock {
    NSLock *_nsLock = [[NSLock alloc] init];
    _measeure({
        [_nsLock lock];
        [_nsLock unlock];
    });
}

- (void)testSyncronized {
    NSObject *_obLock = [[NSObject alloc] init];
    _measeure({
        objc_sync_enter(_obLock);
        objc_sync_exit(_obLock);
    })
}

#undef _measeure

@end
