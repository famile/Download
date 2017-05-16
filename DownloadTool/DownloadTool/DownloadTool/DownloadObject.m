//
//  DownloadObject.m
//  Test_8.15
//
//  Created by 李涛 on 15/11/19.
//  Copyright © 2015年 敲代码的小毛驴. All rights reserved.
//

#import "DownloadObject.h"

@implementation DownloadObject
- (TaskProgressInfo *)progressInfo{
    if (!_progressInfo) {
        _progressInfo = [[TaskProgressInfo alloc] init];
    }
    return _progressInfo;
}
- (NSOutputStream *)stream{
    if (!_stream) {
        _stream = [[NSOutputStream alloc] initToFileAtPath:self.filePath append:YES];
    }
    return _stream;
}
+ (instancetype)downloadObjectWith:(NSURLSessionDataTask *)dataTask progress:(void (^)(TaskProgressInfo *))progressBlock complete:(void (^)(NSString *, NSError *))completion{
    DownloadObject *obj = [[self alloc] init];
    obj.downloadTask = dataTask;
    obj.progressBlock = progressBlock;
    obj.completion = completion;
    return obj;
}

@end
