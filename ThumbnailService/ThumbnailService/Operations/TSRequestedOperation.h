//
//  TSRequestedOperation.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 18.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSOperation.h"

@interface TSRequestedOperation : TSOperation

- (void) addRequest:(TSRequest *)request andWait:(BOOL)wait;
- (void) removeRequest:(TSRequest *)request andWait:(BOOL)wait;

- (void) enumerationRequests:(void(^)(TSRequest *anRequest))enumerationBlock onQueue:(dispatch_queue_t)queue;
- (BOOL) shouldCacheOnDisk;
- (BOOL) shouldCacheInMemory;

- (void) updatePriority;

@end


