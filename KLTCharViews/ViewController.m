//
//  ViewController.m
//  KLTCharViews
//
//  Created by 田凯 on 15/12/9.
//  Copyright © 2015年 netease. All rights reserved.
//

#import "ViewController.h"
#import "KLTColumnChartView.h"
#import "KLTLineChartView.h"
#import "KLTPieChartView.h"
#import "KLTRadarChartView.h"

@interface ViewController ()<KLTLineChartDataSource,KLTLineChartDelegate,KLTLineChartTipViewDelegate, KLTRadarChartViewDataSource, KLTRadarChartViewDelegate>
{
    
}
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) KLTPieChartView *pieView;
@property (strong, nonatomic) KLTLineChartView *lineChartView;
@property (strong, nonatomic) KLTColumnChartView *columnChartView;
@property (strong, nonatomic) KLTRadarChartView *radarChartView;
@property (strong, nonatomic) UIButton *refreshBtn;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.view addSubview:self.scrollView];
    WEAK_SELF(weakSelf);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.scrollView addSubview:self.radarChartView];
        [self.scrollView addSubview:self.columnChartView];
        [self.scrollView addSubview:self.lineChartView];
        [self.scrollView addSubview:self.pieView];
        [self.scrollView addSubview:self.refreshBtn];
        weakSelf.scrollView.contentSize = CGSizeMake(weakSelf.view.bounds.size.width, 770+50);
        [weakSelf refresh];
    });
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doTapRefreshBtn:(id)sender{
    [self refresh];
}

- (void)refresh{
    [self demo_pieChart];
    [self demo_lineChart];
    [self demo_columnChart];
    [self demo_radarChart];
}

- (void)demo_radarChart {
    self.radarChartView.dataSource = self;
    self.radarChartView.delegate = self;
    self.radarChartView.numberOfLatitude = 5;
    [self.radarChartView displayWithAnimation:YES];
}

- (void)demo_columnChart{
    KLTColumnChartView *columnChartView = self.columnChartView;
    
    NSMutableArray<KLTColumnChartItem *> *columnItems = [@[] mutableCopy];
    {
        KLTColumnChartItem *item = [[KLTColumnChartItem alloc] init];
        item.desc = @"32.98";
        item.value = 32.98;
        item.title = @"11-22";
        [columnItems addObject:item];
    }
    {
        KLTColumnChartItem *item = [[KLTColumnChartItem alloc] init];
        item.desc = @"15.98";
        item.value = 15.98;
        item.title = @"11-23";
        [columnItems addObject:item];
    }
    {
        KLTColumnChartItem *item = [[KLTColumnChartItem alloc] init];
        item.desc = @"-30.98";
        item.value = -30.98;
        item.title = @"11-24";
        [columnItems addObject:item];
    }
    {
        KLTColumnChartItem *item = [[KLTColumnChartItem alloc] init];
        item.desc = @"-20.98";
        item.value = -20.98;
        item.title = @"11-25";
        [columnItems addObject:item];
    }
    {
        KLTColumnChartItem *item = [[KLTColumnChartItem alloc] init];
        item.desc = @"30.98";
        item.value = 30.98;
        item.title = @"11-26";
        [columnItems addObject:item];
    }
    [columnChartView setColumns:columnItems];
    [columnChartView showWithAnimation:YES];
}

- (void)demo_lineChart{
    KLTLineChartView *lineChartView = self.lineChartView;
    [lineChartView setBackgroundColor:[UIColor whiteColor]];
    [lineChartView setNumberOfVerticalLines:2];
    [lineChartView setNumberOfHorizontalLines:5];
    [lineChartView setColorOfVerticalLines:[UIColor clearColor]];
    [lineChartView setColorOfHorizontalLines:[UIColor colorWithWhite:0.7 alpha:0.5]];
    lineChartView.dataSource = self;
    lineChartView.delegate = self;
    lineChartView.delegateOfTipView = self;
    
    NSMutableArray *lines = [@[] mutableCopy];
    {
        KLTLineChartLine *line = [[KLTLineChartLine alloc] init];
        line.fillColor = [UIColor colorWithRed:0.5 green:0.0 blue:0.1 alpha:1];
        line.lineColor = [UIColor colorWithRed:1 green:0.0 blue:0.1 alpha:1];
        NSMutableArray *points = [@[] mutableCopy];
        [points addObject:[[KLTLineChartPoint alloc] initWithValueOfHorizontal:0 vertical:-0.014]];
        [points addObject:[[KLTLineChartPoint alloc] initWithValueOfHorizontal:3 vertical:0.003]];
        [points addObject:[[KLTLineChartPoint alloc] initWithValueOfHorizontal:7 vertical:0.003]];
        [points addObject:[[KLTLineChartPoint alloc] initWithValueOfHorizontal:14 vertical:0.0050]];
        [points addObject:[[KLTLineChartPoint alloc] initWithValueOfHorizontal:20 vertical:0.0020]];
        {
            KLTLineChartPoint *point = [points lastObject];
            point.identity = @"卖入";
            point.context = @"阿斯顿发舒服";
        }
        [points addObject:[[KLTLineChartPoint alloc] initWithValueOfHorizontal:25 vertical:0.0010]];
        [points addObject:[[KLTLineChartPoint alloc] initWithValueOfHorizontal:30 vertical:-0.0030]];
        {
            KLTLineChartPoint *point = [points lastObject];
            point.identity = @"卖入2";
            point.context = @"阿斯顿发舒服";
        }
        [points addObject:[[KLTLineChartPoint alloc] initWithValueOfHorizontal:60 vertical:0.0056]];
        [points addObject:[[KLTLineChartPoint alloc] initWithValueOfHorizontal:70 vertical:0.0056]];
        {
            KLTLineChartPoint *point = [points lastObject];
            point.identity = @"卖出";
            point.context = @"阿斯顿发舒服";
        }
        line.points = points;
        [lines addObject:line];
    }
    {
        KLTLineChartLine *line = [[KLTLineChartLine alloc] init];
        line.fillColor = [UIColor clearColor];
        line.lineColor = [UIColor colorWithRed:0 green:0 blue:0.9 alpha:1];
        NSMutableArray *points = [@[] mutableCopy];
        [points addObject:[[KLTLineChartPoint alloc] initWithValueOfHorizontal:0 vertical:-0.0018]];
        [points addObject:[[KLTLineChartPoint alloc] initWithValueOfHorizontal:3 vertical:0.0038]];
        [points addObject:[[KLTLineChartPoint alloc] initWithValueOfHorizontal:7 vertical:0.002]];
        [points addObject:[[KLTLineChartPoint alloc] initWithValueOfHorizontal:14 vertical:0.0080]];
        [points addObject:[[KLTLineChartPoint alloc] initWithValueOfHorizontal:20 vertical:0.0030]];
        [points addObject:[[KLTLineChartPoint alloc] initWithValueOfHorizontal:25 vertical:0.0020]];
        [points addObject:[[KLTLineChartPoint alloc] initWithValueOfHorizontal:30 vertical:-0.0070]];
        [points addObject:[[KLTLineChartPoint alloc] initWithValueOfHorizontal:60 vertical:0.0096]];
        [points addObject:[[KLTLineChartPoint alloc] initWithValueOfHorizontal:70 vertical:0.0086]];
        line.points = points;
        [lines addObject:line];
    }
    [lineChartView setLines:lines];
    [lineChartView displayWithAnimation:YES];
}


- (void)demo_pieChart{
    KLTPieChartView *pieView = self.pieView;
    pieView.radius = 80;
    pieView.pieWidth = 30;
    //    pieView.value_100 = 350;
    pieView.showDescrition = YES;
    
    NSDictionary *attrDic = @{
                              NSFontAttributeName : [UIFont systemFontOfSize:12],
                              NSForegroundColorAttributeName : [UIColor blackColor]
                              };
    
    NSMutableArray *pieItems = [@[] mutableCopy];
    {
        KLTPieItem *item = [[KLTPieItem alloc] init];
        item.pieColor = [UIColor blueColor];
        item.value = 12.23;
        item.title = [[NSAttributedString alloc] initWithString:@"1TTTTT" attributes:attrDic];
        item.desc = [[NSAttributedString alloc] initWithString:@"1XXX" attributes:attrDic];
        [pieItems addObject:item];
    }
    {
        KLTPieItem *item = [[KLTPieItem alloc] init];
        item.pieColor = [UIColor cyanColor];
        item.value = 122.23;
        item.title = [[NSAttributedString alloc] initWithString:@"2TTT" attributes:attrDic];
        item.desc = [[NSAttributedString alloc] initWithString:@"2XXXXX" attributes:attrDic];
        [pieItems addObject:item];
    }
    {
        KLTPieItem *item = [[KLTPieItem alloc] init];
        item.pieColor = [UIColor yellowColor];
        item.value = 13.23;
        item.title = [[NSAttributedString alloc] initWithString:@"3TT" attributes:attrDic];
        item.desc = [[NSAttributedString alloc] initWithString:@"3XXXXX" attributes:attrDic];
        [pieItems addObject:item];
    }
    {
        KLTPieItem *item = [[KLTPieItem alloc] init];
        item.pieColor = [UIColor darkGrayColor];
        item.value = 42.23;
        item.title = [[NSAttributedString alloc] initWithString:@"4TTTTT" attributes:attrDic];
        item.desc = [[NSAttributedString alloc] initWithString:@"4XXX" attributes:attrDic];
        [pieItems addObject:item];
    }
    {
        KLTPieItem *item = [[KLTPieItem alloc] init];
        item.pieColor = [UIColor magentaColor];
        item.value = 2.23;
        item.title = [[NSAttributedString alloc] initWithString:@"6TTTTT" attributes:attrDic];
        item.desc = [[NSAttributedString alloc] initWithString:@"6XXX" attributes:attrDic];
        [pieItems addObject:item];
    }
    
    [pieView setPieItems:pieItems];
    [pieView displaywithAnimation:YES];
}
#pragma mark delegate
- (NSString *)titleOfHorizontalIndex:(NSUInteger)idx withValue:(double)value{
    return [NSString stringWithFormat:@"%.2lf At %ld",value,idx];
}
- (NSString *)titleOfVerticalIndex:(NSUInteger)idx withValue:(double)value{
    return [NSString stringWithFormat:@"%.2lf At %ld",value,idx];
}
- (UIColor *)colorForHorizontalSeparateLineOfIndex:(NSUInteger)idx{
    if (idx == 0) {
        return [UIColor redColor];
    }
    return [UIColor clearColor];
}
- (UIView *)lineChartView:(KLTLineChartView *)chartView tipViewOfPoint:(KLTLineChartPoint *)point inLine:(KLTLineChartLine *)line avilibleRect:(CGRect)rect{
    if (point.context) {
        UIView *view = [[UIView alloc] init];
        view.center = CGPointMake(point.x, point.y);
        view.bounds = CGRectMake(0, 0, 5, 5);
        view.backgroundColor = [UIColor redColor];
        return view;
    }
    return nil;
}

#pragma mark RadarDelegate

- (NSUInteger)numberOfData:(KLTRadarChartView *)radarView {
    return 2;
}

- (NSUInteger)numberOfDimensions:(KLTRadarChartView *)radarView {
    return 5;
}

- (KLTRadarChartDataDimension *)dimensionForIndex:(NSUInteger)idx dataIndex:(NSUInteger)dataIdx inView:(KLTRadarChartView *)radarChartView {
    KLTRadarChartDataDimension *data = [[KLTRadarChartDataDimension alloc] init];
    if (dataIdx == 0) {
         data.value = 5 + idx + idx % 2;
    } else {
        data.value = 5 + idx;
    }
    data.min = 2;
    data.max = 12;
    return data;
}


- (UIColor *)colorForBackgroundLatitudeAtIndex:(NSUInteger)idx total:(NSUInteger)total inView:(KLTRadarChartView *)radarChartView {
    if (idx % 2 == 0) {
        return [UIColor greenColor];
    }
    return [UIColor redColor];
}

- (UIColor *)colorForBackgroundLongitudeAtIndex:(NSUInteger)dimensionIdx total:(NSUInteger)total inView:(KLTRadarChartView *)radarChartView {
    if (dimensionIdx % 2 == 0) {
        return [UIColor redColor];
    }
    return [UIColor greenColor];
}

- (NSAttributedString *)titleForDimesionIdx:(NSUInteger)dimensionIdx inView:(KLTRadarChartView *)radarChartView {
    NSString *str = [NSString stringWithFormat:@"Title is %lu", (unsigned long)dimensionIdx];
    return [[NSAttributedString alloc] initWithString:str attributes:@{
                                                                NSFontAttributeName : [UIFont systemFontOfSize:12],
                                                                NSForegroundColorAttributeName : [UIColor blackColor]
                                                                }];
}

- (void)customBackgroundLatitudePath:(UIBezierPath *)path styleOfIndex:(NSUInteger)idx total:(NSUInteger)total inView:(KLTRadarChartView *)radarChartView {
    const CGFloat pattern[] = {2,2};
    [path setLineDash:pattern count:2 phase:0];
}
- (void)customLatitudePath:(UIBezierPath *)path styleOfIndex:(NSUInteger)idx dataIdx:(NSUInteger)dataIdx inView:(KLTRadarChartView *)radarChartView {
    const CGFloat pattern[] = {2,2};
    [path setLineDash:pattern count:2 phase:0];
}

- (UIColor *)colorForDimensionValueLongitudeAtIndex:(NSUInteger)dimensionIdx total:(NSUInteger)total dataIdx:(NSUInteger)dataIdx inView:(KLTRadarChartView *)radarChartView {
    return [UIColor redColor];
}

- (UIColor *)colorForDimensionValueLatitudeAtDataIdx:(NSUInteger)dataIdx inView:(KLTRadarChartView *)radarChartView {
    if (dataIdx == 0) {
        return [UIColor colorWithRed:0.4 green:0.1 blue:0.9 alpha:1];
    }
    return [UIColor colorWithRed:0.1 green:0.4 blue:0.5 alpha:1];
}

- (UIColor *)colorForDimensionValueFillAtDataIdx:(NSUInteger)dataIdx inView:(KLTRadarChartView *)radarChartView {
    if (dataIdx == 0) {
        return [UIColor colorWithRed:0.4 green:0.1 blue:0.9 alpha:0.5];
    }
    return [UIColor colorWithRed:0.1 green:0.4 blue:0.5 alpha:0.5];
}

- (UIView *)valueDescriptionViewForIdx:(NSUInteger)idx dataIdx:(NSUInteger)dataIdx data:(KLTRadarChartDataDimension *)data point:(CGPoint)point availableRect:(CGRect)avilableRect inView:(KLTRadarChartView *)radarChartView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
    view.backgroundColor = [UIColor redColor];
    view.center = point;
    return view;
}

#pragma mark Getter Setter
- (UIScrollView *)scrollView{
    if (_scrollView) {
        return _scrollView;
    }
    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    return _scrollView;
}
- (KLTRadarChartView *)radarChartView {
    if (_radarChartView) {
        return _radarChartView;
    }
    _radarChartView = [[KLTRadarChartView alloc] initWithFrame:CGRectMake(0, 20, 300,  200)];
    _columnChartView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    return _radarChartView;
}
- (KLTColumnChartView *)columnChartView{
    if (_columnChartView) {
        return _columnChartView;
    }
    _columnChartView = [[KLTColumnChartView alloc] initWithFrame:CGRectMake(0, 420, self.view.bounds.size.width, 150)];
    _columnChartView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    return _columnChartView;
}
- (KLTLineChartView *)lineChartView{
    if (_lineChartView) {
        return _lineChartView;
    }
    _lineChartView = [[KLTLineChartView alloc] initWithFrame:CGRectMake(0, 220, self.view.bounds.size.width, 200)];
    _lineChartView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    return _lineChartView;
}
- (KLTPieChartView *)pieView{
    if (_pieView) {
        return _pieView;
    }
    _pieView = [[KLTPieChartView alloc] initWithFrame:CGRectMake(0, 570, self.view.bounds.size.width, 200)];
    _pieView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    return _pieView;
}
- (UIButton *)refreshBtn{
    if (_refreshBtn) {
        return _refreshBtn;
    }
    _refreshBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 770, self.view.bounds.size.width, 50)];
    [_refreshBtn setTitle:@"Refresh" forState:UIControlStateNormal];
    [_refreshBtn addTarget:self action:@selector(doTapRefreshBtn:) forControlEvents:UIControlEventTouchUpInside];
    [_refreshBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    return _refreshBtn;
}
@end
