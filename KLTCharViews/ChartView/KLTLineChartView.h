//
//  KLTLineChartView.h
//
//
//  Created by 田凯 on 15/11/21.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef SAFEFLOAT
#define SAFEFLOAT(x) (isnan((x))?0:(x))
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
@property (strong, nonatomic) NSString *identity;   //line的标识符号，默认设置随机UUID
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
/**
 *  是否已经绑定数据
 */
@property (nonatomic, assign) BOOL isBinded;
/**
 *  是否需要渐变色
 */
@property (nonatomic, assign) BOOL needGradient;

/**
 *  折线部分的宽，高，原点坐标
 */
@property (nonatomic, assign, readonly) CGFloat chartWidth;
@property (nonatomic, assign, readonly) CGFloat chartHeight;
@property (nonatomic, assign, readonly) CGPoint originP;

- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (void)displayWithAnimation:(BOOL)isAnimation;
@end

#pragma mark - tip category

@protocol KLTLineChartTipViewDelegate<NSObject>
@optional
/**
 *  @brief 询问delegateOfTipView需要显示的tipView
 *
 *  @param chartView 当前的lineChartView
 *  @param point     当前的询问的点的实例
 *  @param line      当前的询问的线的实例
 *  @param aRect     可见的范围CGRect结构
 *
 *  @discussion      应该根据参数中point.x,point.y和aRect来确定view的位置,不保证在主线程，代理中如果有涉及UI修改需要自己保证主线程
 *
 *  @return 类型UIView *,tipView会添加到KLTLineChartView
 */
- (UIView *)lineChartView:(KLTLineChartView *)chartView tipViewOfPoint:(KLTLineChartPoint *)currentPoint inLine:(KLTLineChartLine *)currentLine avilibleRect:(CGRect)aRect;

/**
 *  @brief 当showNoDataTips标志为YES时，询问delegateOfTipView需要显示的NodataTipView
 *
 *  @param chartView 当前的lineChartView
 *  @param aRect     可见的范围CGRect结构
 *
 *  @return 应该根据参数中的aRect来确定view的位置，保证在主线程
 */
- (UIView *)lineChartView:(KLTLineChartView *)chartView nodataTipViewOfAvilibleRect:(CGRect)aRect;

typedef NS_ENUM(NSInteger, KLTLineChartTouchEventType) {
    KLTLineChartTouchEventBegan = 0,
    KLTLineChartTouchEventMoved = 1,
    KLTLineChartTouchEventEnded = 2,
    KLTLineChartTouchEventCancelled = 3
};

/**
 *  @brief 询问delegate 用户touch某个点的时候需要显示的tipView
 *  !important            UIView是临时的，touch事件变动就会消失
 *
 *  @param chartView      当前的lineChartView
 *  @param touchedPoint   当前触摸点的实例
 *  @param touchedLine    当前的询问的线的实例
 *  @param eventType      当前的时间类型 @see KLTLineChartTouchEventType
 *  @param aRect          可见的范围CGRect结构
 *
 *  @discussion  应该根据参数中point.x,point.y和aRect来确定view的位置,不保证在主线程，代理中如果有涉及UI修改需要自己保证主线程
 *
 *  @return 类型UIView *,tipView会添加到KLTLineChartView
 */
- (UIView *)lineChartView:(KLTLineChartView *)chartView autoRemoveTouchTipViewOfPoint:(KLTLineChartPoint *)touchedPoint inLine:(KLTLineChartLine *)touchedLine eventType:(KLTLineChartTouchEventType)eventType avilibleRect:(CGRect)aRect;

/**
 *  @brief 询问delegate 用户touch某个点的时候需要显示的tipView
 *  !important            UIView不是临时的，需要手动清理 @see clearTouchTipView
 *
 *  @param chartView      当前的lineChartView
 *  @param touchedPoint   当前触摸点的实例
 *  @param touchedLine    当前的询问的线的实例
 *  @param eventType      当前的时间类型 @see KLTLineChartTouchEventType
 *  @param aRect          可见的范围CGRect结构
 *
 *  @discussion  应该根据参数中point.x,point.y和aRect来确定view的位置,不保证在主线程，代理中如果有涉及UI修改需要自己保证主线程
 *
 *  @return 类型UIView *,tipView会添加到KLTLineChartView
 */
- (UIView *)lineChartView:(KLTLineChartView *)chartView touchTipViewOfPoint:(KLTLineChartPoint *)touchedPoint inLine:(KLTLineChartLine *)touchedLine eventType:(KLTLineChartTouchEventType)eventType avilibleRect:(CGRect)aRect;
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
/**
 *  @brief  显示无数据提示框
 */
@property (nonatomic, assign) BOOL showNoDataTips;

/**
 *  @brief 清理固定显示的 tipView, 所有line的tipview都会清理
 *
 */
- (void)clearTipView;

/**
 *  @brief 清理所有保留显示的 touchTipView, 所有line的touchTipView都会清理
 *
 */
- (void)clearTouchTipView;
/**
 *  @brief 清理指定line 的 tipView
 *
 * @param identity 需要清理的line的标识符
 *
 */
- (void)clearTipViewForLineIdentity:(NSString *)identity;

/**
 *  @brief 清理指定line 的 touchTipView
 *
 * @param identity 需要清理的line的标识符
 *
 */
- (void)clearTouchTipViewForLineIdentity:(NSString *)identity;

@end

