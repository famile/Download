//
//  TaskProgressInfo.h
//  Test_8.15
//
//  Created by 李涛 on 15/11/19.
//  Copyright © 2015年 敲代码的小毛驴. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum : NSUInteger {
    TaskIsDownloading,//正在下载
    TaskWaitDownload,//等待下载
    TaskHasDownload,//已经下载
    TaskResumeDownload,//恢复下载
    TaskNotDownload//没有下载
} TaskDownloadStatus;
@interface TaskProgressInfo : NSObject
/**
 *  文件的url
 */
@property (nonatomic, copy) NSString *url;
/**
 *  下载进度
 */
@property (nonatomic,assign) float progress;

/**
 *  下载速度
 */
@property (nonatomic,assign) float speed;

/**
 *  文件总大小
 */
@property (nonatomic, assign) long long expectedLength;
/**
 *  已下载大小
 */
@property (nonatomic, assign) long long finishedLenth;
/**
 *  未下载大小
 */
@property (nonatomic, assign) long long remainingLenth;
/**
 *  下载状态
 */
@property (nonatomic, assign) TaskDownloadStatus taskDownloadStatus;

/**
 *  已下载用时
 */
@property (nonatomic,assign) NSTimeInterval downloadTime;

/**
 *  预计剩余下载时间
 */
@property (nonatomic,assign) NSTimeInterval remainingTime;

@end
