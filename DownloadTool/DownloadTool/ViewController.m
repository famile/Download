//
//  ViewController.m
//  DownloadTool
//
//  Created by 李涛 on 16/10/27.
//  Copyright © 2016年 Tao_Lee. All rights reserved.
//

#import "ViewController.h"
#import "DownloadListCell.h"

#define ScreenWidth      [UIScreen mainScreen].bounds.size.width
#define ScreenHeight      [UIScreen mainScreen].bounds.size.height
#define ScreenBounds     [UIScreen mainScreen].bounds



@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *dataSource;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self initUI];
    [self requestData];
}

#pragma mark - UITableViewDelegate,UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _dataSource.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    DownloadListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"downloadlistcell" forIndexPath:indexPath];
//    cell.model = _dataSource[indexPath.row];
    [cell configWithModel:_dataSource[indexPath.row]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

#pragma mark - httpRequest

- (void)requestData
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"videoData" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *rootDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    self.dataSource = @[].mutableCopy;
    NSArray *videoList = [rootDict objectForKey:@"videoList"];
    for (NSDictionary *dataDic in videoList) {
        ZFVideoModel *model = [[ZFVideoModel alloc] init];
        [model setValuesForKeysWithDictionary:dataDic];
        model.downloadStatus = TaskNotDownload;
        [self.dataSource addObject:model];
    }
    [self.tableView reloadData];
    
}

#pragma mark - click

#pragma mark - init

- (void)initUI{
    
    [self.view addSubview:self.tableView];
    [self.tableView registerNib:[UINib nibWithNibName:@"DownloadListCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"downloadlistcell"];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}



- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:(CGRectMake(0, 64, ScreenWidth, ScreenHeight-64)) style:(UITableViewStylePlain)];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tableView;
}


@end
