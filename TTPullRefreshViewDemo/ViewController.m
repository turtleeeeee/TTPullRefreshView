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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    TTPullRefreshView *refreshView = [TTPullRefreshView defaultRefreshView];
    refreshView.titles = @[@"正在努力刷新...", @"2016-09-08 17:25"];
    [refreshView setGuidingText:@"刷新完成" forState:TTPullRefreshStateFinished];
    [refreshView setGuidingText:@"下拉刷新" forState:TTPullRefreshStatePullToRefresh];
    [refreshView setGuidingText:@"松手刷新" forState:TTPullRefreshStateLooseToRefresh];
    [refreshView setTitleColor:[UIColor grayColor]];
    [refreshView setSubTitleColor:[UIColor grayColor]];
    [refreshView setTarget:self action:@selector(refreshHandler:)];
    _tableView.refreshView = refreshView;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)refreshHandler:(id)sender {
    NSLog(@"-----------------------------refreshing..");
    TTPullRefreshView *pullRefreshView = sender;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [pullRefreshView finished];
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseID = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseID];
    }
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    
}

@end
