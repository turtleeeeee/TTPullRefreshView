//
//  TTPullRefreshView.m
//  RefreshControllTest
//
//  Created by turtle on 16/8/28.
//  Copyright © 2016年 Turtle. All rights reserved.
//

#import "TTPullRefreshView.h"
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

static const CGFloat kDefaultIndicatorHeight = 30.0f;
CGFloat kGlobalTitleHeight = 12.0f;
CGFloat kGlobalSubTitleHeight = 12.0f;
static const CGFloat kDefaultHorizontalSpacing = 8.0f;
static const CGFloat kDefaultVerticalSpacing = 5.0f;
static const CGFloat kNeedsRefreshingSpacing = 3.0f;
static const CGFloat kFixedOffset = 13.0f;         

@implementation UIScrollView (TTPullRefreshView)

static char refreshViewKey;
BOOL shouldSwizzleIfRefreshViewIsNil = NO;

#pragma mark - Category public
- (TTPullRefreshView * _Nullable)refreshView {
    return objc_getAssociatedObject(self, &refreshViewKey);
}

- (void)setRefreshView:(TTPullRefreshView * _Nullable)refreshView {
    if (self.refreshView) {
        [self.refreshView removeFromSuperview];
    }
    objc_setAssociatedObject(self, &refreshViewKey, refreshView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (refreshView != nil) {
        [self addSubview:refreshView];
        [self addObserver:refreshView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
        [self.panGestureRecognizer addTarget:self.refreshView action:@selector(scrollViewPanHandler:)];
        [refreshView setValue:self forKey:@"scrollView"];
        if (!shouldSwizzleIfRefreshViewIsNil) {
            [self swizzleMethods];
            shouldSwizzleIfRefreshViewIsNil = YES;
        }
    }
    else {
        if (shouldSwizzleIfRefreshViewIsNil) {
            [self swizzleMethods];
            shouldSwizzleIfRefreshViewIsNil = NO;
        }
    }
}

#pragma mark - Category private
#pragma mark - layout
- (void)swizzleMethods {
    Method originalMethod = class_getInstanceMethod([self class], @selector(layoutSubviews));
    Method swizzleMethod = class_getInstanceMethod([self class], @selector(swizzle_layoutSubviews));
    method_exchangeImplementations(originalMethod, swizzleMethod);
}

- (void)swizzle_layoutSubviews {
    [self swizzle_layoutSubviews];
    CGFloat refreshViewHeight = [self getRefreshViewHeight];
    UIEdgeInsets scrollViewOriginalInset = [[self.refreshView valueForKey:@"scrollViewOriginalInset"] UIEdgeInsetsValue];
    BOOL didSetOriginalInsets = [[self.refreshView valueForKey:@"didSetOriginalInsets"] boolValue];
    NSLog(@"%@", self.refreshView);
    if (didSetOriginalInsets) {
        self.refreshView.frame = CGRectMake(0, - refreshViewHeight - scrollViewOriginalInset.top, self.frame.size.width, refreshViewHeight);
    }
    else if(self.contentInset.top != 0) {
            self.refreshView.frame = CGRectMake(0, - refreshViewHeight - self.contentInset.top, self.frame.size.width, refreshViewHeight);
    }
}

#pragma mark - helper
//感觉kDefaultIndicatorHeight应该可以改成imageView的高度=。=。。。动态决定吧~
- (CGFloat)getRefreshViewHeight {
    if (self.refreshView.titles.count > 0) {
        CGFloat referredHeight;
        switch (self.refreshView.layoutType) {
            case TTPullRefreshLayoutLeft:
            case TTPullRefreshLayoutRight:
                referredHeight = kGlobalTitleHeight + (self.refreshView.titles.count - 1) * (kGlobalSubTitleHeight + kDefaultVerticalSpacing);
                referredHeight = referredHeight > kDefaultIndicatorHeight ? referredHeight : kDefaultIndicatorHeight;
                break;
            case TTPullRefreshLayoutTop:
            case TTPullRefreshLayoutBottom:
                referredHeight = kDefaultIndicatorHeight + kGlobalTitleHeight + (self.refreshView.titles.count - 1) * (kGlobalSubTitleHeight + kDefaultVerticalSpacing);
                break;
            default:
                NSAssert(NO, @"Don't have such a layout type, which is not expected...");
                break;
        }
        referredHeight += kFixedOffset;
        return referredHeight;
    }
    return kDefaultIndicatorHeight;
}

@end

#pragma mark - TTPullRefreshView Start
@interface TTPullRefreshView (){
    UIStackView * _Nullable _horizontalStackView;
    UIStackView *_verticalStackView;
    id _target;
    SEL _action;
}
@property (nonatomic, weak)UIScrollView *scrollView;
@property (nonatomic, assign)UIEdgeInsets scrollViewOriginalInset;
@property (nonatomic, assign)TTPullRefreshState refreshState;
@property (nonatomic, strong)NSMutableDictionary *stateTitles;
@property (nonatomic, strong)UILabel *guidingLabel;//上拉刷新，松手结束，已完成的指示label
@property (nonatomic, assign)BOOL didSetOriginalInsets;

@end

@implementation TTPullRefreshView

#pragma mark - life cycle
- (void)willMoveToSuperview:(UIView * _Nullable)newSuperview {
    [super willMoveToSuperview:newSuperview];
    [_scrollView removeObserver:self forKeyPath:@"contentOffset"];
}

- (void)dealloc {
    [_scrollView removeObserver:self forKeyPath:@"contentOffset"];
}

#pragma mark - KVO
//捕捉滑动事件
- (void)observeValueForKeyPath:(NSString * _Nullable)keyPath ofObject:(id _Nullable)object change:(NSDictionary<NSKeyValueChangeKey,id> * _Nullable)change context:(void * _Nullable)context
{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        CGPoint contentOffset = [[change objectForKey:NSKeyValueChangeNewKey] CGPointValue];
        [self scrollViewDidScrollToOffset:contentOffset];
    }
}

#pragma mark - public 
+ (TTPullRefreshView *)defaultRefreshView {
    TTPullRefreshView *pullRefreshView = [[TTPullRefreshView alloc] init];
    pullRefreshView.layoutType = TTPullRefreshLayoutTop;
    pullRefreshView.stateTitles = [[NSMutableDictionary alloc] init];
    pullRefreshView.guidingLabel = [[UILabel alloc] init];
    pullRefreshView.didSetOriginalInsets = NO;
    [pullRefreshView setupPullRefreshView];
    return pullRefreshView;
}

- (void)setLayoutType:(TTPullRefreshLayoutType)layoutType {
    _layoutType = layoutType;
    [self setupPullRefreshView];
}

- (void)setGuidingText:(NSString *)guidingText forState:(TTPullRefreshState)state {
    [_stateTitles setObject:guidingText forKey:[NSNumber numberWithInteger:state]];
}

- (void)setTitles:(NSArray<NSString *> * _Nullable)titles {
    _titles = [titles copy];
    [self setupTitleLabels];
}

- (void)setRefreshState:(TTPullRefreshState)refreshState {
    _refreshState = refreshState;
    NSString *guidingText = [_stateTitles objectForKey:[NSNumber numberWithInteger:refreshState]];
    switch (refreshState) {
        case TTPullRefreshStateNone:
            break;
        case TTPullRefreshStatePullToRefresh:
            if (guidingText) {
                _guidingLabel.text = guidingText;
                [self setupGuidingLabelWithHiddenFlag:NO];
            }
            break;
        case TTPullRefreshStateLooseToRefresh:
            if (guidingText) {
                _guidingLabel.text = guidingText;
                [self setupGuidingLabelWithHiddenFlag:NO];
            }
            break;
        case TTPullRefreshStateRefreshing:
            [self setupGuidingLabelWithHiddenFlag:YES];
            break;
        case TTPullRefreshStateFinished:
            if (guidingText) {
                _guidingLabel.text = guidingText;
                [self setupGuidingLabelWithHiddenFlag:NO];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        _scrollView.contentInset = _scrollViewOriginalInset;
                    } completion:^(BOOL finished) {
                        _refreshState = TTPullRefreshStateNone;
                        _didSetOriginalInsets = NO;
                    }];
                });
                return;
            }
            [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                _scrollView.contentInset = _scrollViewOriginalInset;
            } completion:^(BOOL finished) {
                _refreshState = TTPullRefreshStateNone;
                _didSetOriginalInsets = NO;
            }];
            break;
    }
}

- (void)setTarget:(id)target action:(SEL)action {
    _target = target;
    _action = action;
}

- (void)setTitleFontSize:(CGFloat)titleFontSize {
    _titleFontSize = titleFontSize;
    kGlobalTitleHeight = titleFontSize;
    for (UIView *view in _verticalStackView.arrangedSubviews) {
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)view;
            if ([label.text isEqualToString:_titles[0]]) {
                label.font = [UIFont systemFontOfSize:titleFontSize];
            }
        }
    }
    _guidingLabel.font = [UIFont systemFontOfSize:titleFontSize];
}

- (void)setSubTitleFontSize:(CGFloat)subTitleFontSize {
    _subTitleFontSize = subTitleFontSize;
    kGlobalSubTitleHeight = subTitleFontSize;
    for (UIView *view in _verticalStackView.arrangedSubviews) {
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)view;
            if (![label.text isEqualToString:_titles[0]] && label != _guidingLabel) {
                label.font = [UIFont systemFontOfSize:subTitleFontSize];
            }
        }
    }
}

- (void)setTitleColor:(UIColor *)titleColor {
    _titleColor = titleColor;
    for (UIView *view in _verticalStackView.arrangedSubviews) {
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)view;
            if ([label.text isEqualToString:_titles[0]]) {
                label.textColor = titleColor;
            }
        }
    }
    _guidingLabel.textColor = titleColor;
}

- (void)setSubTitleColor:(UIColor *)subTitleColor {
    _subTitleColor = subTitleColor;
    for (UIView *view in _verticalStackView.arrangedSubviews) {
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)view;
            if (![label.text isEqualToString:_titles[0]] && label != _guidingLabel) {
                label.textColor = subTitleColor;
            }
        }
    }
}

- (void)finished {
    self.refreshState = TTPullRefreshStateFinished;
}

#pragma mark - private
#pragma mark - UI helper
- (void)setupPullRefreshView {
    _indicatorView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"loading"]];
    _refreshState = TTPullRefreshStateNone;
    switch (_layoutType) {
        case TTPullRefreshLayoutLeft:
        case TTPullRefreshLayoutRight:
            [self layoutsHorizontalType];
            break;
        case TTPullRefreshLayoutTop:
        case TTPullRefreshLayoutBottom:
            [self layoutsVerticalType];
            break;
        default:
            break;
    }
}

- (void)setupHorizontalStackView {
    _horizontalStackView = [[UIStackView alloc] init];
    _horizontalStackView.axis = UILayoutConstraintAxisHorizontal;
    _horizontalStackView.spacing = kDefaultHorizontalSpacing;
    _horizontalStackView.alignment = UIStackViewAlignmentCenter;
}

- (void)setupVerticalStackView {
    _verticalStackView = [[UIStackView alloc] init];
    _verticalStackView.axis = UILayoutConstraintAxisVertical;
    _verticalStackView.spacing = kDefaultVerticalSpacing;
    switch (_layoutType) {
        case TTPullRefreshLayoutLeft:
            _verticalStackView.alignment = UIStackViewAlignmentLeading;
            break;
        case TTPullRefreshLayoutRight:
            _verticalStackView.alignment = UIStackViewAlignmentTrailing;
            break;
        case TTPullRefreshLayoutTop:
        case TTPullRefreshLayoutBottom:
            _verticalStackView.alignment = UIStackViewAlignmentCenter;
            break;
        default:
            break;
    }
}

- (void)checkStackView {
    if (_horizontalStackView) {
        [_horizontalStackView removeFromSuperview];
    }
}

- (void)layoutsHorizontalType {
    [self checkStackView];
    [self setupHorizontalStackView];
    [self setupVerticalStackView];
    UIView *firstView, *secondView;
    if (_layoutType == TTPullRefreshLayoutLeft) {
        firstView = _indicatorView;
        secondView = _verticalStackView;
    } else if(_layoutType == TTPullRefreshLayoutRight) {
        firstView = _verticalStackView;
        secondView = _indicatorView;
    }
    else {
        NSAssert(NO, @"Dispatch with wrong type...");
    }
    [_horizontalStackView addArrangedSubview:firstView];
    [_horizontalStackView addArrangedSubview:secondView];
    [self setupTitleLabels];
    [self addSubview:_horizontalStackView];
    [self setupConstraintsWithStackView:_horizontalStackView];
}

- (void)layoutsVerticalType {
    [self checkStackView];
    [self setupHorizontalStackView];
    [self setupVerticalStackView];
    if (_layoutType == TTPullRefreshLayoutTop) {
        [_verticalStackView addArrangedSubview:_indicatorView];
        [self setupTitleLabels];
    } else if(_layoutType == TTPullRefreshLayoutBottom) {
        [self setupTitleLabels];
        [_verticalStackView addArrangedSubview:_indicatorView];
    }
    else {
        NSAssert(NO, @"Dispatch with wrong type...");
    }
    [_horizontalStackView addArrangedSubview:_verticalStackView];
    [self addSubview:_horizontalStackView];
    [self setupConstraintsWithStackView:_horizontalStackView];
}

- (void)setupTitleLabels { //配置好verticalStackView里的titles label
    for (NSString *title in _titles) {
        UILabel *label = [[UILabel alloc] init];
        if ([_titles indexOfObject:title] == 0) {
            label.font = [UIFont systemFontOfSize:kGlobalTitleHeight];
            label.textColor = _titleColor;
        }
        else {
            label.font = [UIFont systemFontOfSize:kGlobalSubTitleHeight];
            label.textColor = _subTitleColor;
        }
        label.text = title;
        [_verticalStackView addArrangedSubview:label];
    }
    _guidingLabel.textColor = _titleColor;
    [_verticalStackView addArrangedSubview:_guidingLabel];
}

- (void)setupConstraintsWithStackView:(UIStackView *)stackView {
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [stackView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
    [stackView.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
    [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
}

- (void)indicatorViewStartAnimating {
    [UIView animateWithDuration:0.2 animations:^{
        CGAffineTransform rotateTransform = CGAffineTransformRotate(_indicatorView.transform, M_PI_2);
        _indicatorView.transform = rotateTransform;
    } completion:^(BOOL finished) {
        if (finished) {
            if (_refreshState == TTPullRefreshStateFinished) {
                _indicatorView.transform = CGAffineTransformMakeRotation(0);
                //刷新完成
            }
            else {
                [self indicatorViewStartAnimating];
            }
        }
    }];
}

- (void)setupGuidingLabelWithHiddenFlag:(BOOL)hidden {
    _guidingLabel.hidden = hidden;
    for (UIView *view in _verticalStackView.arrangedSubviews) {
        if (view != _guidingLabel && view != _indicatorView) {
            view.hidden = !hidden;
        }
    }
}

#pragma mark - scroolView observation helper
- (void)scrollViewDidScrollToOffset:(CGPoint)contentOffset {
    CGFloat offsetY = contentOffset.y;
    CGFloat refreshViewY = self.frame.origin.y;
    //判断是否可以执行refresh
    if (offsetY - refreshViewY <= kNeedsRefreshingSpacing&& refreshViewY < 0) {
        //开始imageView动画，执行刷新action
        if (_refreshState == TTPullRefreshStatePullToRefresh) {
            self.refreshState = TTPullRefreshStateLooseToRefresh;
        }
    }
    if ((offsetY < 0) && (offsetY - refreshViewY > kNeedsRefreshingSpacing)) {
        if (_refreshState == TTPullRefreshStateNone) {
            self.refreshState = TTPullRefreshStatePullToRefresh;
        }
        else if (_refreshState == TTPullRefreshStateLooseToRefresh) {
            self.refreshState = TTPullRefreshStatePullToRefresh;
        }
    }
}

- (void)scrollViewPanHandler:(id) sender {
    UIPanGestureRecognizer *pan = sender;
    if (pan.state == UIGestureRecognizerStateBegan) {
        [self scrollViewDidBeginDragging];
    }
    else if (pan.state == UIGestureRecognizerStateEnded) {
        [self scrollViewDidEndDragging];
    }
}

- (void)scrollViewDidEndDragging {
    if (_refreshState == TTPullRefreshStateLooseToRefresh) {
        [self indicatorViewStartAnimating];
        if (_action) {
            if ([_target respondsToSelector:_action]) {
                IMP imp = [_target methodForSelector:_action];
                void (*func)(id, SEL, TTPullRefreshView *) = (void *)imp;
                func(_target, _action, self);
            }
        }
        self.refreshState = TTPullRefreshStateRefreshing;
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _scrollView.contentInset = UIEdgeInsetsMake(_scrollViewOriginalInset.top + self.frame.size.height, 0, 0, 0);
        } completion:nil];
    }
}

- (void)scrollViewDidBeginDragging {
    if (_refreshState == TTPullRefreshStateNone || _refreshState == TTPullRefreshStatePullToRefresh) {
        if (!_didSetOriginalInsets) {
            _scrollViewOriginalInset = _scrollView.contentInset;
            _didSetOriginalInsets = YES;
        }
    }
}

@end

NS_ASSUME_NONNULL_END
