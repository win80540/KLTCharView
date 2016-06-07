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
#define SAFEFLOAT(x) (isnan((x))?1:(x))
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
@property (strong, nonatomic) NSString *identity;
@property (strong, nonatomic) UIColor *lineColor;
@property (strong, nonatomic) UIColor *fillColor;
@property (assign, nonatomic) CGFloat lineWidth;
@property (strong, nonatomic) NSMutableArray<KLTLineChartPoint *> *points;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

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


- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (void)displayWithAnimation:(BOOL)isAnimation;
@end

#pragma mark - tip category

@protocol KLTLineChartTipViewDelegate<NSObject>
@optional
/**
 *  @brief 询问delegate需要显示的tipView
 *
 *  @param chartView 当前的lineChartView
 *  @param point     当前的询问的点的实例
 *  @param line      当前的询问的线的实例
 *  @param aRect     可见的范围CGRect结构
 *
 *  @discussion      应该根据参数中point.x,point.y和aRect来确定view的位置
 *
 *  @return 类型UIView *,tipView会添加到KLTLineChartView
 */
- (UIView *)lineChartView:(KLTLineChartView *)chartView tipViewOfPoint:(KLTLineChartPoint *)currentPoint inLine:(KLTLineChartLine *)currentLine avilibleRect:(CGRect)aRect;

@end

/**
 *  @brief 需要显示点的对应信息的Category
 */
@interface KLTLineChartPoint (KLTTipInfo)

@property (strong, nonatomic) NSString *identity;
/**
 *  @brief 需要携带的上下文，为生成TipView提供携带的信息
 */
@property (strong, nonatomic) id context;

@property (assign, nonatomic, readonly) CGFloat x;
@property (assign, nonatomic, readonly) CGFloat y;

@end

@interface KLTLineChartView (KLTTipInfo)

@property (weak,nonatomic)  id<KLTLineChartTipViewDelegate> delegateOfTipView;

@end

