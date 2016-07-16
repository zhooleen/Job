#import "RTJob.h"

@implementation RTJob

- (instancetype) init {
    self = [super init];
    if(self) {
        self.createdTime = [[NSDate date] timeIntervalSince1970];
        self.errorCode = 0;
        self.retryTimes = 4;
        self.shouldSaved = YES;
        self.cancellable = YES;
        self.repeative = NO;
        self.executing = NO;
    }
    return self;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self) {
        self.type = [aDecoder decodeObjectForKey:@"type"];
        self.identifier = [aDecoder decodeObjectForKey:@"identifier"];
        self.createdTime = [[aDecoder decodeObjectForKey:@"createdTime"] doubleValue];
        self.errorCode = [[aDecoder decodeObjectForKey:@"errorCode"] intValue];
        self.retryTimes = [[aDecoder decodeObjectForKey:@"retryTimes"] intValue];
        self.shouldSaved = [[aDecoder decodeObjectForKey:@"shouldSaved"] boolValue];
        self.cancellable = [[aDecoder decodeObjectForKey:@"cancellable"] boolValue];
        self.repeative = [[aDecoder decodeObjectForKey:@"repeative"] boolValue];
        self.parameters = [aDecoder decodeObjectForKey:@"parameters"];
        self.executing = NO;
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.type forKey:@"type"];
    [aCoder encodeObject:self.identifier forKey:@"identifier"];
    [aCoder encodeObject:@(self.createdTime) forKey:@"createdTime"];
    [aCoder encodeObject:@(self.errorCode) forKey:@"errorCode"];
    [aCoder encodeObject:@(self.retryTimes) forKey:@"retryTimes"];
    [aCoder encodeObject:@(self.shouldSaved) forKey:@"shouldSaved"];
    [aCoder encodeObject:@(self.cancellable) forKey:@"cancellable"];
    [aCoder encodeObject:@(self.repeative) forKey:@"repeative"];
    [aCoder encodeObject:self.parameters forKey:@"parameters"];
}

- (BOOL) isEqual:(RTJob*)job {
    return [self.type isEqualToString:job.type] && ([self.identifier isEqualToString: job.identifier]);
}

- (BOOL) isInverse:(RTJob*)job {
    return ![self.type isEqualToString:job.type] && ([self.identifier isEqualToString: job.identifier]);
}

- (void) executeWithBlock:(void(^)(int status))block {
    self.executing = YES;
    -- self.retryTimes;
    if(block) {
        block(self.retryTimes == 0? self.errorCode+1 : 0);
    }
    self.executing = NO;
}

- (RTJob*) inverseJob {
    return nil;
}
@end
