#import "OAPromiseTestSuite.h"
#import "OAPromise.h"

@implementation OAPromiseTestSuite


- (void) testAll
{
    OAPromise* finalPromise = [OAPromise promiseWithValue:nil];
    
    // Ways to combine:
    // 1. Parallel sequence.
    // 2. Serial sequence of operations. Later operations are dropped when 
    
    [self testPropertyAccessPerformance].then(^OAPromise *(id value) {
        NSLog(@"%@", value);
        return [self testThen];
    }, nil).then(^OAPromise *(id value) {
        NSLog(@"%@", value);
        return [self testError];
    }, nil).then(^OAPromise *(id value) {
        NSLog(@"%@", value);
        return [self testCompletion];
    }, nil).then(^OAPromise *(id value) {
        NSLog(@"%@", value);
        return finalPromise;
    }, nil).then(^OAPromise *(id value) {
        NSLog(@"Tests Completed.");
        return nil;
    }, nil).onError(^OAPromise *(NSError *error) {
        NSLog(@"Test Failure: %@", error.localizedDescription);
        return nil;
    }, nil);
    
    
    //    [[[[self delayedSuccess:@"1"] then:^OAPromise*(id value){
    //        NSLog(@"Got value #1: %@", value);
    //        return [self delayedSuccess:@"2"];
    //    }] then:^OAPromise *(id value) {
    //        NSLog(@"Got value #2: %@", value);
    //        return nil;
    //    }] error:^OAPromise *(NSError *err) {
    //        NSLog(@"Got error: %@", err.localizedDescription);
    //        return nil;
    //    }];
    
    // To test:
    //
    // 1. Errors.
    // 2. Queues.
    // 3. Callbacks attached when the value is already there.
    // 4. Duplicate callbacks create an exception.
    // 5. Progress
    // 6. Derived promise callbacks are never called and properly freed when previous promise's block returns nil.
    

}

- (OAPromise*) testPropertyAccessPerformance
{
    NSDate* start = [NSDate date];
    
    OAPromise* promise = [OAPromise promiseWithValue:@1];
    for (int i =0; i < 1000000; i++)
    {
        id value1 = promise.value;
        id value2 = promise.value;
        id value3 = promise.value;
        id value4 = promise.value;
        id value5 = promise.value;
        if (!value1) // making compiler happy
        {
            NSLog(@"value1 = %@, %@, %@, %@, %@", value1, value2, value3, value4, value5);
        }
    }
    
    NSDate* finish = [NSDate date];
    
    return [OAPromise promiseWithValue:[NSString stringWithFormat:@"Property access time: %f sec", [finish timeIntervalSinceDate:start]]];
}

- (OAPromise*) testThen
{
    OAPromise* promise = [OAPromise promise];
    NSMutableArray* list = [@[] mutableCopy];
    
    [[self delayedSuccess:@"2"] then:^OAPromise *(id value) {
        [list addObject:value];
        
        if ([list isEqual:@[@"1", @"2"]])
        {
            promise.value = [NSString stringWithFormat:@"%@: OK.", NSStringFromSelector(_cmd)];
        }
        else
        {
            promise.error = [self errorWithDescription:[NSString stringWithFormat:@"%@: results are not [1,2] => %@", NSStringFromSelector(_cmd), list]];
        }
        return nil;
    } queue:nil];
    
    [list addObject:@"1"];
    
    return promise;
}


- (OAPromise*) testError
{
    OAPromise* promise = [OAPromise promise];
    NSMutableArray* list = [@[] mutableCopy];
    
    [[self delayedError:@"2"] error:^OAPromise*(NSError* error) {
        [list addObject:error.localizedDescription];
        
        if ([list isEqual:@[@"1", @"2"]])
        {
            promise.value = [NSString stringWithFormat:@"%@: OK.", NSStringFromSelector(_cmd)];
        }
        else
        {
            promise.error = [self errorWithDescription:[NSString stringWithFormat:@"%@: results are not [1,2] => %@", NSStringFromSelector(_cmd), list]];
        }
        return nil;
    } queue:nil];
    
    [list addObject:@"1"];
    
    return promise;
}


- (OAPromise*) testCompletion
{
    OAPromise* promise = [OAPromise promise];
    NSMutableArray* list = [@[] mutableCopy];
    
    [[self delayedSuccess:@"2"] completion:^OAPromise *(id value, NSError * error) {
        [list addObject:value];
        NSAssert(error == nil, @"Error must be nil");
        
        if ([list isEqual:@[@"1", @"2"]])
        {
            promise.value = [NSString stringWithFormat:@"%@: OK.", NSStringFromSelector(_cmd)];
        }
        else
        {
            promise.error = [self errorWithDescription:[NSString stringWithFormat:@"%@: results are not [1,2] => %@", NSStringFromSelector(_cmd), list]];
        }
        return nil;
    } queue:nil];
    
    [list addObject:@"1"];
    
    return promise;
}

- (void) testAlreadyResolvedPromises
{
}

- (void) testNestedPromises
{
}

- (void) testAlreadyResolvedNestedPromises
{
}





#pragma mark - Helper Methods


- (NSError*) errorWithDescription:(NSString*)string
{
    return [NSError errorWithDomain:@"TestDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: string}];
}

- (OAPromise*) delayedSuccess:(NSString*)string
{
    OAPromise* promise = [OAPromise promise];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        promise.value = string;
    });
    
    return promise;
}

- (OAPromise*) delayedError:(NSString*)string
{
    OAPromise* promise = [OAPromise promise];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        promise.error = [self errorWithDescription:string];
    });
    
    return promise;
}


@end
