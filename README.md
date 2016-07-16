# Job
Let jobs run in background thread to improve user experience


> 有些时候，用户对的操作需要等待服务器的响应，如关注，评论。。。。
> 对于这些简单的操作，必须保证快速且操作成功， 提升用户体验。
> 
> Job 简单地封装了以上需求：
> 1.立刻响应用户，对UI进行更新
> 2.将用户操作封装成任务扔到后台任务队列，由队列保证执行成功
