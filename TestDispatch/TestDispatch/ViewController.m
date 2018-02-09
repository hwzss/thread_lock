//
//  ViewController.m
//  TestDispatch
//
//  Created by qwkj on 2018/2/6.
//  Copyright © 2018年 qwkj. All rights reserved.
//

#import "ViewController.h"
#import <libkern/OSAtomic.h>
#import <pthread.h>

#if __has_include(<os/lock.h>)
#import <os/lock.h>
#else
#error os_unfair_lock support on iOS (10.0 and later), macOS (10.12 and later), tvOS (10.0 and later), watchOS (3.0 and later)
#endif

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    testNSConditionLock();
}

void testNSConditionLock() {
    NSConditionLock *cLock = [[NSConditionLock alloc] initWithCondition:0];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程1 准备上锁");
        [cLock lockWhenCondition:1];
        NSLog(@"线程1 得到锁");
        NSLog(@"线程1 准备释放锁");
        [cLock unlockWithCondition:3];
        NSLog(@"线程1 解锁");
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSLog(@"线程2 准备上锁");
        if ([cLock tryLockWhenCondition:0]) {
            NSLog(@"线程2 得到锁");
            NSLog(@"线程2 准备释放锁");
            [cLock unlockWithCondition:1];
            NSLog(@"线程2 解锁");
        } else {
            NSLog(@"失败");
        }
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSLog(@"线程3 准备上锁");
        [cLock lockWhenCondition:3];
        NSLog(@"线程3 得到锁");
        NSLog(@"线程3 准备释放锁");
        [cLock unlockWithCondition:2];
        NSLog(@"线程3 解锁");
    });
}

void testNSLock() {
    NSLock *_nsLock = [[NSLock alloc]init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程1 准备上锁");
        [_nsLock lock];
        NSLog(@"线程1得到锁");
        sleep(3);
        NSLog(@"线程1 准备释放锁");
        [_nsLock unlock];
        NSLog(@"线程1 已释放锁");
    });
    sleep(1);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程2 准备上锁");
        [_nsLock lock];
        NSLog(@"线程2得到锁");
        NSLog(@"线程2 准备释放锁");
        [_nsLock unlock];
        NSLog(@"线程2 已释放锁");
    });
}

void testPthreadMutexT() {
    __block pthread_mutex_t pLock;
    pthread_mutex_init(&pLock, NULL);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程1 准备上锁");
        pthread_mutex_lock(&pLock);
        NSLog(@"线程1得到锁");
        sleep(3);
        NSLog(@"线程1 准备释放锁");
        pthread_mutex_unlock(&pLock);
        NSLog(@"线程1 已释放锁");
    });
    sleep(1);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程2 准备上锁");
        pthread_mutex_lock(&pLock);
        NSLog(@"线程2得到锁");
        NSLog(@"线程2 准备释放锁");
        pthread_mutex_unlock(&pLock);
        NSLog(@"线程2 已释放锁");
    });
}

void doLongRunningOpreation() {
#define LoingRuning_MAX  1
    for (int i = 0; i < 1000000000; i++) {
        @autoreleasepool {
#if LoingRuning_MAX
            int a = 0 + 1 + 2;
            int b = 0 + 1 + 2;
            a += a + b;
#else
            int a = 0 + 1 * 2;
            int b = 0 + 1 * 2;
            a += a * b;
#endif
        }
    }
#undef LoingRuning_MAX
}

#define test_in_queue(_name, _addotional_code) \
NSLog(@"%s %@求锁", __func__, _name);\
OSSpinLockLock(&osLock);\
NSLog(@"%s %@开始", __func__, _name);\
_addotional_code;\
NSLog(@"%s %@结束", __func__, _name);\
NSLog(@"%s %@放锁", __func__, _name);\
OSSpinLockUnlock(&osLock);\

void testOsSpinLockPriorityInversion() {
    __block OSSpinLock osLock = OS_SPINLOCK_INIT;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        test_in_queue(@"线程1", doLongRunningOpreation());
    });
    sleep(1);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        test_in_queue(@"线程2", nil);
    });
    //无法达到条件反转条件😂
}

void testOsSpinLock() {
    __block OSSpinLock osLock = OS_SPINLOCK_INIT;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{        
        test_in_queue(@"线程1", sleep(3));
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        test_in_queue(@"线程2", nil);
    });
}
#undef test_in_queue

void testOsspinLock_demo() {
    static os_unfair_lock  _lock = OS_UNFAIR_LOCK_INIT;
    os_unfair_lock_t  lock = &(_lock);
    //os_unfair_lock  _lock = OS_UNFAIR_LOCK_INIT; 用os_unfair_lock_t时记得注意持有锁_lock，防止野指针
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        os_unfair_lock_lock(lock);
        NSLog(@"第一个线程同步操作开始");
        sleep(3);
        NSLog(@"第一个线程同步操作结束");
        os_unfair_lock_unlock(lock);
    });
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(1);
        os_unfair_lock_lock(lock);
        NSLog(@"第二个线程同步操作开始");
        os_unfair_lock_unlock(lock);
    });
}

void testDispatchApply() {
    __block OSSpinLock _spinLock = OS_SPINLOCK_INIT;
    dispatch_queue_t _queue = dispatch_queue_create("com.qwkj.test.queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_apply(10, _queue, ^(size_t i) {
        NSString *_name = [NSString stringWithFormat:@"线程%zu", i];
        NSLog(@"%s %@求锁", __func__, _name);
        OSSpinLockLock(&_spinLock);
        NSLog(@"%s %@开始", __func__, _name);
        sleep(1);
        NSLog(@"%s %@结束", __func__, _name);
        NSLog(@"%s %@放锁", __func__, _name);
        OSSpinLockUnlock(&_spinLock);
    });
}

@end
