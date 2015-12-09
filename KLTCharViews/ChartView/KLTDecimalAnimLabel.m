//
//  KLTMoneyLabel.m
//
//
//  Created by 田凯 on 15/11/25.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "KLTDecimalAnimLabel.h"
static BOOL KLT_Global_DecimalLabelMask = NO;
static const CGFloat animSpeed = 0.02;

NSString * const kKLT_Global_DecimalLabelMaskStateChanged = @"com.netease.KLT.kGlobalDecimalLabelMaskStateChanged";
@implementation KLTDecimalAnimLabel{
    double _value;
    NSTimer *_timer;
    NSUInteger _times;
    NSUInteger _currentTimes;
    double _spaceValue;
}

+ (void)setDecimalMask:(BOOL)mask{
    if (mask == KLT_Global_DecimalLabelMask) {
        return;
    }
    KLT_Global_DecimalLabelMask = mask;
    [[NSNotificationCenter defaultCenter] postNotificationName:kKLT_Global_DecimalLabelMaskStateChanged object:nil];
    NSLog(@"KLT_Global_DecimalLabelMask changed %d",mask);
}
+ (BOOL)isDecimalMask{
    return KLT_Global_DecimalLabelMask;
}

- (instancetype)init{
    if (self = [super init]) {
        [self __initialize];
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self __initialize];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        [self __initialize];
    }
    return self;
}
- (void)__initialize{
    _conrollerMask = YES;
}

- (void)setValue:(double)value withAnimationDuration:(CGFloat)duration{
    _value = value;
    if (duration > animSpeed) {
        [_timer invalidate];
        _times = floor(duration / animSpeed);
        _currentTimes = 0;
        _spaceValue = _value / _times;
        _timer = [NSTimer scheduledTimerWithTimeInterval:animSpeed target:self selector:@selector(__timerTrigger:) userInfo:nil repeats:YES];
    }else{
        [self __setValueText:nil];
    }
}

- (void)__timerTrigger:(NSTimer *)time{
    NSString *text = nil;
    if ((self.needMask) || (!self.conrollerMask && KLT_Global_DecimalLabelMask)) {
        [_timer invalidate];
    }else{
        _currentTimes ++;
        if (_currentTimes == _times) {
            [_timer invalidate];
        }else{
            text = [NSString stringWithFormat:self.formatStr,_spaceValue*_currentTimes];
        }
    }
    [self __setValueText:text];
}

- (void)__setValueText:(NSString *)text{
    NSMutableAttributedString *attrValue = [[NSMutableAttributedString alloc] init];
    if (self.prefixStr) {
        [attrValue appendAttributedString:self.prefixStr];
    }
    if ((self.needMask) || (!self.conrollerMask && KLT_Global_DecimalLabelMask)) {
        [attrValue appendAttributedString:self.maskStr];
    }else{
        if (text == nil) {
            text = [NSString stringWithFormat:self.formatStr,_value];
        }
        [attrValue appendAttributedString:[[NSAttributedString alloc] initWithString:text attributes:[self attrDic]]];
    }
    if (self.suffixStr) {
        [attrValue appendAttributedString:self.prefixStr];
    }
    [self setAttributedText:attrValue];
}

#pragma mark Getter Setter
- (NSDictionary *)attrDic{
    if (_attrDic){
        return _attrDic;
    }
    _attrDic = @{
                 NSFontAttributeName : [UIFont systemFontOfSize:12],
                 NSForegroundColorAttributeName : [UIColor blackColor]
                 };
    return _attrDic;
}

- (NSString *)formatStr{
    if (_formatStr) {
        return _formatStr;
    }
    _formatStr = @"%.2lf";
    return _formatStr;
}

- (NSAttributedString *)maskStr{
    if (_maskStr) {
        return _maskStr;
    }
    _maskStr = [[NSAttributedString alloc] initWithString:@"****" attributes:[self attrDic]];
    return _maskStr;
}

@end
