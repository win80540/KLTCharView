//
//  KLTMoneyLabel.h
//
//
//  Created by 田凯 on 15/11/25.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
extern NSString * const kKLT_Global_DecimalLabelMaskStateChanged;

@interface KLTDecimalAnimLabel : UILabel
/*
 @brief 金额的富文本属性
 */
@property (strong,nonatomic) NSDictionary *attrDic;
/*
 @brief 前缀NSAttributedString
 */
@property (strong,nonatomic) NSAttributedString *prefixStr;
/*
 @brief 后缀NSAttributedString
 */
@property (strong,nonatomic) NSAttributedString *suffixStr;
/*
 @brief 隐藏金额时的代替文本NSAttributedString
 @discussion 默认使用attrDic和"****"生产的maskStr
 */
@property (strong,nonatomic) NSAttributedString *maskStr;
/*
 @brief 金额的格式化字符串
 @discussion 默认使用@"%.2lf"
 */
@property (strong,nonatomic) NSString *formatStr;
/*
 @brief 是否自己控制显示or隐藏金额,当该值为NO时，label将受全局控制
 */
@property (assign,nonatomic) BOOL conrollerMask;
/*
 @brief 显示or隐藏金额
 */
@property (assign,nonatomic) BOOL needMask;


+ (void)setDecimalMask:(BOOL)mask;
+ (BOOL)isDecimalMask;

- (void)setValue:(double)value withAnimationDuration:(CGFloat)duration;

@end
