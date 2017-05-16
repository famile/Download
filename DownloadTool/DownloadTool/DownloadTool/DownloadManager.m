//
//  DownloadManager.m
//  Test_8.15
//
//  Created by 李涛 on 15/11/19.
//  Copyright © 2015年 敲代码的小毛驴. All rights reserved.
//

#import "DownloadManager.h"

#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonCrypto.h>
NSString * const kNKDownloadKeyURL = @"URL";
NSString * const kNKDownloadKeyFileName = @"fileName";

#define fileLengthList [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"length.plist"]

@interface DownloadManager ()<NSURLSessionDataDelegate,NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSession *backgroundSession;
/**
 *  普通下载数组
 */
@property (nonatomic, strong) NSMutableArray *downloadArray;

@property (nonatomic, strong) NSMutableArray *urlArray;

@property (nonatomic, strong) NSMutableArray *modelArray;

/**
 *  正在下载的集合
 */
@property (nonatomic, strong) NSMutableSet *isDownloadingSet;

@end

@implementation DownloadManager
static id _instance;
+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}
+ (instancetype)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

#pragma mark - download Method
- (void)download:(NSString *)urlString model:(ZFVideoModel *)model progress:(void (^)(TaskProgressInfo *))progressInfo complete:(void (^)(NSString *, NSError *))complete enableBackgroundMode:(BOOL)backgroundMode{
    
    if ([self fileHasAddToUrlArray:urlString]) {
        [self.downloadArray enumerateObjectsUsingBlock:^(DownloadObject *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([urlString isEqualToString:obj.progressInfo.url]) {
               [obj setProgressBlock:^(TaskProgressInfo *pro) {
                   progressInfo(pro);
               }];
            }
        }];
        
    }else{
        [self.urlArray addObject:urlString];
        [self.modelArray addObject:model];
    
        NSString *fileName = [self getFileName:urlString];
        if ([self fileExistsWithName:urlString]) {
            TaskProgressInfo *progress = [self progressInfoIfFileExsit:urlString];
            progressInfo(progress);
            NSLog(@"下载完成");
        }else{
            // 创建下载任务
            NSURLSessionDataTask *dataTask = [self createdownloadTask:urlString enableBackgroundMode:YES];
            DownloadObject *downloadObj = [DownloadObject downloadObjectWith:dataTask progress:progressInfo complete:complete];
            downloadObj.fileName = fileName;
            downloadObj.filePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileName];
            downloadObj.startTime = [NSDate date];
            downloadObj.status = RequestStatusDownloading;
            downloadObj.progressInfo.taskDownloadStatus = TaskWaitDownload;
            downloadObj.progressInfo.url = urlString;
            downloadObj.progressBlock(downloadObj.progressInfo);
            
            [self.downloadArray addObject:downloadObj];
            [dataTask resume];
        }
    }

}

/**
 *  创建一个新任务
 *
 *  @param urlString      url
 *  @param backgroundMode 后台模式选择
 *
 *  @return
 */
- (NSURLSessionDataTask *)createdownloadTask:(NSString *)urlString enableBackgroundMode:(BOOL)backgroundMode{
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *fileName = [self getFileName:urlString];
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileName];
    NSUInteger finishedLength = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil][NSFileSize] integerValue];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-",finishedLength];
    [request setValue:range forHTTPHeaderField:@"Range"];
    //设置任务描述信息
    NSMutableDictionary *descDict = [NSMutableDictionary dictionary];
    [descDict setObject:urlString forKey:kNKDownloadKeyURL];
    [descDict setObject:fileName forKey:kNKDownloadKeyFileName];
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:descDict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    //产生一个新任务
    NSURLSessionDataTask *downloadTask = nil;
    if (backgroundMode) {
        downloadTask = [self.backgroundSession dataTaskWithRequest:request];
    }else{
        downloadTask = [self.session dataTaskWithRequest:request];
    }
    [downloadTask setTaskDescription:jsonString];
    return downloadTask;
}
- (void)cancelAllDownload
{
    [self.downloadArray enumerateObjectsUsingBlock:^(DownloadObject *downloadObject, NSUInteger idx, BOOL *stop) {
        if (downloadObject.completion) {
            downloadObject.completion = nil;
        }
        [downloadObject.downloadTask cancel];
        [self.downloadArray removeObject:downloadObject];
    }];
}

- (void)cancleDownload:(NSString *)urlString
{
    [self.urlArray removeObject:urlString];
    [self.isDownloadingSet removeObject:urlString];
    
    ZFVideoModel *model = [self modelHasAddToModelArray:urlString];
    if (model) {
        [self.modelArray removeObject:model];
    }

    [self.downloadArray enumerateObjectsUsingBlock:^(DownloadObject *downloadObject, NSUInteger idx, BOOL *stop) {
        if ([downloadObject.fileName isEqualToString:[self getFileName:urlString]]) {
            if (downloadObject.completion) {
                downloadObject.completion = nil;
            }
            downloadObject.progressInfo.speed = 0.0;
            [downloadObject.downloadTask cancel];
            [self.downloadArray removeObject:downloadObject];
        }
    }];
}
- (void)pauseDownload:(NSString *)urlString
{
    NSString *fileName = [self getFileName:urlString];
    [self.downloadArray enumerateObjectsUsingBlock:^(DownloadObject *downloadObject, NSUInteger idx, BOOL *stop) {
        RequestStatus status = downloadObject.status;
        if (status == RequestStatusDownloading && [downloadObject.fileName isEqualToString:fileName]) {
            [downloadObject.downloadTask suspend];
            downloadObject.progressInfo.speed = 0.0;
            downloadObject.status = RequestStatusPaused;
        }
    }];
}
- (void)retryDownload:(NSString *)urlString
{
    NSString *fileName = [self getFileName:urlString];
    [self.downloadArray enumerateObjectsUsingBlock:^(DownloadObject *downloadObject, NSUInteger idx, BOOL *stop) {
        RequestStatus status = downloadObject.status;
        if (status == RequestStatusPaused && [downloadObject.fileName isEqualToString:fileName]) {
            [downloadObject.downloadTask resume];
            downloadObject.status = RequestStatusDownloading;
        }
    }];
}

- (void)cancleAllDownload{
    
}

- (BOOL)removeHasDownloadTask:(NSString *)urlString{
    NSString *fileName = [self getFileName:urlString];
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileName];
    return [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
}
#pragma mark - file Method
- (TaskProgressInfo *)progressInfoIfFileExsit:(NSString *)urlString{
    
    NSString *fileName = [self getFileName:urlString];
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileName];
    if ([self fileExistsWithName:fileName] || [self fileHasAddToUrlArray:urlString]) {
        
        TaskProgressInfo *progressInfo = [[TaskProgressInfo alloc] init];
        if ([self fileHasAddToUrlArray:urlString]) {
            progressInfo.taskDownloadStatus = TaskWaitDownload;
        }else{
            progressInfo.taskDownloadStatus = TaskNotDownload;
        }
        if ([self fileIsDownloading:urlString]) {
            progressInfo.taskDownloadStatus = TaskIsDownloading;
        }
        if ([self fileExistsWithName:fileName]) {
            progressInfo.finishedLenth = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil][NSFileSize] integerValue];
            progressInfo.expectedLength = [[NSDictionary dictionaryWithContentsOfFile:fileLengthList][fileName] integerValue];
            progressInfo.progress = 1.0 * progressInfo.finishedLenth/progressInfo.expectedLength;
            progressInfo.speed = 0.0;
            progressInfo.remainingLenth = progressInfo.expectedLength - progressInfo.finishedLenth;
            progressInfo.url = urlString;
        }else{
            progressInfo.finishedLenth = 0;
            progressInfo.expectedLength = 0;
            progressInfo.progress = 0;
            progressInfo.remainingLenth = 0;
            progressInfo.url = urlString;
        }
        
        return progressInfo;
    }
    return nil;
}

- (NSString *)getFileName:(NSString *)urlString{
    NSString *fileNameWithoutType = [self md5:urlString];
    NSString *fileName = [NSString stringWithFormat:@"%@.%@",fileNameWithoutType,@"mp3"];
    return fileName;
}
/**
 *  返回文件类型
 */
- (NSString *)fileTypeWith:(NSString *)urlString
{
    return @"mp3";
}

- (BOOL)fileExistsWithName:(NSString *)fileName{
    BOOL exists = NO;
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        exists = YES;
    }
    
    return exists;
}
// 是否下载100%完成
- (BOOL)fileHasBeenDownloaded:(NSString *)fileName
{
    BOOL Done = NO;
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileName];
    NSUInteger finishedLength = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil][NSFileSize] integerValue];
    NSInteger totalLength = [[NSDictionary dictionaryWithContentsOfFile:fileLengthList][fileName] integerValue];
    if (totalLength && finishedLength == totalLength) {
        Done = YES;
    }
    return Done;
}
/**
 *  任务是否已经添加
 */
- (BOOL)fileHasAddToUrlArray:(NSString *)url{
    for (NSString *u in self.urlArray) {
        if ([u isEqualToString:url]) {
            return YES;
        }
    }
    return NO;
}
- (ZFVideoModel *)modelHasAddToModelArray:(NSString *)url{
    ZFVideoModel *model = nil;
    for (ZFVideoModel *m in self.modelArray) {
        if ([m.playUrl isEqualToString:url]) {
            model = m;
        }
    }
    return model;
}
/**
 *  这个url文件正在下载
 */
- (BOOL)fileIsDownloading:(NSString *)urlString{
    for (NSString *u in self.isDownloadingSet) {
        if ([u isEqualToString:urlString]) {
            return YES;
        }
    }
    return NO;
}
#pragma mark - NSURLSessionDataDelegate,NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    [self.downloadArray enumerateObjectsUsingBlock:^(DownloadObject *downloadObj,NSUInteger index, BOOL *stop){
        if ([downloadObj.downloadTask isEqual:dataTask]) {
            [downloadObj.stream open];
            //获得已经下载的长度
            downloadObj.progressInfo.finishedLenth = [[[NSFileManager defaultManager] attributesOfItemAtPath:downloadObj.filePath error:nil][NSFileSize] integerValue];
            downloadObj.progressInfo.expectedLength = [response.allHeaderFields[@"Content-Length"] integerValue] + downloadObj.progressInfo.finishedLenth;
            
            //把文件长度存进列表文件
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithContentsOfFile:fileLengthList];
            if (dic == nil) {
                dic = [NSMutableDictionary dictionary];
            }
            dic[downloadObj.fileName] = @(downloadObj.progressInfo.expectedLength);
            [dic writeToFile:fileLengthList atomically:YES];
            //接受这个请求，允许接受服务器的数据
            completionHandler(NSURLSessionResponseAllow);
        }
    }];
    
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    [self.downloadArray enumerateObjectsUsingBlock:^(DownloadObject *downloadObj,NSUInteger index, BOOL *stop){
        if ([downloadObj.downloadTask isEqual:dataTask]) {
            //写入数据
            NSUInteger left = [data length];
            downloadObj.progressInfo.finishedLenth += left;
            NSUInteger nwr = 0;
            do {
                nwr = [downloadObj.stream write:[data bytes] maxLength:left];
                if (-1 == nwr) {
                    break;
                }
                left -= nwr;
            } while (left > 0);
            if (left) {
                NSLog(@"stream error :%@",[downloadObj.stream streamError]);
            }
            if (downloadObj.progressBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    downloadObj.progressInfo.progress = 1.0 * downloadObj.progressInfo.finishedLenth / downloadObj.progressInfo.expectedLength;
                    
                    downloadObj.progressInfo.downloadTime = -1 * [downloadObj.startTime timeIntervalSinceNow];
                    downloadObj.progressInfo.speed = downloadObj.progressInfo.finishedLenth / downloadObj.progressInfo.downloadTime / 1024;
                    
                    downloadObj.progressInfo.remainingLenth = downloadObj.progressInfo.expectedLength - downloadObj.progressInfo.finishedLenth;
                    downloadObj.progressInfo.remainingTime = downloadObj.progressInfo.remainingLenth / downloadObj.progressInfo.speed;
                    
                    if (downloadObj.progressInfo.progress == 1) {
                        
                        downloadObj.progressInfo.taskDownloadStatus = TaskHasDownload;
                        ZFVideoModel *model = [self modelHasAddToModelArray:downloadObj.progressInfo.url];
                        downloadObj.progressInfo.speed = 0;
                        if (model) {

                            //保存到本地数据库
                        }
                        [self.isDownloadingSet removeObject:downloadObj.progressInfo.url];
                        [self.urlArray removeObject:downloadObj.progressInfo.url];
                        [self.downloadArray removeObject:downloadObj];
                    }else{
                        downloadObj.progressInfo.taskDownloadStatus = TaskIsDownloading;
                        [self.isDownloadingSet addObject:downloadObj.progressInfo.url];
                        
                    }
                    
                    downloadObj.progressBlock(downloadObj.progressInfo);
                });
            }
        }
    }];
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if ([session isEqual:self.backgroundSession]) {
        [task resume];
        NSLog(@"%@",error);
        
        
    }else{
        [self.downloadArray enumerateObjectsUsingBlock:^(DownloadObject *downloadObj, NSUInteger idx, BOOL *stop){
            if (downloadObj.completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    downloadObj.completion(downloadObj.filePath,error);
                });
            }
            [downloadObj.stream close];
            downloadObj.stream = nil;
            [downloadObj.downloadTask cancel];
            downloadObj.downloadTask = nil;
            
            [self.downloadArray removeObject:downloadObj];
            [self.isDownloadingSet removeObject:downloadObj.progressInfo.url];
            [self.urlArray removeObject:downloadObj.progressInfo.url];
        }];
    }
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session{
    [session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks){
        if ([dataTasks count] == 0) {
            if (self.backgroundTransferCompletionHandler != nil) {
                void(^comPletionHandler)() = self.backgroundTransferCompletionHandler;
                dispatch_async(dispatch_get_main_queue(), ^{
                    comPletionHandler();
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.alertBody = @"所有任务下载完成";
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                });
                self.backgroundTransferCompletionHandler = nil;
            }
        }
        
    }];
}
/**
 *  正在下载
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
}
/**
 *  下载完成
 *
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location{
    
}

- (NSString *)md5:(NSString *)str
{
    NSData *stringbytes = [str dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    if (CC_MD5([stringbytes bytes], (int)[stringbytes length], digest)) {
        NSMutableString *digestString = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH];
        for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
            unsigned char achar = digest[i];
            [digestString appendFormat:@"%02X",achar];
        }
        return digestString;
    }
    return nil;
}



#pragma mark - lazyLoad
- (NSURLSession *)session{
    if (!_session) {
        NSURLSessionConfiguration *confi = [NSURLSessionConfiguration defaultSessionConfiguration];
        //同一个Host 可以设置下载的最大数量
        confi.HTTPMaximumConnectionsPerHost = 2;
        _session = [NSURLSession sessionWithConfiguration:confi delegate:self delegateQueue:nil];
    }
    return _session;
}

- (NSURLSession *)backgroundSession{
    if (!_backgroundSession) {
        NSURLSessionConfiguration *confi = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"backGround"];
        _backgroundSession = [NSURLSession sessionWithConfiguration:confi delegate:self delegateQueue:nil];
    }
    return _backgroundSession;
}
- (NSMutableArray *)downloadArray{
    if (!_downloadArray) {
        _downloadArray = [NSMutableArray array];
    }
    return _downloadArray;
}
- (NSMutableArray *)urlArray{
    if (!_urlArray) {
        _urlArray = [NSMutableArray array];
    }
    return _urlArray;
}
- (NSMutableArray *)modelArray{
    if (!_modelArray) {
        _modelArray = [NSMutableArray array];
    }
    return _modelArray;
}
- (NSMutableSet *)isDownloadingSet{
    if (!_isDownloadingSet) {
        _isDownloadingSet = [NSMutableSet set];
    }
    return _isDownloadingSet;
}
@end
