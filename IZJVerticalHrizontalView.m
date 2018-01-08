//
//  IZJVerticalHrizontalView.m
//  IZJScrollView
//
//  Created by LZY on 2018/1/6.
//  Copyright © 2018年 coodingOrg. All rights reserved.
//

#import "IZJVerticalHrizontalView.h"

@interface IZJVerticalHrizontalView()<UICollectionViewDelegateFlowLayout,UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *contentView;

@property (nonatomic, strong) NSMutableDictionary *scrollViewDics;

@property (nonatomic, strong) NSMutableDictionary *scrollViewDefaultContentInsetTops;

//子元素停驻图
@property (nonatomic, strong) NSMutableArray *itemSegments;

//子元素停驻图高度
@property (nonatomic, strong) NSMutableArray *itemSegmentsHeight;

@property (nonatomic, strong) UIScrollView *headerContentView;

@property (nonatomic, strong) UIScrollView *segmentContentView;

@end

static char CurrentScrollViewKey;
static CGFloat const DefaultSegmentHeight = 44;
static CGFloat const DefaultItemSegmentHeight = 30;

@implementation IZJVerticalHrizontalView
{
    CGFloat        _itemCount;
    CGFloat        _currentContentOffsetY;
    UIScrollView  *_currentScrollView;
    NSInteger      _currentItemIndex;
    CGFloat        _headerHeight;
    CGFloat        _segmentHeight;
    UIView        *_headerView;
    UIView        *_segmentView;
    CGFloat       _totalHeaderHeight;
    BOOL          _isAutoScroll;
    BOOL          _isReloadSection;
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
    [self.scrollViewDics removeAllObjects];

    for (int i = 0; i < _itemCount; i++) {

        if (i == 0) {
            UIScrollView *s = [self.dataSource verticalHrizontalView:self contentScrollViewAtIndex:i];
            [self.scrollViewDics setObject:s forKey:@(i)];
            [self.scrollViewDefaultContentInsetTops setObject:@(s.contentInset.top) forKey:@(i)];
        }
        
        if ([self.delegate respondsToSelector:@selector(verticalHrizontalView:itemSegmentViewAtIndex:)]) {
            UIView *v = [self.delegate verticalHrizontalView:self itemSegmentViewAtIndex:i];
            CGFloat itemSegmentHeight = DefaultItemSegmentHeight;
            if ([self.delegate respondsToSelector:@selector(heightOfItemSegmentViewInVerticalHrizontalView:atIndex:)]) {
               itemSegmentHeight = [self.delegate heightOfItemSegmentViewInVerticalHrizontalView:self atIndex:i];
            }
            [self.itemSegments addObject:v];
            [self.itemSegmentsHeight addObject:@(itemSegmentHeight)];
        }else{
            [self.itemSegmentsHeight addObject:@(0)];
        }
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

- (void)reloadHrizontalItemAtIndex:(NSInteger)index
{
    _isAutoScroll = YES;
    _isReloadSection = YES;
    [self addHeaderViewToBaseView];
    [self addSegmentViewToBaseView];
    [self addItemSegmentViewToBaseView];
    
    UIScrollView *scrollView = [self.dataSource verticalHrizontalView:self contentScrollViewAtIndex:index];
    [self.scrollViewDics setObject:scrollView forKey:@(index)];
    [self.scrollViewDefaultContentInsetTops setObject:@(scrollView.contentInset.top) forKey:@(index)];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [UIView performWithoutAnimation:^{
        [self.contentView reloadItemsAtIndexPaths:@[indexPath]];
    }];

    [self addObserverToScrollAsCurrentViewWithIndex:index];
    if (self.headerContentView.superview != self) {
            [self addHeaderViewToCurrentView];
    }
    if (self.segmentContentView && self.segmentContentView.superview != self) {
            [self addSegmentViewToCurrentView];
    }
    _isAutoScroll = NO;
    _isReloadSection = NO;
    
}

//滑动到第几个水平视图
- (void)scrollToHorizontalItemAtIndex:(NSInteger)index animation:(BOOL)animation
{
    if (index < 0 || index > _itemCount - 1) {
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
    CGFloat contentInsetTop = [[self.scrollViewDefaultContentInsetTops objectForKey:@(self.currentVerticalHrizontalItemIndex)] floatValue];
    CGFloat itemSegmentHeight  =  [self.itemSegmentsHeight[self.currentVerticalHrizontalItemIndex] floatValue];
    self.headerContentView.frame = CGRectMake(0, -_totalHeaderHeight - contentInsetTop - itemSegmentHeight , self.bounds.size.width, _headerHeight);
    [_currentScrollView addSubview:self.headerContentView];
    
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
        [self.segmentContentView removeFromSuperview];
    }
    CGFloat contentInsetTop = [[self.scrollViewDefaultContentInsetTops objectForKey:@(self.currentVerticalHrizontalItemIndex)] floatValue];
    CGFloat itemSegmentHeight  =  [self.itemSegmentsHeight[self.currentVerticalHrizontalItemIndex] floatValue];
    
    self.segmentContentView.frame = CGRectMake(0, -_segmentHeight - contentInsetTop - itemSegmentHeight, self.bounds.size.width, _segmentHeight);
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


- (void)addItemSegmentViewToCurrentViewAtIndex:(NSInteger)index
{
    if (self.itemSegments.count == 0) {
        return;
    }
    UIScrollView *containerView = [self.scrollViewDics objectForKey:@(index)];
    UIView *itemSegment = self.itemSegments[index];
    CGFloat itemSegmentHeight  =  [self.itemSegmentsHeight[index] floatValue];
    CGFloat contentInsetTop = [[self.scrollViewDefaultContentInsetTops objectForKey:@(index)] floatValue];
    if ((-containerView.contentOffset.y <= _segmentHeight + self.segmentViewEdgeToTop + contentInsetTop + itemSegmentHeight) && containerView == _currentScrollView) {
        CGFloat subY = _segmentHeight + self.segmentViewEdgeToTop + contentInsetTop + itemSegmentHeight + containerView.contentOffset.y;
        itemSegment.frame = CGRectMake(0, -itemSegmentHeight - contentInsetTop + subY, self.bounds.size.width, itemSegmentHeight);
    }else{
        itemSegment.frame = CGRectMake(0, -itemSegmentHeight - contentInsetTop, self.bounds.size.width, itemSegmentHeight);
    }
    if (itemSegment.superview && itemSegment.superview != containerView) {
        [itemSegment removeFromSuperview];
    }
    [containerView addSubview:itemSegment];
    [containerView layoutIfNeeded];
}


- (void)addItemSegmentViewToBaseView
{
    
    if (self.itemSegments.count == 0) {
        return;
    }
    UIView *itemSegment = self.itemSegments[self.currentVerticalHrizontalItemIndex];
    CGFloat itemSegmentHeight  =  [self.itemSegmentsHeight[self.currentVerticalHrizontalItemIndex] floatValue];
    CGRect rect = CGRectZero;
    if (itemSegment.superview && itemSegment.superview != self) {
        CGFloat offsetY = [itemSegment.superview convertRect:itemSegment.frame toView:self].origin.y;
        if (offsetY < self.segmentViewEdgeToTop + _segmentHeight) {
            offsetY = self.segmentViewEdgeToTop + _segmentHeight;
        }
        rect = CGRectMake(0, offsetY, self.bounds.size.width, itemSegmentHeight);
        [itemSegment removeFromSuperview];
    }
    if (!itemSegment.superview) {
        itemSegment.frame = rect;
        [self addSubview:itemSegment];
        self.clipsToBounds = YES;
        [self layoutIfNeeded];
    }
}

- (void)addObserverToScrollAsCurrentViewWithIndex:(NSInteger)index
{
    if (_currentScrollView) {
        [_currentScrollView removeObserver:self forKeyPath:@"contentOffset"];
    }
    _currentScrollView = [self.scrollViewDics objectForKey:@(index)];
    _currentItemIndex = index;
    [_currentScrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:&CurrentScrollViewKey];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (context == & CurrentScrollViewKey) {
         CGPoint tableOffset = [[change objectForKey:@"new"] CGPointValue];
        _currentContentOffsetY = tableOffset.y;
        CGFloat contentInsetTop = [[self.scrollViewDefaultContentInsetTops objectForKey:@(self.currentVerticalHrizontalItemIndex)] floatValue];
        CGFloat itemSegmentHeight = [self.itemSegmentsHeight[self.currentVerticalHrizontalItemIndex] floatValue];
        if (_isAutoScroll) {
            return;
        }
        if (-_currentContentOffsetY <= _segmentHeight + self.segmentViewEdgeToTop + contentInsetTop + itemSegmentHeight) {
            [self addSegmentViewToBaseView];
            [self addItemSegmentViewToBaseView];
            [self addHeaderViewToBaseView];
        }else{
            [self addHeaderViewToCurrentView];
            [self addSegmentViewToCurrentView];
            [self addItemSegmentViewToCurrentViewAtIndex:self.currentVerticalHrizontalItemIndex];
        }
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
    UIScrollView *scrollView = [self.scrollViewDics objectForKey:@(indexPath.row)];
    if (!scrollView) {
        scrollView = [self.dataSource verticalHrizontalView:self contentScrollViewAtIndex:indexPath.row];
        [self.scrollViewDics setObject:scrollView forKey:@(indexPath.row)];
    }
    CGFloat contentInsetTop = 0;
    NSNumber *c = [self.scrollViewDefaultContentInsetTops objectForKey:@(indexPath.row)];
    if (!c) {
        contentInsetTop = scrollView.contentInset.top;
        [self.scrollViewDefaultContentInsetTops setObject:@(contentInsetTop) forKey:@(indexPath.row)];
    }else{
        contentInsetTop = [c floatValue];
    }
    
    CGFloat itemSegmentHeight = [self.itemSegmentsHeight[indexPath.row] floatValue];
    
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
    [scrollView setContentInset:UIEdgeInsetsMake(_totalHeaderHeight + contentInsetTop + itemSegmentHeight, 0, 0, 0)];
    [scrollView layoutIfNeeded];
    CGFloat oldOffSetY = _currentScrollView.contentOffset.y;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (oldOffSetY >= -(_segmentHeight + self.segmentViewEdgeToTop + contentInsetTop + itemSegmentHeight)) {
            scrollView.contentOffset = CGPointMake(0, -(_segmentHeight + self.segmentViewEdgeToTop + contentInsetTop + itemSegmentHeight));
        }else{
            scrollView.contentOffset =  CGPointMake(0, oldOffSetY - (itemSegmentHeight - [self.itemSegmentsHeight[self.currentVerticalHrizontalItemIndex] floatValue]));
        }
    });
    if (!_isReloadSection) {
        [self addItemSegmentViewToCurrentViewAtIndex:indexPath.row];
    }

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
    [self addItemSegmentViewToCurrentViewAtIndex:self.currentVerticalHrizontalItemIndex];
    if (self.delegate && [self.delegate respondsToSelector:@selector(verticalHrizontalViewDidScroll:)]) {
        [self.delegate verticalHrizontalViewDidScroll:scrollView];
    }
    
}


- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    NSInteger index = scrollView.contentOffset.x / scrollView.bounds.size.width;
    if (index < 0 || index > _itemCount - 1) {
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
    if (index < 0 || index > _itemCount - 1) {
        return;
    }
    [self addObserverToScrollAsCurrentViewWithIndex:index];
    [self addSegmentViewToCurrentView];
    [self addHeaderViewToCurrentView];
    
    _isAutoScroll = NO;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(verticalHrizontalViewDidEndScroll:AtIndex:)]) {
        [self.delegate verticalHrizontalViewDidEndScroll:scrollView AtIndex:index];
    }
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
    return _currentItemIndex;
}

- (UIScrollView *)currentItemScrollView
{
    if (_currentScrollView) {
        return _currentScrollView;
    }else{
        return nil;
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
        _contentView.backgroundColor = [UIColor whiteColor];
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


- (NSMutableDictionary *)scrollViewDics
{
    if (!_scrollViewDics) {
        _scrollViewDics = @{}.mutableCopy;
    }
    return _scrollViewDics;
}


- (NSMutableDictionary *)scrollViewDefaultContentInsetTops
{
    if (!_scrollViewDefaultContentInsetTops) {
        _scrollViewDefaultContentInsetTops = @{}.mutableCopy;
    }
    return _scrollViewDefaultContentInsetTops;
}


- (NSMutableArray *)itemSegments
{
    if (!_itemSegments) {
        _itemSegments = @[].mutableCopy;
    }
    return _itemSegments;
}


- (NSMutableArray *)itemSegmentsHeight
{
    if (!_itemSegmentsHeight) {
        _itemSegmentsHeight = @[].mutableCopy;
    }
    return _itemSegmentsHeight;
}


- (void)dealloc
{
    if (_currentScrollView) {
        [_currentScrollView removeObserver:self forKeyPath:@"contentOffset"];
    }
}

@end
