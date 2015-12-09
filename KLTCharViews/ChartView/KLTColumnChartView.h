//
//  KLTColumnChart.h
//  
//
//  Created by 田凯 on 15/11/23.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KLTColumnChartItem : NSObject
/*
 @brief 刻度
 */
@property (copy , nonatomic) NSString * title;
/*
 @brief 标注
 */
@property (copy , nonatomic) NSString * desc;
/*
 @brief 刻度样式
 */
@property (copy , nonatomic) NSDictionary * attrOfTitle;
/*
 @brief 标注样式
 */
@property (copy , nonatomic) NSDictionary * attrOfDesc;
/*
 @brief 边框色
 */
@property (strong,nonatomic) UIColor *borderColor;
/*
 @brief 填充色
 */
@property (strong,nonatomic) UIColor *fillColor;
@property (assign, nonatomic) double value;
@end


@interface KLTColumnChartView : UIView
/*
 @brief 最大值
 @discussion 不设值时会根据columns自动计算
 */
@property (assign, nonatomic) double maxValue;
/*
 @brief 最小值
 @discussion 不设值时会根据columns自动计算
 */
@property (assign, nonatomic) double minValue;
/*
 @brief 柱子的数据原型
 */
@property (copy, nonatomic) NSArray<KLTColumnChartItem*> * columns;
/*
 @brief 起点值
 */
@property (assign, nonatomic) double originValue;
/*
 @brief 起点线的颜色
 */
@property (strong,nonatomic) UIColor *colorOfOriginLine;

- (void)showWithAnimation:(BOOL)isAnimation;
@end
