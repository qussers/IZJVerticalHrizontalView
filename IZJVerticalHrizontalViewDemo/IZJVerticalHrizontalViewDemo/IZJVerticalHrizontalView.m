//
//  IZJVerticalHrizontalView.m
//  IZJScrollView
//
//  Created by 李志宇 on 2018/1/6.
//  Copyright © 2018年 coodingOrg. All rights reserved.
//

#import "IZJVerticalHrizontalView.h"

@interface IZJVerticalHrizontalView()<UICollectionViewDelegateFlowLayout,UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *contentView;

@property (nonatomic, strong) NSMutableArray *scrollViews;

@property (nonatomic, strong) UIScrollView *headerContentView;

@property (nonatomic, strong) UIScrollView *segmentContentView;

@end

static char CurrentScrollViewKey;
static CGFloat const DefaultSegmentHeight = 44;

@implementation IZJVerticalHrizontalView
{
    CGFloat        _itemCount;
    CGFloat        _currentContentOffsetY;
    UIScrollView  *_currentScrollView;
    CGFloat        _headerHeight;
    CGFloat        _segmentHeight;
    UIView        *_headerView;
    UIView        *_segmentView;
    CGFloat       _totalHeaderHeight;
    BOOL          _isAutoScroll;
}
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setUp];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setUp];
    }
    return self;
}

- (void)setUp
{
    _itemCount = 0;
    _segmentHeight = 0;
    _segmentView = nil;
    _segmentViewEdgeToTop = 0;
    _isAutoScroll = NO;
    [self addSubview:self.contentView];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    
    [self addConstraint:leftConstraint];
    [self addConstraint:rightConstraint];
    [self addConstraint:topConstraint];
    [self addConstraint:bottomConstraint];
    
}

- (void)reloadData
{
    _itemCount    = [self.dataSource numberOfItemsInVerticalHrizontalView:self];
    _headerHeight = [self.dataSource heightOfHeaderViewInVerticalHrizontalView:self];
    _headerView   = [self.dataSource headerViewInVerticalHrizontalView:self];
    for (UIView *v in self.headerContentView.subviews) {
        [v removeFromSuperview];
    }
    if ([self.dataSource respondsToSelector:@selector(segmentViewInVerticalHrizontalView:)]) {
        _segmentView = [self.delegate segmentViewInVerticalHrizontalView:self];
        for (UIView *v  in self.segmentContentView.subviews) {
            [v removeFromSuperview];
        }
        if ([self.dataSource respondsToSelector:@selector(heightOfSegmentViewInVerticalHrizontalView:)]) {
            _segmentHeight = [self.delegate heightOfSegmentViewInVerticalHrizontalView:self];
        }else{
            _segmentHeight = DefaultSegmentHeight;
        }
    }
    _totalHeaderHeight = _headerHeight + _segmentHeight;
    [self.scrollViews removeAllObjects];
    for (int i = 0; i < _itemCount; i++) {
        UIScrollView *s = [self.dataSource verticalHrizontalView:self contentScrollViewAtIndex:i];
        [self.scrollViews addObject:s];
    }
    [self addObserverToScrollAsCurrentViewWithIndex:0];
    [self.contentView reloadData];
    dispatch_async(dispatch_get_main_queue(), ^{
        _headerView.frame = CGRectMake(0, 0, self.bounds.size.width, _headerHeight);
        [self.headerContentView addSubview:_headerView];
        [self.headerContentView setContentSize:CGSizeMake(self.bounds.size.width + 0.00001, _headerHeight)];
         [self addHeaderViewToCurrentView];
        if (_segmentView) {
            _segmentView.frame = CGRectMake(0, 0, self.bounds.size.width, _segmentHeight);
            [self.segmentContentView addSubview:_segmentView];
            [self.segmentContentView setContentSize:CGSizeMake(self.bounds.size.width + 0.00001, _segmentHeight)];
            [self addSegmentViewToCurrentView];
        }
    });
   
}

//滑动到第几个水平视图
- (void)scrollToHorizontalItemAtIndex:(NSInteger)index animation:(BOOL)animation
{
    if (index < 0 || index > self.scrollViews.count - 1) {
        return;
    }
    _isAutoScroll = YES;
    [self.contentView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:animation];
    if (animation) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _isAutoScroll = NO;
        });
    }else{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _isAutoScroll = NO;
            [self addObserverToScrollAsCurrentViewWithIndex:index];
            [self addSegmentViewToCurrentView];
            [self addHeaderViewToCurrentView];
        });
    }
}

#pragma mark - private
- (void)addHeaderViewToCurrentView
{
    
    if (self.headerContentView.superview && self.headerContentView.superview == _currentScrollView) {
        return;
    }
    if (self.headerContentView.superview) {
        [self.headerContentView removeFromSuperview];
    }
    self.headerContentView.frame = CGRectMake(0, -_totalHeaderHeight, self.bounds.size.width, _headerHeight);
    [_currentScrollView addSubview:self.headerContentView];
    [_currentScrollView layoutIfNeeded];
}

- (void)addHeaderViewToBaseView
{
    CGRect rect = CGRectZero;
    if (self.headerContentView.superview && self.headerContentView.superview != self) {
        CGFloat offsetY = [self.headerContentView.superview convertRect:self.headerContentView.frame toView:self].origin.y;
        rect = CGRectMake(0, offsetY, self.bounds.size.width, _headerHeight);
        [self.headerContentView removeFromSuperview];
    }
    if (!self.headerContentView.superview) {
        self.headerContentView.frame = rect;
        [self addSubview:self.headerContentView];
        self.clipsToBounds = YES;
        [self layoutIfNeeded];
    }
}

- (void)addSegmentViewToCurrentView
{
    if (!_segmentView) {
        return;
    }
    if (-_currentContentOffsetY <= _segmentHeight + self.segmentViewEdgeToTop) {
        return;
    }
    if (self.segmentContentView.superview && self.segmentContentView.superview == _currentScrollView) {
        return;
    }
    
    if (self.segmentContentView.superview ) {
        [self.headerContentView removeFromSuperview];
    }
    self.segmentContentView.frame = CGRectMake(0, -_segmentHeight, self.bounds.size.width, _segmentHeight);
    [_currentScrollView addSubview:self.segmentContentView];
    [_currentScrollView layoutIfNeeded];
}

- (void)addSegmentViewToBaseView
{
    if (!_segmentView) {
        return;
    }
    CGRect rect = CGRectZero;
    if (self.segmentContentView.superview && self.segmentContentView.superview != self) {
        CGFloat offsetY = [self.segmentContentView.superview convertRect:self.segmentContentView.frame toView:self].origin.y;
        if (offsetY < self.segmentViewEdgeToTop) {
            offsetY = self.segmentViewEdgeToTop;
        }
        rect = CGRectMake(0, offsetY, self.bounds.size.width, _segmentHeight);
        [self.segmentContentView removeFromSuperview];
    }
    if (!self.segmentContentView.superview) {
        self.segmentContentView.frame = rect;
        [self addSubview:self.segmentContentView];
        self.clipsToBounds = YES;
        [self layoutIfNeeded];
    }
}

- (void)addObserverToScrollAsCurrentViewWithIndex:(NSInteger)index
{
    if (_currentScrollView) {
        [_currentScrollView removeObserver:self forKeyPath:@"contentOffset"];
    }
    _currentScrollView = self.scrollViews[index];
    [_currentScrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:&CurrentScrollViewKey];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (context == & CurrentScrollViewKey) {
         CGPoint tableOffset = [[change objectForKey:@"new"] CGPointValue];
        _currentContentOffsetY = tableOffset.y;
        if (_isAutoScroll) {
            return;
        }
        if (-_currentContentOffsetY <= _segmentHeight + self.segmentViewEdgeToTop) {
            [self addSegmentViewToBaseView];
        }else{
            [self addSegmentViewToCurrentView];
        }
        [self addHeaderViewToCurrentView];
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - UICollectionViewDataSource && UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _itemCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    UIScrollView *scrollView = self.scrollViews[indexPath.row];
    NSArray *subs = cell.contentView.subviews;
    if (subs && subs.count > 0) {
        UIView *v = subs.firstObject;
        if (v != scrollView) {
            [v removeFromSuperview];
            goto end;
        }
    }else{
    end:{
        [cell.contentView addSubview:scrollView];
        scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
        NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
        [cell.contentView addConstraint:leftConstraint];
        [cell.contentView addConstraint:rightConstraint];
        [cell.contentView addConstraint:topConstraint];
        [cell.contentView addConstraint:bottomConstraint];
       }
    }
    [scrollView setContentInset:UIEdgeInsetsMake(_totalHeaderHeight, 0, 0, 0)];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_currentScrollView.contentOffset.y >= -(_segmentHeight + self.segmentViewEdgeToTop)) {
             scrollView.contentOffset = CGPointMake(0, -(_segmentHeight + self.segmentViewEdgeToTop));
        }else{
             scrollView.contentOffset = _currentScrollView.contentOffset;
        }
    });
    [cell layoutIfNeeded];
    return cell;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return collectionView.bounds.size;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    _isAutoScroll = YES;
    [self addSegmentViewToBaseView];
    [self addHeaderViewToBaseView];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(verticalHrizontalViewDidScroll:)]) {
        [self.delegate verticalHrizontalViewDidScroll:scrollView];
    }
    
}


- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    NSInteger index = scrollView.contentOffset.x / scrollView.bounds.size.width;
    if (index < 0 || index > self.scrollViews.count - 1) {
        return;
    }
    [self addObserverToScrollAsCurrentViewWithIndex:index];
    [self addSegmentViewToCurrentView];
    [self addHeaderViewToCurrentView];
    
    _isAutoScroll = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger index = scrollView.contentOffset.x / scrollView.bounds.size.width;
    if (index < 0 || index > self.scrollViews.count - 1) {
        return;
    }
    [self addObserverToScrollAsCurrentViewWithIndex:index];
    [self addSegmentViewToCurrentView];
    [self addHeaderViewToCurrentView];
    
    _isAutoScroll = NO;
}

#pragma mark - setter
- (CGFloat)segmentViewEdgeToTop
{
    if (!_segmentView) {
        return 0;
    }else{
        return _segmentViewEdgeToTop;
    }
}

#pragma mark - getter
- (NSInteger)currentVerticalHrizontalItemIndex
{
    if (_currentScrollView) {
        return [self.scrollViews indexOfObject:_currentScrollView];
    }else{
        return -1;
    }
}

#pragma mark - lazy
- (UICollectionView *)contentView
{
    if (!_contentView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing      = 0;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _contentView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        [_contentView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        _contentView.dataSource = self;
        _contentView.delegate   = self;
        _contentView.pagingEnabled = YES;
        _contentView.alwaysBounceVertical = NO;
        _contentView.alwaysBounceHorizontal = NO;
        _contentView.showsVerticalScrollIndicator = NO;
        _contentView.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 10.0, *)) {
            _contentView.prefetchingEnabled = NO;
        }
    }
    return _contentView;
}

- (UIScrollView *)headerContentView
{
    if (!_headerContentView) {
        _headerContentView = [[UIScrollView alloc] init];
    }
    return _headerContentView;
}

- (UIScrollView *)segmentContentView
{
    if (!_segmentContentView) {
        _segmentContentView = [[UIScrollView alloc] init];
    }
    return _segmentContentView;
}


- (NSMutableArray *)scrollViews
{
    if (!_scrollViews) {
        _scrollViews = @[].mutableCopy;
    }
    return _scrollViews;
}

- (void)dealloc
{
    if (_currentScrollView) {
        [_currentScrollView removeObserver:self forKeyPath:@"contentOffset"];
    }
}

@end
