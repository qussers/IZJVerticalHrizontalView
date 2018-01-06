//
//  IZJVerticalHrizontalView.h
//  IZJScrollView
//
//  Created by 李志宇 on 2018/1/6.
//  Copyright © 2018年 coodingOrg. All rights reserved.
//

#import <UIKit/UIKit.h>
@class IZJVerticalHrizontalView;

@protocol IZJVerticalHrizontalViewDataSource <NSObject>

@required;
//水平子视图数量
- (NSInteger)numberOfItemsInVerticalHrizontalView:(IZJVerticalHrizontalView *)verticalHrizontalView;

//水平子视图
- (UIScrollView *)verticalHrizontalView:(IZJVerticalHrizontalView *)verticalHrizontalView contentScrollViewAtIndex:(NSInteger)index;

//垂直顶部视图
- (UIView *)headerViewInVerticalHrizontalView:(IZJVerticalHrizontalView *)verticalHrizontalView;

//垂直顶部视图高度
- (CGFloat)heightOfHeaderViewInVerticalHrizontalView:(IZJVerticalHrizontalView *)verticalHrizontalView;


@end

@protocol IZJVerticalHrizontalViewDelegate <NSObject>


@optional;
//停驻视图
- (UIView *)segmentViewInVerticalHrizontalView:(IZJVerticalHrizontalView *)verticalHrizontalView;

//停驻视图高度
- (CGFloat)heightOfSegmentViewInVerticalHrizontalView:(IZJVerticalHrizontalView *)verticalHrizontalView;

//水平切换偏移
- (void)verticalHrizontalViewDidScroll:(UIScrollView *)scrollView;

@end


@interface IZJVerticalHrizontalView : UIView

@property (nonatomic, weak) id<IZJVerticalHrizontalViewDataSource> dataSource;

@property (nonatomic, weak) id<IZJVerticalHrizontalViewDelegate> delegate;

@property (nonatomic, assign, readonly) NSInteger currentVerticalHrizontalItemIndex;

//停住图距离顶部偏移量，没有停住图时，不要设置 默认为0
@property (nonatomic, assign) CGFloat segmentViewEdgeToTop;

//刷新
- (void)reloadData;

//滑动到第几个水平视图
- (void)scrollToHorizontalItemAtIndex:(NSInteger)index animation:(BOOL)animation;

@end
