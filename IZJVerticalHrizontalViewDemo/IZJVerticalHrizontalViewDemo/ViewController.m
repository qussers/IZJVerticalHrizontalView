//
//  ViewController.m
//  IZJVerticalHrizontalViewDemo
//
//  Created by 李志宇 on 2018/1/6.
//  Copyright © 2018年 coodingOrg. All rights reserved.
//

#import "ViewController.h"
#import "IZJVerticalHrizontalView.h"
@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,IZJVerticalHrizontalViewDelegate,IZJVerticalHrizontalViewDataSource>

@property (nonatomic, strong) IZJVerticalHrizontalView *mainView;

@property (nonatomic, strong) NSMutableArray *tableViews;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    if (@available(iOS 11.0, *)) {
        UIScrollView.appearance.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }else{
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    self.mainView = [[IZJVerticalHrizontalView alloc]initWithFrame:self.view.bounds];
    self.mainView.dataSource = self;
    self.mainView.delegate = self;
    [self.view addSubview:self.mainView];
    self.tableViews = @[].mutableCopy;
    
    for (int i = 0; i < 10; i++) {
        UITableView *tableview = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        [tableview registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell2"];
        tableview.dataSource = self;
        tableview.delegate = self;
        [self.tableViews addObject:tableview];
    }
    
    [self.mainView reloadData];
}


- (void)btnClick
{
    NSLog(@"Hello! Scroll to last");
    [self.mainView scrollToHorizontalItemAtIndex:self.tableViews.count - 1 animation:YES];
}

#pragma mark - IZJVerticalHrizontalViewDelegate,IZJVerticalHrizontalViewDataSource

- (NSInteger)numberOfItemsInVerticalHrizontalView:(IZJVerticalHrizontalView *)verticalHrizontalView
{
    return 10;
}

- (UIScrollView *)verticalHrizontalView:(IZJVerticalHrizontalView *)verticalHrizontalView contentScrollViewAtIndex:(NSInteger)index
{
    return self.tableViews[index];
}

- (UIView *)headerViewInVerticalHrizontalView:(IZJVerticalHrizontalView *)verticalHrizontalView
{
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = [UIColor yellowColor];
    return v;
}

- (CGFloat)heightOfHeaderViewInVerticalHrizontalView:(IZJVerticalHrizontalView *)verticalHrizontalView
{
    return 300;
}

//可选
- (UIView *)segmentViewInVerticalHrizontalView:(IZJVerticalHrizontalView *)verticalHrizontalView
{
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.backgroundColor = [UIColor grayColor];
    [b setTitle:@"Click SegmentView" forState:UIControlStateNormal];
    [b addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (CGFloat)heightOfSegmentViewInVerticalHrizontalView:(IZJVerticalHrizontalView *)verticalHrizontalView
{
    return 44;
}


//可选
- (UIView *)verticalHrizontalView:(IZJVerticalHrizontalView *)verticalHrizontalView itemSegmentViewAtIndex:(NSInteger)index
{
    UIView *v = [[UIView alloc] init];
    if (index %2 == 0) {
        v.backgroundColor = [UIColor redColor];
    }else{
        v.backgroundColor = [UIColor yellowColor];
    }
    return v;
}

- (CGFloat)heightOfItemSegmentViewInVerticalHrizontalView:(IZJVerticalHrizontalView *)verticalHrizontalView atIndex:(NSInteger)index
{
    return 30;
}

#pragma mark - UITableViewDelegate,UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell2" forIndexPath:indexPath];
        cell.textLabel.text = [NSString stringWithFormat:@"我是水平的cell%@    快【横向】滑动我",@(indexPath.row)];
        return cell;
    
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
