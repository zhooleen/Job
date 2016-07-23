//
//  RTTestJob.m
//  Job
//
//  Created by lzhu on 7/23/16.
//  Copyright © 2016 redeight. All rights reserved.
//

#import "RTTestJob.h"

@implementation RTTestJob

+ (instancetype) positiveJob {
    RTTestJob *job = [[RTTestJob alloc] init];
    job.type = @"Positive";
    job.identifier = @"Test_111";
    job.parameters = @{@"id":@111};
    return job;
}

+ (instancetype) negativeJob {
    RTTestJob *job = [[RTTestJob alloc] init];
    job.type = @"Negative";
    job.identifier = @"Test_111";
    job.parameters = @{@"id":@111};
    return job;
}

- (void) executeInQueue:(dispatch_queue_t)queue withBlock:(void(^)(int status))block {
    [super executeInQueue:queue withBlock:^(int sta){
        if(sta == 0) { //execute successfully in super class
            //do the job in subclass
            sleep(4); //simulate time-consuming job
            int d = random() % 2;
            if(d == 0) {
                if([self.type isEqualToString:@"Positive"]) {
                    printf("execute success : +\n");
                } else {
                    printf("execute success : -\n");
                }
            }
            sta = d;
        }
        dispatch_async(queue, ^{
            block(sta);
        });
    }];
}

@end
