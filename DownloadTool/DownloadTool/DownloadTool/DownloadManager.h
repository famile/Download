//
//  DownloadManager.h
//  Test_8.15
//
//  Created by 李涛 on 15/11/19.
//  Copyright © 2015年 敲代码的小毛驴. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TaskProgressInfo.h"
#import "DownloadObject.h"
#import "ZFVideoModel.h"

@interface DownloadManager : NSObject
/**
 *  后台模式的回调block
 */
@property (nonatomic, strong) void(^backgroundTransferCompletionHandler)();

/**
 *  @return 下载管理者
 */
+ (instancetype)shareManager;
/**
 *  下载方法
 *
 *  @param urlString      文件的url路径
 *  @param progress       文件下载过程的回调block
 *  @param complete       文件下载完后的回调block
 *  @param backgroundMode 后台模式选择
 */
- (void)download:(NSString *)urlString model:(ZFVideoModel *)model progress:(void(^)(TaskProgressInfo *progressInfo))progressInfo complete:(void(^)(NSString *filePath,NSError *error))complete enableBackgroundMode:(BOOL)backgroundMode;
/**
 *  暂停正在进行的下载任务
 */
- (void)pauseDownload:(NSString *)urlString;
/**
 *  继续暂停的下载任务
 */
- (void)retryDownload:(NSString *)urlString;
/**
 *  取消一个下载任务
 */
- (void)cancleDownload:(NSString *)urlString;
/**
 *  取消所有下载任务
 */
- (void)cancleAllDownload;
/**
 *  删除下载完的任务
 */
- (BOOL)removeHasDownloadTask:(NSString *)urlString;

/**
 *  有的文件已经下载完毕或者下载了一部分，需要知道进度信息，调用此方法
 *
 *  @param urlString 文件的url
 *
 *  @return 已经存在文件的进度信息
 */
- (TaskProgressInfo *)progressInfoIfFileExsit:(NSString *)urlString;
@end
