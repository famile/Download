//
//  DownloadObject.h
//  Test_8.15
//
//  Created by 李涛 on 15/11/19.
//  Copyright © 2015年 敲代码的小毛驴. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TaskProgressInfo.h"
typedef enum : NSUInteger {
    RequestStatusDownloading,
    RequestStatusPaused,
    RequestStatusFailed
} RequestStatus;

@interface DownloadObject : NSObject
/**
 *  进度
 */
@property (nonatomic, strong) TaskProgressInfo *progressInfo;
/**
 *  文件名
 */
@property (nonatomic, copy) NSString *fileName;
/**
 *  下载任务
 */
@property (nonatomic, strong) NSURLSessionDataTask *downloadTask;
/**
 *  文件路径
 */
@property (nonatomic, copy) NSString *filePath;
/**
 *  下载开始时间
 */
@property(nonatomic,strong) NSDate *startTime;
/**
 *  当前请求状态
 */
@property (nonatomic, assign) RequestStatus status;
/**
 *  下载时候的流对象
 */
@property (nonatomic, strong) NSOutputStream *stream;
/**
 *  下载中的回调
 */
@property (nonatomic, copy) void(^progressBlock)(TaskProgressInfo *progressInfo);
/**
 *  下载完的回调
 */
@property (nonatomic, copy) void(^completion)(NSString *filePath,NSError *error);

+ (instancetype)downloadObjectWith:(NSURLSessionDataTask *)dataTask progress:(void(^)(TaskProgressInfo *progressInfo))progressBlock complete:(void(^)(NSString *filePath,NSError *error))completion;
@end
