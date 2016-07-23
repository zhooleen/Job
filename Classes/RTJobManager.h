#import <Foundation/Foundation.h>

#import "RTJob.h"

@interface RTJobManager : NSObject

/**
 * The RTJobManager singleton object
 */
+ (instancetype) sharedManager;

/**
 * The thing you only need to do is to create a concrete subclass inherits from RTJob, that is a Time-consuming operation.
 * Add it into manager, and the manager will handle the rest: execute it until success or expiration.
 */
- (void) addJob:(RTJob*)job;

/**
 * Start the manager's run loop when app did launch.
 * Then the manager will unarchive the jobs, continue excuting.
 */
- (void) start;

/**
 * Stop executing and archive the left jobs.
 */
- (void) save;

/**
 * Stop executing and clear the left jobs.
 */
- (void) clear;

/**
 * Observe the notification 'notificationName',
 * when it posted, stop executing and archive left jobs.
 * Such as UIApplicationDidEnterBackgroundNotification, NetworkNotreachableNotification...
 */
- (void) saveJobsWhenPostNotification:(NSString*)notificationName;

/**
 * Observe the notification 'notificationName',
 * when it posted, stop executing and clear left jobs
 * Such as UserHasLogoutNotification...
 */
- (void) clearJobsWhenPostNotification:(NSString*)notificationName;

@end


