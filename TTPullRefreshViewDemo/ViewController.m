//
//  ViewController.m
//  RefreshControllTest
//
//  Created by Turtle on 16/8/26.
//  Copyright © 2016年 Turtle. All rights reserved.
//

#import "ViewController.h"
#import "TTPullRefreshView.h"

#define refreshControlWidth 50.0f
#define refreshControlHeight 50.0f

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (copy, nonatomic) NSMutableArray *models;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _models = [NSMutableArray arrayWithArray:@[
                                               @"Stephen Curry",
                                               @"James Harden",
                                               @"Klay Thompson",
                                               @"Lamarcus Aldridge",
                                               @"Tristan Thompson"
                                               ]];
    TTPullRefreshView *refreshView = [TTPullRefreshView defaultRefreshView];
    refreshView.layoutType = TTPullRefreshLayoutLeft;
    refreshView.titles = @[@"正在努力刷新...", @"请稍等", @"2016-09-08 17:25"];
    [refreshView setGuidingText:@"刷新完成" forState:TTPullRefreshStateFinished];
    [refreshView setGuidingText:@"下拉刷新" forState:TTPullRefreshStatePullToRefresh];
    [refreshView setGuidingText:@"松手刷新" forState:TTPullRefreshStateLooseToRefresh];
    [refreshView setTitleFontSize:16.0f];
    [refreshView setSubTitleFontSize:12.0f];
    [refreshView setTitleColor:[UIColor grayColor]];
    [refreshView setSubTitleColor:[UIColor blueColor]];
    [refreshView setTarget:self action:@selector(refreshHandler:)];
    _tableView.refreshView = refreshView;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)refreshHandler:(id)sender {
    TTPullRefreshView *pullRefreshView = sender;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [pullRefreshView finished];
        if (_models.count == 10) {
            [_models removeObjectsInRange:NSMakeRange(5, 5)];
            [_tableView reloadData];
        }
        else {
            
            [_models addObjectsFromArray:@[
                                           @"Russell Westbrook",
                                           @"Paul Pierce",
                                           @"Paul George",
                                           @"Carmelo Anthony",
                                           @"Joakim Noah"
                                           ]];
            [_tableView reloadData];

        }
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _models.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseID = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseID];
    }
    cell.textLabel.text = _models[indexPath.row];
    return cell;
}

@end
