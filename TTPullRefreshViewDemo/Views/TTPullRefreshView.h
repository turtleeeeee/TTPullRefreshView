//
//  TTPullRefreshView.h
//  RefreshControllTest
//
//  Created by turtle on 16/8/28.
//  Copyright © 2016年 Turtle. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TTPullRefreshLayoutType) {
    TTPullRefreshLayoutLeft,
    TTPullRefreshLayoutRight,
    TTPullRefreshLayoutTop,
    TTPullRefreshLayoutBottom
};

typedef NS_ENUM(NSInteger, TTPullRefreshState) {
    TTPullRefreshStateNone,
    TTPullRefreshStatePullToRefresh,
    TTPullRefreshStateLooseToRefresh,
    TTPullRefreshStateRefreshing,
    TTPullRefreshStateFinished
};

@class TTPullRefreshView;
@interface UIScrollView (TTPullRefreshView)

@property (nonatomic, strong, nullable)TTPullRefreshView *refreshView;

@end

@interface TTPullRefreshView : UIView

@property (nonatomic, strong)UIImageView *indicatorView;
@property (nonatomic, copy, nullable)NSArray<NSString *> *titles;
@property (nonatomic, assign)TTPullRefreshLayoutType layoutType;
@property (nonatomic, assign)CGFloat titleFontSize;
@property (nonatomic, assign)CGFloat subTitleFontSize;
@property (nonatomic, strong)UIColor *titleColor;
@property (nonatomic, strong)UIColor *subTitleColor;

+ (TTPullRefreshView *)defaultRefreshView;
- (void)setTarget:(id)target action:(SEL)action;
- (void)finished;
- (void)setGuidingText:(NSString *)guidingText forState:(TTPullRefreshState)state;

@end

NS_ASSUME_NONNULL_END
