//
//  KLTColumnChart.m
//
//
//  Created by 田凯 on 15/11/23.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "KLTColumnChartView.h"
#import "KLTDecimalAnimLabel.h"

static const CGFloat autoComputeVRangeRate = 0.2; //纵向留空百分比
static const CGFloat verticalPadding = 15;
static const CGFloat horizontalPaddin = 15;
static const CGFloat titleDivHeight = 20;   //刻度文本框的高度
static const CGFloat descDivHeight = 21;    //描述文本框的高度
static const CGFloat spacePreColumn = 15;   //每个柱子的间距
static const CGFloat lineWidth = 1;
static const CGFloat maxColumnWidth = 20;   //每个柱子的最大宽度
static const CGFloat preOffsetTime = 0.05; //每个柱子开始动画的间隔时间
static const CGFloat animDuration = 0.5;
static const CGFloat cornerRadiu = 2.5; //柱形图圆角半径
@implementation KLTColumnChartItem

- (NSDictionary *)attrOfDesc{
    if (_attrOfDesc) {
        return _attrOfDesc;
    }
    _attrOfDesc = @{
                  NSFontAttributeName : [UIFont systemFontOfSize:12],
                  NSForegroundColorAttributeName : [UIColor blackColor]
                  };
    return _attrOfDesc;
}
- (NSDictionary *)attrOfTitle{
    if (_attrOfTitle) {
        return _attrOfTitle;
    }
    _attrOfTitle = @{
                     NSFontAttributeName : [UIFont systemFontOfSize:12],
                     NSForegroundColorAttributeName : [UIColor blackColor]
                     };
    return _attrOfTitle;
}

- (UIColor *)borderColor{
    if (_borderColor) {
        return _borderColor;
    }
    _borderColor = [UIColor clearColor];
    return _borderColor;
}

- (UIColor *)fillColor{
    if (_fillColor) {
        return _fillColor;
    }
    _fillColor = [UIColor blueColor];
    return _fillColor;
}

@end

@implementation KLTColumnChartView{
    BOOL _autoComputeRange;
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[UIColor whiteColor]];
        _autoComputeRange = YES;
        self.layer.masksToBounds = YES;
        _originValue = 0;
        _colorOfOriginLine = [UIColor grayColor];
    }
    return self;
}

- (void)showWithAnimation:(BOOL)isAnimation{
    CGFloat charHeight = CGRectGetHeight(self.bounds) - verticalPadding * 2 - titleDivHeight;
    CGFloat charWidth = CGRectGetWidth(self.bounds) - horizontalPaddin * 2;
    CGFloat vRate = charHeight / (_maxValue - _minValue);
    CGPoint originP = CGPointMake(horizontalPaddin, verticalPadding+(_maxValue - _originValue)*vRate);
    CGFloat lineWidthPixel = lineWidth / [UIScreen mainScreen].scale;
    
    NSMutableArray * columnsLayers = [@[] mutableCopy];
    NSMutableArray * descLbs = [@[] mutableCopy];
    
    WEAK_SELF(weakSelf);
    //添加原点线
    {
        CAShapeLayer * originLineLayer = [CAShapeLayer layer];
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:originP];
        [path addLineToPoint:CGPointMake(originP.x+charWidth, originP.y)];
        originLineLayer.path = path.CGPath;
        originLineLayer.lineWidth = lineWidthPixel;
        originLineLayer.strokeColor = _colorOfOriginLine.CGColor;
        [weakSelf.layer addSublayer:originLineLayer];
    }
    //添加柱形图
    CGFloat columnWidth = (charWidth - spacePreColumn * (_columns.count + 1)) / _columns.count;
    columnWidth = MAX(maxColumnWidth, columnWidth);
    [_columns enumerateObjectsUsingBlock:^(KLTColumnChartItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CAShapeLayer *columnLayer = [CAShapeLayer layer];
        CGPoint currentOriginP = CGPointMake(originP.x, obj.value > _originValue ? originP.y-lineWidthPixel : originP.y + lineWidthPixel);

        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, &CGAffineTransformIdentity, currentOriginP.x+(spacePreColumn*(idx+1))+columnWidth*idx, currentOriginP.y);
        CGPathAddArcToPoint(path, &CGAffineTransformIdentity, currentOriginP.x+(spacePreColumn*(idx+1))+columnWidth*idx, currentOriginP.y- (obj.value - _originValue)*vRate, currentOriginP.x+(spacePreColumn*(idx+1))+columnWidth*(idx+0.5), currentOriginP.y- (obj.value - _originValue)*vRate, cornerRadiu);
        CGPathAddArcToPoint(path, &CGAffineTransformIdentity, currentOriginP.x+(spacePreColumn*(idx+1))+columnWidth*(idx+1), currentOriginP.y- (obj.value - _originValue)*vRate, currentOriginP.x+(spacePreColumn*(idx+1))+columnWidth*(idx+1), currentOriginP.y, cornerRadiu);
        CGPathAddLineToPoint(path, &CGAffineTransformIdentity, currentOriginP.x+(spacePreColumn*(idx+1))+columnWidth*(idx+1), currentOriginP.y);
        
        columnLayer.path = path;
        columnLayer.lineWidth = lineWidthPixel;
        columnLayer.strokeColor = obj.borderColor.CGColor;
        columnLayer.fillColor = obj.fillColor.CGColor;
        [columnsLayers addObject:columnLayer];
        [weakSelf.layer addSublayer:columnLayer];
        
        CGPathRelease(path);
    }];
    //添加title文字
    [_columns enumerateObjectsUsingBlock:^(KLTColumnChartItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        KLTDecimalAnimLabel *lbTitle = [[KLTDecimalAnimLabel alloc] initWithFrame:CGRectMake(originP.x+(spacePreColumn*(idx+1))+columnWidth*idx, weakSelf.bounds.size.height - titleDivHeight, columnWidth, titleDivHeight)];
        lbTitle.textAlignment = NSTextAlignmentCenter;
        lbTitle.adjustsFontSizeToFitWidth = YES;
        lbTitle.attributedText = [[NSAttributedString alloc] initWithString:obj.title attributes:obj.attrOfTitle];
        [weakSelf addSubview:lbTitle];
    }];
    //添加desc文字
    [_columns enumerateObjectsUsingBlock:^(KLTColumnChartItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat y = originP.y- (obj.value - _originValue)*vRate;
        if (obj.value > _originValue) {
            y -= descDivHeight;
        }
        KLTDecimalAnimLabel *lbDesc = [[KLTDecimalAnimLabel alloc] initWithFrame:CGRectMake(originP.x+(spacePreColumn*(idx+1))+columnWidth*idx, y ,columnWidth, descDivHeight)];
        lbDesc.textAlignment = NSTextAlignmentCenter;
        lbDesc.adjustsFontSizeToFitWidth = YES;
        lbDesc.attributedText = [[NSAttributedString alloc] initWithString:obj.desc attributes:obj.attrOfDesc];
        [descLbs addObject:lbDesc];
        [weakSelf addSubview:lbDesc];
    }];
    
    if (isAnimation) {
        //柱形动画
        [columnsLayers enumerateObjectsUsingBlock:^(CAShapeLayer *  _Nonnull columnLayer, NSUInteger idx, BOOL * _Nonnull stop) {
            KLTColumnChartItem *obj = _columns[idx];
            CGPoint currentOriginP = CGPointMake(originP.x, obj.value > _originValue ? originP.y-lineWidthPixel : originP.y + lineWidthPixel);
            CAShapeLayer *maskLayer = [CAShapeLayer layer];
            maskLayer.lineWidth = columnWidth+lineWidthPixel;
            maskLayer.strokeColor = [UIColor clearColor].CGColor;
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(currentOriginP.x+(spacePreColumn*(idx+1))+columnWidth*(idx+0.5), currentOriginP.y)];
            [path addLineToPoint:CGPointMake(currentOriginP.x+(spacePreColumn*(idx+1))+columnWidth*(idx+0.5), currentOriginP.y- (obj.value - _originValue)*vRate)];
            maskLayer.path = path.CGPath;
            [columnLayer setMask:maskLayer];
            //添加动画
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(preOffsetTime * idx * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                maskLayer.strokeColor = [UIColor blackColor].CGColor;
                CABasicAnimation *strokeAnim = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
                strokeAnim.fromValue = @(0);
                strokeAnim.toValue = @(1);
                strokeAnim.duration = animDuration;
                strokeAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
                strokeAnim.removedOnCompletion = YES;
                [maskLayer addAnimation:strokeAnim forKey:@"strokeAnim"];
            });
        }];
        //文字动画
        [descLbs enumerateObjectsUsingBlock:^(KLTDecimalAnimLabel *  _Nonnull lbDesc, NSUInteger idx, BOOL * _Nonnull stop) {
            KLTColumnChartItem *obj = _columns[idx];
            lbDesc.text = @"";
            CGPoint endP;
            {
                CGFloat y = originP.y- (obj.value - _originValue)*vRate;
                if (obj.value > _originValue) {
                    y -= descDivHeight;
                }
                endP = CGPointMake(originP.x+(spacePreColumn*(idx+1))+columnWidth*idx + columnWidth /2, y + descDivHeight/2);
            }
            CGPoint beginP;
            {
                CGFloat y = originP.y;
                if (obj.value > _originValue) {
                    y -= descDivHeight;
                }
                beginP = CGPointMake(originP.x+(spacePreColumn*(idx+1))+columnWidth*idx + columnWidth /2, y + descDivHeight/2);
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(preOffsetTime * idx * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                lbDesc.attrDic = obj.attrOfDesc;
                [lbDesc setValue:obj.value withAnimationDuration:animDuration];
                CABasicAnimation *position = [CABasicAnimation animationWithKeyPath:@"position"];
                position.fromValue = [NSValue valueWithCGPoint:beginP];
                position.toValue = [NSValue valueWithCGPoint:endP];
                position.duration = animDuration;
                position.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
                position.removedOnCompletion = YES;
                [lbDesc.layer addAnimation:position forKey:@"animP"];
            });
        }];
        
    }
}

#pragma mark - getter setter

- (void)setColumns:(NSArray<KLTColumnChartItem *> *)columns{
    _columns = [columns copy];
    if (_autoComputeRange){
        __block double maxValue=0,minValue=0;
        [_columns enumerateObjectsUsingBlock:^(KLTColumnChartItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (maxValue <= obj.value) {
                maxValue = obj.value;
            }
            if (minValue >= obj.value){
                minValue = obj.value;
            }
        }];
        maxValue = maxValue * (1+autoComputeVRangeRate);
        minValue = minValue * (1+autoComputeVRangeRate);
        _maxValue = maxValue;
        _minValue = minValue;
    }
}
- (void)setMaxValue:(double)maxValue{
    _autoComputeRange = NO;
    _maxValue = maxValue;
}
- (void)setMinValue:(double)minValue{
    _autoComputeRange = NO;
    _minValue = minValue;
}

@end
