//
//  KLTRadarChartView.h
//  KLTCharViews
//
//  Created by 田凯 on 3/1/17.
//  Copyright © 2017 netease. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol KLTRadarChartViewDelegate;
@protocol KLTRadarChartViewDataSource;
@class KLTRadarChartDataDimension;

@interface KLTRadarChartView : UIView

@property (nonatomic, weak) id<KLTRadarChartViewDelegate> delegate;
@property (nonatomic, weak) id<KLTRadarChartViewDataSource> dataSource;
/// 背景色，默认透明
@property (nonatomic, copy) UIColor *bgColor;
/// 背景经线的线宽，单位px，默认1，优先级低于代理方法
@property (nonatomic, assign) float widthOfLongitude;
/// 背景纬线的线宽，单位px，默认1，优先级低于代理方法
@property (nonatomic, assign) float widthOfLatitude;
/// 纬线个数，默认1
@property (nonatomic, assign) NSUInteger numberOfLatitude;

- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;

- (void)displayWithAnimation:(BOOL)isAnimation;

@end

@protocol KLTRadarChartViewDelegate <NSObject>
@optional
/**
 * @brief 背景经线颜色
 *
 * @discussion 默认#BBBBBB
 *
 */
- (UIColor *)colorForBackgroundLongitudeAtIndex:(NSUInteger)dimensionIdx total:(NSUInteger)total inView:(KLTRadarChartView *)radarChartView;
/**
 * @brief 背景纬线线颜色
 *
 * @discussion 默认#EEEEEE
 *
 */
- (UIColor *)colorForBackgroundLatitudeAtIndex:(NSUInteger)idx total:(NSUInteger)total inView:(KLTRadarChartView *)radarChartView;
/**
 * @brief 定制背景经线的path代理（如虚线样式，线宽），默认直线
 */
- (void)customBackgroundLongitudePath:(UIBezierPath *)path styleOfIndex:(NSUInteger)idx total:(NSUInteger)total inView:(KLTRadarChartView *)radarChartView;;
/**
 * @brief 定制背景纬线的path代理（如虚线样式，线宽），默认直线
 */
- (void)customBackgroundLatitudePath:(UIBezierPath *)path styleOfIndex:(NSUInteger)idx total:(NSUInteger)total inView:(KLTRadarChartView *)radarChartView;;

/**
 * @brief 每个维度的值的经线颜色
 *
 * @discussion 默认透明
 *
 */
- (UIColor *)colorForDimensionValueLongitudeAtIndex:(NSUInteger)dimensionIdx total:(NSUInteger)total dataIdx:(NSUInteger)dataIdx inView:(KLTRadarChartView *)radarChartView;;
/**
 * @brief 值的纬度的颜色
 *
 * @discussion 默认黑色
 *
 */
- (UIColor *)colorForDimensionValueLatitudeAtDataIdx:(NSUInteger)dataIdx inView:(KLTRadarChartView *)radarChartView;;
/**
 * @brief 每个数据源的填充色的值的经线颜色
 *
 * @discussion 默认透明
 *
 */
- (UIColor *)colorForDimensionValueFillAtDataIdx:(NSUInteger)dataIdx inView:(KLTRadarChartView *)radarChartView;;

//- (CGSize)titleOffsetForDimesionAtIndex:(NSUInteger)dimensionIdx;
//- (CGSize)titleOffsetForDimesionValueAtIndex:(NSUInteger)dimensionIdx;

/**
 * @brief 定制经线的path代理（如虚线样式，线宽），默认直线, 默认宽度2px
 */
- (void)customLongitudePath:(UIBezierPath *)path
               styleOfIndex:(NSUInteger)idx
                      total:(NSUInteger)total
                    dataIdx:(NSUInteger)dataIdx
                     inView:(KLTRadarChartView *)radarChartView;;
/**
 * @brief 定制纬线的path代理（如虚线样式，线宽），默认直线, 默认宽度2px
 */
- (void)customLatitudePath:(UIBezierPath *)path dataIdx:(NSUInteger)dataIdx inView:(KLTRadarChartView *)radarChartView; ;

/**
 * @brief 定制各个顶点的描述视图
 * 
 * @param idx 该顶点的维度索引
 * @param dataIdx 该顶点的所在数据的索引
 * @param data 该顶点的数据模型实例
 * @param point 该顶点的坐标
 * @param avilableRect 有效范围，如果所绘制的view的Rect超出该范围将不可见
 * @param radarChartView 该定点的所在的雷达图
 *
 * @return UIView * 定制的描述视图
 *
 */
- (nullable UIView *)valueDescriptionViewForIdx:(NSUInteger)idx
                       dataIdx:(NSUInteger)dataIdx
                          data:(KLTRadarChartDataDimension *)data
                         point:(CGPoint)point
                 availableRect:(CGRect)avilableRect
                        inView:(KLTRadarChartView *)radarChartView;

@end

@protocol KLTRadarChartViewDataSource <NSObject>

/**
 * @brief 分几个维度
 *
 * @discussion 返回值必须大于等于2，否则报错
 *
 */
- (NSUInteger)numberOfDimensions:(KLTRadarChartView *)radarView;

/**
 * @brief 有几份数据
 */
- (NSUInteger)numberOfData:(KLTRadarChartView *)radarView;

- (KLTRadarChartDataDimension *)dimensionForIndex:(NSUInteger)idx dataIndex:(NSUInteger)dataIdx inView:(KLTRadarChartView *)radarChartView;;

@optional
/**
 * @brief 每个维度的刻度标题
 */
- (nullable NSAttributedString *)titleForDimesionIdx:(NSUInteger)dimensionIdx inView:(KLTRadarChartView *)radarChartView;;

@end


@interface KLTRadarChartDataDimension : NSObject

@property (nonatomic, assign) double value;
/// 显示的标题,默认nil
@property (nonatomic, copy, nullable) NSAttributedString *title;
/// 最大值, 默认1
@property (nonatomic, assign) double max;
/// 最小值, 默认0
@property (nonatomic, assign) double min;

@end

NS_ASSUME_NONNULL_END
