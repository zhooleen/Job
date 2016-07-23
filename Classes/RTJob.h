#import <Foundation/Foundation.h>

/**
 * Some time-consuming operations, usually the network request.
 * The JobManager will do its best to make sure job executing successfully.
 * So, assume it had executed successfully before it really executes, 
 * update the UI according to the success hypothesis.
 */
@interface RTJob : NSObject <NSCoding>

//任务的主类型，相反的任务通过type来区分
@property (strong, nonatomic) NSString *type;

//任务标识, 相反的任务或相同的任务都应该有相同的identifier
@property (strong, nonatomic) NSString *identifier;

//创建任务的时间，单位：秒
@property (assign, nonatomic) NSTimeInterval createdTime;

//错误码，当遇到该错误码时，取消任务
@property (assign, nonatomic) int errorCode;

//剩余重试次数，超过次数，取消任务，次数为0，只能等待下一次重启运行循环才能重试
@property (assign, nonatomic) int retryTimes;

//APP退出时，是否保存任务
@property (assign, nonatomic) BOOL shouldSaved;

//是否可以取消，是否存在存在相反的操作,如点赞，取消点赞，点赞....相邻两个任务是可抵消的
//相反的两种任务都可取消
@property (assign, nonatomic) BOOL cancellable;

//是否可重复，如果为NO，此时队列中存在相同的任务，则删除队列中原来的任务，以最新的任务为主
//如对于同一张照片：点赞－>点赞 ＝ 点赞（虽然一般不会发生的，但点击速度快于状态改变速度，还是有可能的）
@property (assign, nonatomic) BOOL repeative;

//执行该任务需要的环境，状态，条件，参数等
@property (strong, nonatomic) NSDictionary *parameters;

//是否在执行
@property (assign, nonatomic) BOOL executing;

//比较两个任务是否相等
- (BOOL) isEqual:(RTJob*)job;

/**
 比较两个任务，判断它们是否可以相互抵消
 */
- (BOOL) isInverse:(RTJob*)job;


/*****************************************************************\
 子类必须重载以下方法：
 1.[executeInQueue:withBlock:]
 2.[inverseJob]
    > 存在相反的任务，且必须通过执行相反的动作来达到取消的目的的时候
    > 一般不用考虑
\*****************************************************************/

/**
 执行任务
 status：任务执行结束的状态
 0表示成功，其他的表示失败
 如果status与errorCode相等，取消任务
 子类重载方式：
 - (void) executeInQueue:(dispatch_queue_t)queue withBlock:(void(^)(int status))block{
    [super executeInQueue:queue withBlock:^(int sta) {
        if(sta == 0) {
            sta = [self action...];
        }
        dispatch_async(queue, ^{
            block(sta);
        ]);
    }];
 }
 */
- (void) executeInQueue:(dispatch_queue_t)queue withBlock:(void(^)(int status))block;

/**
 如果在执行的时候取消，则会遇到以下几种情况：
    1. 必须忽略取消操作
    2. 必须等到当前执行结束，才能执行取消操作
        2.1 执行成功，则执行相反任务
        2.2 执行失败，删除任务
    3. 可在执行过程中取消 (不考虑这种情况，一般不会出现这种情况)
 没在执行状态，直接删除
 */
//- (void) cancel; //cancel operation execute by manager

/**
 返回一个作用相反的任务
 */
- (RTJob*) inverseJob;


@end
