//
//  KLTPieCircleView.h
//
//
//  Created by 田凯 on 15/11/20.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef KLTChartView_h
#define KLTChartView_h
#define SafeFloat(x) (isnan((x))?1:(x))
#endif

#pragma mark - KLTPieItem
@interface KLTPieItem : NSObject
@property (strong , nonatomic) UIColor * pieColor;
@property (assign , nonatomic) double value;
@property (copy , nonatomic) NSAttributedString * title;
@property (copy , nonatomic) NSAttributedString * desc;
@end

#pragma mark - KLTPieCircleView
@interface KLTPieChartView : UIView
/*
 @brief 包含每个饼图块Model的数字
 */
@property (copy , nonatomic) NSArray<KLTPieItem *> *pieItems;
/*
 @brief 饼图初始位置
 */
@property (assign , nonatomic)  double startAnglePercent;
/*
 @brief 饼的宽度
 */
@property (assign , nonatomic) CGFloat pieWidth;
/*
 @brief 饼最外圈的半径
 */
@property (assign , nonatomic) CGFloat radius;
/*
 @brief 100%对应的数值
 @discussion 如果不设,value_100会根据item的value相加
 */
@property (assign , nonatomic) CGFloat value_100;
/*
 @brief 描边颜色
 */
@property (strong, nonatomic) UIColor *pieBorderColor;


@property (assign , nonatomic) BOOL showDescrition;
@property (strong , nonatomic) UIColor *colorOfDescLine;



- (void)beginAnim;
- (void)displaywithAnimation:(BOOL)isAnimation;
@end
