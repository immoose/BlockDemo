//
//  main.m
//  BlockDemo
//
//  Created by Yifeng Li on 5/11/13.
//  Copyright (c) 2013 Yifeng LI. All rights reserved.
//

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[])
{
    
    @autoreleasepool {
        // 1. NSLog
        NSLog(@"Hello, World!");
        
        // 2. block NSLog
        void (^aBlock)(void) = ^(void) {
            NSLog(@"Hello world");
        };
        aBlock();
        
        // 3. declare first
        void (^bBlock)(void) = 0;
        bBlock = ^(void) {
            NSLog(@"Hello world");
        };
        bBlock();
        
        // 4. block array
        void (^blocks[2])(void) = {
            ^(void) {
                NSLog(@"This is block 1!");
            },
            ^(void) {
                NSLog(@"This is block 2!");
            }
        };
        blocks[0]();
        blocks[1]();
        
        // 5. block alloc on stack, follow is error?
        dispatch_block_t cblock;
        BOOL x = YES;
        if (x) {
            cblock = ^{
                NSLog(@"true");
            };
        } else {
            cblock = ^{
                NSLog(@"false");
            };
        }
        cblock();
        
        // 6. edit var in block
        // use static or __block
//        int global = 100;
        __block int blockLocal = 100;
        static int staticLocal = 100;
        void (^dBlock)(void) = ^(void) {
//            global++;      // raise error
            blockLocal++;
            staticLocal++;
        };
        dBlock();
        NSLog(@"blockLocal:%d, staticLocal:%d", blockLocal, staticLocal);
        
        // 7. block recursion
        // use static block or __block block
        void (^eBlock)(int) = 0;
        static void (^const staticBlock)(int) = ^(int i) {
            if (i > 0) {
                NSLog(@">> static %d", i);
                staticBlock(--i);
            }
        };
        eBlock = staticBlock;
        eBlock(5);
        
        __block void(^blockBlock)(int) = 0;
        blockBlock = ^(int i) {
            if (i > 0) {
                NSLog(@">> block %d", i);
                blockBlock(--i);
            }
        };
        blockBlock(5);
        
    }
    
    // 8. dispatch queue / multi-thread
    dispatch_queue_t queue = dispatch_queue_create("Study Block", NULL);
    int length = 100;
    static BOOL flag = NO;
    dispatch_async(queue, ^{
        int sum = 0;
        for (int i = 0; i < length; ++i) {
            sum += i;
        }
        NSLog(@">>Sum:%d", sum);
        flag = YES;
    });
    while (!flag);
    dispatch_release(queue);
    
    
    // 9. semaphore / 线程间同步,生产-消费模式 / FIFO
    __block dispatch_semaphore_t sem = dispatch_semaphore_create(0);     // 初始资源为0 (must >= 0)
    dispatch_queue_t aqueue = dispatch_queue_create("Study Block", NULL);
    dispatch_async(aqueue, ^{
        int sum = 0;
        for (int i = 0 ; i < 100; ++i) {
            sum += i;
        }
        NSLog(@">>sum2:%d", sum);
        // add 1 resource
        dispatch_semaphore_signal(sem);
    });
    // wait for the sem; until resource is ready;
    // decrease 1 resource
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    dispatch_release(sem);
    dispatch_release(aqueue);
    
    // 10. FIFO semaphore
    // task 1 earlier than task 2
    __block int sum = 0;
    __block dispatch_semaphore_t bsem = dispatch_semaphore_create(0);
    __block dispatch_semaphore_t taskSem = dispatch_semaphore_create(0);
    dispatch_queue_t bqueue = dispatch_queue_create("Study Block", NULL);
    dispatch_block_t task1 = ^(void) {
        int s = 0;
        for (int i = 0; i < 100; ++i) {
            s += i;
        }
        sum = s;
        NSLog(@">>after add: %d", sum);
        dispatch_semaphore_signal(taskSem);
    };
    dispatch_block_t task2 = ^(void) {
        dispatch_semaphore_wait(taskSem, DISPATCH_TIME_FOREVER);
        int s = sum;
        for (int i = 0; i < 100; ++i) {
            s -= i;
        }
        sum = s;
        NSLog(@">>after subtract:%d", sum);
        dispatch_semaphore_signal(bsem);
    };
    dispatch_async(bqueue, task1);
    dispatch_async(bqueue, task2);
    dispatch_semaphore_wait(bsem, DISPATCH_TIME_FOREVER);
    dispatch_release(taskSem);
    dispatch_release(bsem);
    dispatch_release(bqueue);
    
    
    // 11. dispatch recursion
    // use `dispatch_apply(size_t iterations, dispatch_queue_t queue, void(^block)(size_t));`
    // 求和是并行的
    dispatch_queue_t cqueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    __block int csum = 0;
    int clength = 100;
    dispatch_apply(clength, cqueue, ^(size_t i) {
        csum += (int)i;
    });
    NSLog(@">>sum:%d", csum);
    dispatch_release(cqueue);
    
    
    // 12. dispatch group
    __block int dSum = 0;
    __block dispatch_semaphore_t taskdSem = dispatch_semaphore_create(0);
    dispatch_queue_t dQueue = dispatch_queue_create("Study Block", NULL);
    dispatch_group_t group = dispatch_group_create();
    dispatch_block_t dTask1 = ^(void) {
        int s = 0;
        for (int i = 0; i < 100; ++i) {
            s += i;
        }
        dSum = s;
        NSLog(@">> after add: %d", dSum);
        dispatch_semaphore_signal(taskdSem);
    };
    dispatch_block_t dTask2 = ^(void) {
        dispatch_semaphore_wait(taskdSem, DISPATCH_TIME_FOREVER);
        int s = dSum;
        for (int i = 0; i < 100; ++i){
            s -= i;
        }
        dSum = s;
        NSLog(@">> after substract: %d", dSum);
    };
    dispatch_group_async(group, dQueue, dTask1);
    dispatch_group_async(group, dQueue, dTask2);
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    dispatch_release(taskdSem);
    dispatch_release(dQueue);
    dispatch_release(group);
    
    return 0;
}
