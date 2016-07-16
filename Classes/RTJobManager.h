#import <Foundation/Foundation.h>

#import "RTJob.h"

@interface RTJobManager : NSObject

+ (instancetype) sharedManager;

- (void) addJob:(RTJob*)job;

- (void) start;

- (void) save;

- (void) clear;

@end


