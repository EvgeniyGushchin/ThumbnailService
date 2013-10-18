//
//  TSOperation.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSOperation.h"
#import "TSOperation+Private.h"

@interface TSOperation ()

@property (nonatomic, strong) NSMutableSet *completionBlocks;
@property (nonatomic, strong) NSMutableSet *cancelBlocks;

@property (nonatomic, getter = isFinished)  BOOL finished;
@property (nonatomic, getter = isExecuting) BOOL executing;
@property (nonatomic, getter = isStarted)   BOOL started;

@end

@implementation TSOperation {
    dispatch_queue_t callbackQueue;
    
    int completionCalled;
    int calledFromBlock;
    
    TSOperationThreadPriority threadPriority;
}

@synthesize completionBlocks = _completionBlocks;
@synthesize cancelBlocks = _cancelBlocks;

- (id) init
{
    self = [super init];
    if (self) {
        completionCalled = 0;
        calledFromBlock = 0;
        
        self.completionBlocks = [NSMutableSet new];
        self.cancelBlocks = [NSMutableSet new];
       
        self.operationQueue = dispatch_queue_create("TSOperationQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(self.operationQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
        
        callbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        __weak typeof (self) weakSelf = self;
        [super setCompletionBlock:^{
            [weakSelf onComplete];
        }];
    }
    return self;
}

- (void) dealloc
{
    dispatch_release(self.operationQueue);
    dispatch_release(callbackQueue);
}

#pragma mark - NSOperation cuncurrent support

- (void) start
{
    self.started = YES;
    if (![self isCancelled]) {
        self.executing = YES;
        dispatch_async(dispatch_get_global_queue([self queuePriorityFromThreadPriority:self.threadPriority], 0), ^{
            [self main];
            self.executing = NO;
            self.finished = YES;
        });
    } else {
        self.finished = YES;
    }
}

- (BOOL) isConcurrent
{
    return YES;
}

- (void) cancel
{
    if (self.started && !self.finished) {
        self.finished = YES;
    }

    [self onCancel];
    [super cancel];
}

- (dispatch_queue_priority_t)queuePriorityFromThreadPriority:(TSOperationThreadPriority)priority
{
    switch (priority) {
        case TSOperationThreadPriorityBackground:
            return DISPATCH_QUEUE_PRIORITY_BACKGROUND;
        default:
        case TSOperationThreadPriorityLow:
            return DISPATCH_QUEUE_PRIORITY_LOW;
        case TSOperationThreadPriorityNormal:
            return DISPATCH_QUEUE_PRIORITY_DEFAULT;
        case TSOperationThreadPriorityHight:
            return DISPATCH_QUEUE_PRIORITY_HIGH;
    }
}


#pragma mark - Thread priority

- (void) setThreadPriority:(TSOperationThreadPriority)priority
{
    threadPriority = priority;
}

- (TSOperationThreadPriority) threadPriority
{
    return threadPriority;
}

#pragma mark - Operation termination

- (void) onComplete
{
    if (![self isCancelled]) {
        [self callCompleteBlocks];
    }
}

- (void) onCancel
{
    [self callCancelBlocks];
}

#pragma mark - KVO notifications

- (void)setExecuting:(BOOL)isExecuting
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = isExecuting;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setFinished:(BOOL)isFinished
{
    [self willChangeValueForKey:@"isFinished"];
    _finished = isFinished;
    [self didChangeValueForKey:@"isFinished"];
}

#pragma mark - Callbacks

- (void) addCompleteBlock:(TSOperationCompletion)completionBlock
{
    dispatch_sync(self.operationQueue, ^{
        [_completionBlocks addObject:completionBlock];
    });
}

- (void) addCancelBlock:(TSOperationCompletion)cancelBlock
{
    dispatch_sync(self.operationQueue, ^{
        [_cancelBlocks addObject:cancelBlock];
    });
}

- (NSMutableSet *) completionBlocks
{
    __block NSMutableSet *set;
    dispatch_sync(self.operationQueue, ^{
        set = _completionBlocks;
    });
    return set;
}

- (NSMutableSet *) cancelBlocks
{
    __block NSMutableSet *set;
    dispatch_sync(self.operationQueue, ^{
        set = _cancelBlocks;
    });
    return set;
}

- (void) callCancelBlocks
{
    dispatch_async(callbackQueue, ^{
        for (TSOperationCompletion cancel in self.cancelBlocks) {
            cancel(self);
        }
    });
}

- (void) callCompleteBlocks
{
    dispatch_async(callbackQueue, ^{
        for (TSOperationCompletion complete in self.completionBlocks) {
            complete(self);
        }
    });
}

@end
