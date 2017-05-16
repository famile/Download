//
//  DownloadListCell.m
//  DownloadTool
//
//  Created by 李涛 on 16/10/27.
//  Copyright © 2016年 Tao_Lee. All rights reserved.
//

#import "DownloadListCell.h"
#import "DownloadManager.h"

@interface DownloadListCell ()<UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;

@property (nonatomic, assign) BOOL waitDownload;
//@property (nonatomic, assign) TaskDownloadStatus taskDownloadStatus;
@property (nonatomic, strong) ZFVideoModel *model;


@end

@implementation DownloadListCell

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == 0) {
        [[DownloadManager shareManager] removeHasDownloadTask:_model.playUrl];
        _model.downloadStatus = TaskNotDownload;
        self.progressView.progress = 0;
        [self setButtonIcon];
    }
}


#pragma mark - httpRequest

#pragma mark - click

- (void)clickDownloadBtn:(UIButton *)btn{
    
    switch (_model.downloadStatus) {
        case TaskHasDownload:{
            [self delete];
            break;
        }
        case TaskResumeDownload:{
            [self resume];
            break;
        }
        case TaskNotDownload:{
            [self start];
            break;
        }
        case TaskIsDownloading:{
            [self pause];
            break;
        }
        case TaskWaitDownload:{
            [self.downloadBtn setImage:[UIImage imageNamed:@"wait"] forState:(UIControlStateNormal)];
            break;
        }
        default:
            break;
    }
}

- (void)setButtonIcon{
    
    switch (_model.downloadStatus) {
        case TaskIsDownloading:{
            [self.downloadBtn setImage:[UIImage imageNamed:@"reuse"] forState:(UIControlStateNormal)];
            break;
        }
        case TaskWaitDownload:{
            [self.downloadBtn setImage:[UIImage imageNamed:@"wait"] forState:(UIControlStateNormal)];
            break;
        }
        case TaskHasDownload:{
            [self.downloadBtn setImage:[UIImage imageNamed:@"delete"] forState:(UIControlStateNormal)];
            break;
        }
        case TaskResumeDownload:{
            [self.downloadBtn setImage:[UIImage imageNamed:@"reuse"] forState:(UIControlStateNormal)];
            break;
        }
        case TaskNotDownload:{
            [self.downloadBtn setImage:[UIImage imageNamed:@"download"] forState:(UIControlStateNormal)];
            break;
        }
        default:{
            break;
        }
    }
}

/**
 *  从零开始
 */
- (void)start
{
    
    [self.downloadBtn setImage:[UIImage imageNamed:@"reuse"] forState:(UIControlStateNormal)];
    __weak __typeof(&*self)ws = self;
    [[DownloadManager shareManager] download:[NSString stringWithFormat:@"%@",self.model.playUrl] model:self.model progress:^(TaskProgressInfo *progressInfo) {
        if ([ws.model.playUrl isEqualToString:progressInfo.url]) {
            ws.progressView.progress = progressInfo.progress;
            ws.model.downloadStatus = progressInfo.taskDownloadStatus;
            ws.speedLabel.text = [NSString stringWithFormat:@"%.2fK",progressInfo.speed];
            [ws setButtonIcon];
            
        }
    } complete:^(NSString *filePath, NSError *error) {
        
    } enableBackgroundMode:YES];
    
}

/**
 *  恢复（继续）
 */
- (void)resume
{
    [self.downloadBtn setImage:[UIImage imageNamed:@"reuse"] forState:(UIControlStateNormal)];
    [[DownloadManager shareManager] retryDownload:[NSString stringWithFormat:@"%@",self.model.playUrl]];
    
}

/**
 *  暂停
 */
- (void)pause
{
    [self.downloadBtn setImage:[UIImage imageNamed:@"start"] forState:(UIControlStateNormal)];
    [[DownloadManager shareManager] cancleDownload:[NSString stringWithFormat:@"%@",self.model.playUrl]];
    self.speedLabel.text = @"0.0K";
    self.model.downloadStatus = TaskNotDownload;
}
/**
 *  删除
 */
- (void)delete{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"确定要删除吗" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
    [alert show];
    
}



#pragma mark - init

- (void)configWithModel:(ZFVideoModel *)model{
    _model = model;
    _nameLabel.text = model.title;
    
    if (self.waitDownload == YES) {
        [_downloadBtn setImage:[UIImage imageNamed:@"wait"] forState:(UIControlStateNormal)];
    }
    __weak __typeof(&*self)ws = self;
    
    TaskProgressInfo *info = [[DownloadManager shareManager] progressInfoIfFileExsit:model.playUrl];
    
    if (info) {
        
        if (info.progress == 1) {
            _model.downloadStatus = TaskHasDownload;
            self.progressView.progress = 1.0;
        }else{
            self.progressView.progress = info.progress;
            self.speedLabel.text = [NSString stringWithFormat:@"%.2fK",info.speed];
            _model.downloadStatus = info.taskDownloadStatus;
            if (info.taskDownloadStatus != TaskNotDownload) {
                [[DownloadManager shareManager] download:[NSString stringWithFormat:@"%@",self.model.playUrl] model:self.model progress:^(TaskProgressInfo *progressInfo) {
                    if ([ws.model.playUrl isEqualToString:progressInfo.url]) {
                        ws.progressView.progress = progressInfo.progress;
                        ws.model.downloadStatus = progressInfo.taskDownloadStatus;
                        ws.speedLabel.text = [NSString stringWithFormat:@"%.2fK",progressInfo.speed];
                        [ws setButtonIcon];
                        
                    }
                } complete:^(NSString *filePath, NSError *error) {
                    
                } enableBackgroundMode:YES];
            }
            
        }
        
    }else{
        
        self.model.downloadStatus = TaskNotDownload;
        self.progressView.progress = info.progress;
        self.speedLabel.text = [NSString stringWithFormat:@"%.2fK",info.speed];
    }
    
    [self setButtonIcon];
}


- (void)layoutSubviews{
    [super layoutSubviews];
    if (self.waitDownload) {
        [self.downloadBtn setImage:[UIImage imageNamed:@"wait"] forState:(UIControlStateNormal)];
    }
    if (self.progressView.progress == 1) {
        [self.downloadBtn setImage:[UIImage imageNamed:@"delete"] forState:(UIControlStateNormal)];
    }
}



- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self.downloadBtn addTarget:self action:@selector(clickDownloadBtn:) forControlEvents:(UIControlEventTouchUpInside)];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}




@end
