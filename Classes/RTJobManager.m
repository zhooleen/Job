#import "RTJobManager.h"

@interface RTJobManager ()

@property (strong, nonatomic) NSMutableArray<NSString *> *keysQueue;

@property (strong, nonatomic) NSMutableDictionary<NSString*, NSMutableArray<RTJob*>*> *jobMap;

@property (assign, nonatomic) BOOL running;

@property dispatch_queue_t exeQueue;

@property (strong, nonatomic) NSMutableArray *savedNotifications;

@property (strong, nonatomic) NSMutableArray *clearNotifications;

@end

@implementation RTJobManager

- (instancetype) init {
    self = [super init];
    if(self) {
        self.keysQueue = [NSMutableArray array];
        self.jobMap = [NSMutableDictionary dictionary];
        self.running = NO;
        self.exeQueue = dispatch_queue_create("com.redeight.JobQueue", NULL); // 串行queue
        self.savedNotifications = [NSMutableArray array];
        self.clearNotifications = [NSMutableArray array];
    }
    return self;
}

+ (instancetype) sharedManager {
    static dispatch_once_t once;
    static RTJobManager *mgr;
    dispatch_once(&once, ^{
        mgr = [[RTJobManager alloc] init];
    });
    return mgr;
}

#pragma mark - PUBLIC

- (void) start {
    if(!self.running) {
        [self unarchive];
    }
}

- (void) addJob:(RTJob*)job {
    dispatch_async(self.exeQueue, ^{
        NSMutableArray *jobs = self.jobMap[job.identifier];
        if(jobs) {
            if(!job.repeative && [self findSameJob:job] != nil) {
                return;
            }
            if(job.cancellable) {
                RTJob *j = [self findInverseJob:job];
                if(j) {
                    [self removeJob:j];
                    return;
                }
            }
            [jobs addObject:job];
            //printf("Add Job : %s\n", [job.type UTF8String]);
        } else {
            jobs = [NSMutableArray arrayWithObject:job];
            [self.jobMap setObject:jobs forKey:job.identifier];
            [self.keysQueue addObject:job.identifier];
            //printf("Add Job : %s\n", [job.type UTF8String]);
        }
        if(self.running == NO) {
            [self restart];
        }
    });
}

- (void) save {
    [self archive];
}

- (void) clear {
    dispatch_async(self.exeQueue, ^{
        [self.keysQueue removeAllObjects];
        [self.jobMap removeAllObjects];
        self.running = NO;
    });
}

- (void) saveJobsWhenPostNotification:(NSString *)notificationName {
    if(![self.savedNotifications containsObject:notificationName]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save) name:notificationName object:nil];
        [self.savedNotifications addObject:notificationName];
    }
}

- (void) clearJobsWhenPostNotification:(NSString *)notificationName {
    if(![self.clearNotifications containsObject:notificationName]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clear) name:notificationName object:nil];
        [self.clearNotifications addObject:notificationName];
    }
}

#pragma mark - Private

- (RTJob*) findSameJob:(RTJob*)job {
    NSMutableArray *jobs = self.jobMap[job.identifier];
    if(jobs) {
        for (RTJob *j in jobs) {
            if([job isEqual:j]) {
                //printf("FindSameJob %s\n", [job.identifier UTF8String]);
                return j;
            }
        }
    }
    return nil;
}
       
- (RTJob*) findInverseJob:(RTJob*)job {
    NSMutableArray *jobs = self.jobMap[job.identifier];
    if(jobs) {
        for (RTJob *j in jobs) {
            if([job isInverse:j] && j.executing == NO) {
                //printf("findInverseJob %s\n", [job.identifier UTF8String]);
                return j;
            }
        }
    }
    return nil;
}

- (void) restart {
    if(self.running) {
        return;
    }
    if(self.keysQueue.count) {
        for(NSString *key in self.keysQueue) {
            NSArray *array = self.jobMap[key];
            for(RTJob *job in array) {
                job.retryTimes = 2;
            }
        }
        [self next];
    }
}

- (void) next {
    dispatch_async(self.exeQueue, ^{
        //printf("Next\n");
        self.running = YES;
        if([self hasValidJob]) {
            NSString *key = self.keysQueue[0];
            RTJob *job = self.jobMap[key][0];
            //printf("Fetch JOB : %s\n", [job.type UTF8String]);
            if(job.retryTimes == 0) {
                [self.keysQueue removeObject:key];
                [self.keysQueue addObject:key];
                [self next];
                return;
            }
            [self executeJob:job];
        } else {
            self.running = NO;
            //printf("No Jobs.\n");
        }
    });
}

- (void) executeJob:(RTJob*)job {
    [job executeInQueue:self.exeQueue withBlock:^(int status) {
        if(!self.running) {
            return;
        }
        if(status == 0) {
            //printf("Finish Job : %s\n", [job.type UTF8String]);
            [self removeJob:job];
        } else if([self shouldCancelJob:job withStatus:status]) {
#warning TODO post cancel notification her
            [self removeJob:job];
        } else {
            [self.keysQueue removeObject:job.identifier];
            [self.keysQueue addObject:job.identifier];
            RTJob *inverseJob = [self findInverseJob:job];
            if(inverseJob) {
                [self removeJob:job];
                [self removeJob:inverseJob];
            }
        }
        [self next];
    }];
}

- (void) removeJob:(RTJob*)job {
    if(job == nil) {
        return;
    }
    //printf("Remove Job : %s\n", [job.type UTF8String]);
    NSMutableArray *array = self.jobMap[job.identifier];
    if(array.count > 1) {
        [array removeObject:job];
    } else {
        [self.jobMap removeObjectForKey:job.identifier];
        [self.keysQueue removeObject:job.identifier];
        if(self.keysQueue.count == 0) {
            self.running = NO;
        }
    }
}

- (BOOL) shouldCancelJob:(RTJob*)job withStatus:(int)status {
    NSTimeInterval interval = [NSDate date].timeIntervalSince1970;
    BOOL cancel = ((interval - job.createdTime) > 7*24*60*60);
    return cancel || (status == job.errorCode);
}

- (BOOL) hasValidJob {
    for (NSString *key in self.keysQueue) {
        RTJob *job = self.jobMap[key][0];
        if(job.retryTimes != 0) {
            return YES;
        }
    }
    return NO;
}


#pragma mark - Archive

- (NSString*) archiveFile {
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [documentPath stringByAppendingPathComponent:@"JobQueue.archive"];
    return filePath;
}

- (void) archive {
    dispatch_async(self.exeQueue, ^{
        if(self.keysQueue.count == 0) {
            return;
        }
        NSArray *jobArray = [[self.jobMap objectEnumerator].allObjects copy];
        [self clear];
        NSMutableArray *jobs = [NSMutableArray array];
        for(NSArray *array in jobArray) {
            for(RTJob *job in array) {
                if(job.shouldSaved) {
                    [jobs addObject:job];
                }
            }
        }
//        NSLog(@"Archive");
        [NSKeyedArchiver archiveRootObject:jobs toFile:[self archiveFile]];
    });
}

- (void) unarchive {
    dispatch_async(self.exeQueue, ^{
        NSArray *jobs = [NSKeyedUnarchiver unarchiveObjectWithFile:[self archiveFile]];
        if(jobs == nil || jobs.count == 0) {
            return;
        }
        for(RTJob *job in jobs) {
            [self addJob:job];
        }
        [[NSFileManager defaultManager] removeItemAtPath:[self archiveFile] error:nil];
        [self restart];
    });
}

@end


