//
//  KLTLineChartView.h
//  
//
//  Created by 田凯 on 15/11/21.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef KLTChartView_h
#define KLTChartView_h
#define SafeFloat(x) (isnan((x))?1:(x))
#endif

@protocol KLTLineChartDataSource <NSObject>
@optional
- (NSString *)titleOfHorizontalIndex:(NSUInteger)idx withValue:(double)value;
- (NSString *)titleOfVerticalIndex:(NSUInteger)idx withValue:(double)value;
@end
@protocol KLTLineChartDelegate <NSObject>
@optional
- (CGSize)titleOffsetOfHorizontalIndex:(NSUInteger)idx;
- (CGSize)titleOffsetOfVerticalIndex:(NSUInteger)idx;
- (UIColor *)colorForHorizontalSeparateLineOfIndex:(NSUInteger)idx;
- (UIColor *)colorForVerticalSeparateLineOfIndex:(NSUInteger)idx;
/*
 @brief 定制背景横线的path代理（如虚线样式，线宽）
 */
- (void)customHorizontalSeparateLinePath:(UIBezierPath *)path styleOfIndex:(NSUInteger)idx;
/*
 @brief 定制背景竖线的path代理（如虚线样式，线宽）
 */
- (void)customVerticalSeparateLinePath:(UIBezierPath *)path styleOfIndex:(NSUInteger)idx;
@end

@interface KLTLineChartPoint : NSObject
@property (assign, nonatomic) double valueOfHorizontal;
@property (assign, nonatomic) double valueOfVertical;
+ (instancetype)pointWithHorizontalValue:(double)valueOfHorizontal verticalValue:(double)valueOfVertical;
- (instancetype)initWithValueOfHorizontal:(double)valueOfHorizontal vertical:(double)valueOfVertical;
@end

@interface KLTLineChartLine : NSObject
@property (strong, nonatomic) UIColor *lineColor;
@property (strong, nonatomic) UIColor *fillColor;
@property (strong, nonatomic) NSMutableArray<KLTLineChartPoint *> *points;
@end

@interface KLTLineChartView : UIView
@property (weak,nonatomic)  id<KLTLineChartDataSource> dataSource;

@property (weak,nonatomic)  id<KLTLineChartDelegate> delegate;

@property (strong,nonatomic) NSArray<KLTLineChartLine *> *lines;

/*
 @brief 横向网格线个数
 */
@property (assign,nonatomic) NSUInteger numberOfHorizontalLines;
/*
 @brief 纵向网格线个数
 */
@property (assign,nonatomic) NSUInteger numberOfVerticalLines;

/*
 @brief 横向网格线的颜色
 @discussion 如果实现了 colorForHorizontalSeparateLineOfIndex: 代理方法，该值无效
 */
@property (strong,nonatomic) UIColor *colorOfHorizontalLines;
/*
 @brief 纵向网格线的颜色
 @discussion 如果实现了 colorForVerticalSeparateLineOfIndex: 代理方法，该值无效
 */
@property (strong,nonatomic) UIColor *colorOfVerticalLines;

/*
 @brief Y轴刻度的属性
 */
@property (strong,nonatomic) NSDictionary *attributeOfVerticalText;
/*
 @brief X轴刻度的属性
 */
@property (strong,nonatomic) NSDictionary *attributeOfHorizontalText;

/*
 maxValueOfHorizontal，minValueOfHorizontal，maxValueOfVertical，minValueOfVertical可以都不设值，
 都不设的时候会根据数据计算图表的X轴和Y轴范围，
 */
/*
 @brief X轴最大值
 */
@property (assign,nonatomic) double maxValueOfHorizontal;
/*
 @brief X轴最小值
 */
@property (assign,nonatomic) double minValueOfHorizontal;
/*
 @brief Y轴最大值
 */
@property (assign,nonatomic) double maxValueOfVertical;
/*
 @brief Y轴最小值
 */
@property (assign,nonatomic) double minValueOfVertical;


- (void)displayWithAnimation:(BOOL)isAnimation;
@end
