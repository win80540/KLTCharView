//
//  KLTLineChartView.m
//
//
//  Created by 田凯 on 15/11/21.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "KLTLineChartView.h"

static const CGFloat horizontalTitleSpace = 21; //x轴标题的默认高度
static const CGFloat verticalTitleSpace = 50; //y轴标题的默认宽度
static const CGFloat horizontalPadding = 15;
static const CGFloat verticalPadding = 15;
static const CGFloat widthOfBGLine = 1; //表格的网格线宽度
static const CGFloat widthOfLine = 1; //折线宽度
static const CGFloat autoComputeVRangeMAXRate = 0.2; //顶部留空百分比
static const CGFloat autoComputeVRangeMINRate = 0.2; //底部留空百分比
static const CGFloat autoComputeHRangeMAXRate = 0.0; //左部留空百分比
static const CGFloat autoComputeHRangeMINRate = 0.0; //右部留空百分比

#pragma mark - Interface

#pragma mark Private Class
@interface KLTLineChartLineBGView : UIView
@property (strong,nonatomic) KLTLineChartLine *line;
@property (assign,nonatomic) CGPoint originP;
@property (copy,nonatomic) UIBezierPath *path;
@end
@interface KLTLineChartLineView : UIView
@property (strong,nonatomic) KLTLineChartLine *line;
@property (assign,nonatomic) CGPoint originP;
@property (strong,nonatomic) KLTLineChartLineBGView *bgView;
- (void)buildUI;
@end
#pragma mark Public Class

@interface KLTLineChartPoint (){
    
}
@property (assign, nonatomic) CGFloat x;
@property (assign, nonatomic) CGFloat y;
@end

@interface KLTLineChartView (){
    CGFloat _chartWidth ;
    CGFloat _chartHeight ;
    CGPoint _originP ;
    BOOL _autoComputeVRange;
    BOOL _autoComputeHRange;
}
@property (strong,nonatomic) UIView *containerView;
@property (strong,nonatomic) CAShapeLayer *bgLayer;
@property (assign,nonatomic) double valueOfPreHorizontalGird;
@property (assign,nonatomic) double valueOfPreVerticalGird;
@end
#pragma mark - Implemetation

#pragma mark Private Class
@implementation KLTLineChartLineBGView
- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}
- (void)layoutSubviews{
    //加入渐变
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    [gradientLayer setFrame:self.bounds];
    [gradientLayer setColors:@[
                               (id)[UIColor blackColor].CGColor,
                               (id)[UIColor clearColor].CGColor
                               ]];
    [gradientLayer setStartPoint:CGPointMake(.5,0)];
    [gradientLayer setEndPoint:CGPointMake(.5, 1)];
    //用渐变作为mask layer
    self.layer.mask = gradientLayer;
}
- (void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, _line.fillColor.CGColor);
    CGContextSetStrokeColorWithColor(context, _line.lineColor.CGColor);
    //画填充色
    KLTLineChartPoint *startP =  [_line.points objectAtIndex:0];
    KLTLineChartPoint *endP = [_line.points lastObject];
    [_path addLineToPoint:CGPointMake(endP.x, _originP.y)];
    [_path addLineToPoint:CGPointMake(startP.x, _originP.y)];
    [_path addLineToPoint:CGPointMake(startP.x, startP.y)];
    [_path fill];
}
@end

@implementation KLTLineChartLineView
- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}
- (void)buildUI{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [_line.points enumerateObjectsUsingBlock:^(KLTLineChartPoint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0) {
            [path moveToPoint:CGPointMake(obj.x, obj.y)];
        }else{
            [path addLineToPoint:CGPointMake(obj.x, obj.y)];
        }
    }];
    
    if (![_line.fillColor isEqual:[UIColor clearColor]]){
        //画出渐变填充色
        _bgView = [[KLTLineChartLineBGView alloc] initWithFrame:self.bounds];
        _bgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _bgView.line = self.line;
        _bgView.originP = self.originP;
        _bgView.path = path;
        [self addSubview:_bgView];
    }
    
    //画出折线
    CAShapeLayer *lineShaperLayer = [CAShapeLayer layer];
    lineShaperLayer.path = path.CGPath;
    lineShaperLayer.lineWidth = widthOfLine;
    lineShaperLayer.strokeColor = self.line.lineColor.CGColor;
    lineShaperLayer.fillColor = [UIColor clearColor].CGColor;
    [self.layer addSublayer:lineShaperLayer];
}

@end
#pragma mark Public Class

@implementation KLTLineChartPoint

+ (instancetype)pointWithHorizontalValue:(double)valueOfHorizontal verticalValue:(double)valueOfVertical{
    return [[self alloc] initWithValueOfHorizontal:valueOfHorizontal vertical:valueOfVertical];
}
- (instancetype)initWithValueOfHorizontal:(double)valueOfHorizontal vertical:(double)valueOfVertical;{
    self = [super init];
    if (self) {
        _valueOfHorizontal = valueOfHorizontal;
        _valueOfVertical = valueOfVertical;
    }
    return self;
}

@end


@implementation KLTLineChartLine
- (UIColor *)lineColor{
    if (_lineColor) {
        return _lineColor;
    }
    _lineColor = [UIColor redColor];
    return _lineColor;
}
- (UIColor *)fillColor{
    if (_fillColor) {
        return _fillColor;
    }
    _fillColor = [UIColor clearColor];
    return _fillColor;
}
@end



@implementation KLTLineChartView

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

- (void)displayWithAnimation:(BOOL)isAnimation{
    [self setNeedsDisplay];
    
    _chartWidth = self.bounds.size.width - verticalTitleSpace-horizontalPadding*2;
    _chartHeight = self.bounds.size.height - (horizontalTitleSpace+verticalPadding)*2;
    _originP = CGPointMake(verticalTitleSpace+horizontalPadding, _chartHeight+verticalPadding+horizontalTitleSpace);
    
    WEAK_SELF(weakSelf);
    //清理view
     [_containerView removeFromSuperview];
    //重新生产contanerView
    _containerView = [[UIView alloc] initWithFrame:CGRectMake(_originP.x, verticalPadding+horizontalTitleSpace, _chartWidth, _chartHeight)];
    [_containerView setBackgroundColor:[UIColor clearColor]];
    [self addSubview:_containerView];
    
    //画出每一条线
    [self.lines enumerateObjectsUsingBlock:^(KLTLineChartLine * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       [_containerView addSubview:[weakSelf createLineView:obj]];
    }];

    if (isAnimation) {
        //动画
        CAShapeLayer *makeLayer = [CAShapeLayer layer];
        makeLayer.lineWidth = _chartHeight;
        makeLayer.strokeColor = [UIColor blackColor].CGColor;
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(0, _chartHeight/2.0)];
        [path addLineToPoint:CGPointMake(_chartWidth, _chartHeight/2.0)];
        makeLayer.path = path.CGPath;
        _containerView.layer.mask = makeLayer;
        
        CABasicAnimation *maskAnim = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        maskAnim.fromValue = @(0);
        maskAnim.toValue = @(1);
        maskAnim.duration = 2;
        maskAnim.removedOnCompletion = YES;
        maskAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [makeLayer addAnimation:maskAnim forKey:@"maskLayerAnimation"];
    }
}

#pragma mark Private Method
//设置一些初始化参数
- (void)__initialize{
    [self setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1]];
    [self setUserInteractionEnabled:YES];
    _colorOfHorizontalLines = [UIColor colorWithWhite:0.8 alpha:1];
    _colorOfVerticalLines = [UIColor colorWithWhite:0.8 alpha:1];
    _numberOfHorizontalLines = 5;
    _numberOfVerticalLines = 5;
    _maxValueOfHorizontal = 100;
    _minValueOfHorizontal = 0;
    _maxValueOfVertical = 100;
    _minValueOfVertical = -100;
    NSDictionary *attrDic = @{
                              NSFontAttributeName : [UIFont systemFontOfSize:12],
                              NSForegroundColorAttributeName : [UIColor blackColor]
                              };
    _attributeOfHorizontalText = attrDic;
    _attributeOfVerticalText = attrDic;
    _autoComputeVRange = YES;
    _autoComputeHRange = YES;
    [self rangeChanged];
}

- (void)rangeChanged{
    //计算横纵单元格的值
    _valueOfPreHorizontalGird = (_maxValueOfHorizontal - _minValueOfHorizontal) / (_numberOfVerticalLines-1);
    _valueOfPreVerticalGird = (_maxValueOfVertical - _minValueOfVertical) / (_numberOfHorizontalLines-1);
}

//自动计算图表y的范围
- (void)autoComputeVRage{
    __block double minV=DBL_MAX,maxV=DBL_MIN;
    //取得最大最小值
    [_lines enumerateObjectsUsingBlock:^(KLTLineChartLine * _Nonnull line, NSUInteger lineIdx, BOOL * _Nonnull lineStop) {
        [line.points enumerateObjectsUsingBlock:^(KLTLineChartPoint * _Nonnull point, NSUInteger pointIdx, BOOL * _Nonnull pointStop) {
            if(point.valueOfVertical >= maxV){
                maxV = point.valueOfVertical;
            }
            if (point.valueOfVertical <= minV) {
                minV = point.valueOfVertical;
            }
        }];
    }];
    double rangeV = maxV - minV;
    //修改刻度范围
    _maxValueOfVertical = maxV+autoComputeVRangeMAXRate*rangeV;
    _minValueOfVertical = minV-autoComputeVRangeMINRate*rangeV;
    [self rangeChanged];
}
//自动计算图表x的范围
- (void)autoComputeHRage{
    __block double minH=DBL_MAX,maxH=DBL_MIN;
    //取得最大最小值
    [_lines enumerateObjectsUsingBlock:^(KLTLineChartLine * _Nonnull line, NSUInteger lineIdx, BOOL * _Nonnull lineStop) {
       [line.points enumerateObjectsUsingBlock:^(KLTLineChartPoint * _Nonnull point, NSUInteger pointIdx, BOOL * _Nonnull pointStop) {
           if(point.valueOfHorizontal >= maxH){
               maxH = point.valueOfHorizontal;
           }
           if (point.valueOfHorizontal <= minH) {
               minH = point.valueOfHorizontal;
           }
       }];
    }];
    double rangeH = maxH - minH;
    //修改刻度范围
    _maxValueOfHorizontal = maxH+autoComputeHRangeMAXRate*rangeH;
    _minValueOfHorizontal = minH-autoComputeHRangeMINRate*rangeH;
    [self rangeChanged];
}

- (KLTLineChartLineView *)createLineView:(KLTLineChartLine *)line{
    //屏幕的点与值的比例
    CGFloat xRate = (_maxValueOfHorizontal - _minValueOfHorizontal)/_chartWidth;
    CGFloat yRate = (_maxValueOfVertical - _minValueOfVertical)/_chartHeight;
    //按比例计算出UI坐标点
    [line.points enumerateObjectsUsingBlock:^(KLTLineChartPoint * _Nonnull point, NSUInteger idx, BOOL * _Nonnull stop) {
        point.x = (point.valueOfHorizontal - _minValueOfHorizontal) / xRate;
        point.y = _chartHeight - (point.valueOfVertical - _minValueOfVertical) / yRate ;
    }];
    //添加折线图
    KLTLineChartLineView *lineView = [[KLTLineChartLineView alloc] initWithFrame:CGRectMake(0, 0, _chartWidth, _chartHeight)];
    lineView.originP = CGPointMake(0, _chartHeight);
    lineView.line = line;
    [lineView buildUI];
    return lineView;
}

#pragma mark Overload
- (void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    
    static CGFloat scale = 2.0;
    static dispatch_once_t t;
    dispatch_once(&t, ^{
        scale = [UIScreen mainScreen].scale;
    });
    //计算图像高宽
    _chartWidth = rect.size.width - verticalTitleSpace-horizontalPadding*2;
    _chartHeight = rect.size.height - (horizontalTitleSpace+verticalPadding)*2;
    //计算图表原点坐标
    _originP = CGPointMake(verticalTitleSpace+horizontalPadding, _chartHeight+verticalPadding+horizontalTitleSpace);
    //计算横纵单元格距离
    CGFloat horizontalSpace = _chartWidth / (_numberOfVerticalLines-1);
    CGFloat verticalSpace = _chartHeight / (_numberOfHorizontalLines-1);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //画出背景竖线
    {
        if ([self.delegate respondsToSelector:@selector(colorForVerticalSeparateLineOfIndex:)]){
            //实现了颜色回调时进入该流程，严重影响性能
            BOOL respondsToPath = [self.delegate respondsToSelector:@selector(customVerticalSeparateLinePath:styleOfIndex:)];
            for (NSUInteger i = 0; i<_numberOfVerticalLines; i++) {
                UIBezierPath * path = [UIBezierPath bezierPath];
                [path moveToPoint:CGPointMake(_originP.x + horizontalSpace * i, _originP.y)];
                [path addLineToPoint:CGPointMake(_originP.x + horizontalSpace * i, _originP.y-_chartHeight)];
                path.lineWidth = widthOfBGLine / scale / 2;
                UIColor *color = [self.delegate colorForVerticalSeparateLineOfIndex:i];
                CGContextSetStrokeColorWithColor(context, color.CGColor);
                if (respondsToPath) {
                    [self.delegate customVerticalSeparateLinePath:path styleOfIndex:i];
                }
                [path stroke];
            }
        }else if(![_colorOfVerticalLines isEqual:[UIColor clearColor]]){
            //未实现颜色回调并且不为无色时进入
            if ([self.delegate respondsToSelector:@selector(customVerticalSeparateLinePath:styleOfIndex:)]) {
                //实现了路径回调时进入该流程，严重影响性能
                for (NSUInteger i = 0; i<_numberOfVerticalLines; i++) {
                    UIBezierPath * path = [UIBezierPath bezierPath];
                    [path moveToPoint:CGPointMake(_originP.x + horizontalSpace * i, _originP.y)];
                    [path addLineToPoint:CGPointMake(_originP.x + horizontalSpace * i, _originP.y-_chartHeight)];
                    path.lineWidth = widthOfBGLine / scale / 2;
                    CGContextSetStrokeColorWithColor(context, _colorOfVerticalLines.CGColor);
                    [self.delegate customVerticalSeparateLinePath:path styleOfIndex:i];
                    [path stroke];
                }
            }else{
                CGContextSetStrokeColorWithColor(context, _colorOfVerticalLines.CGColor);
                UIBezierPath * path = [UIBezierPath bezierPath];
                for (NSUInteger i = 0; i<_numberOfVerticalLines; i++) {
                    [path moveToPoint:CGPointMake(_originP.x + horizontalSpace * i, _originP.y)];
                    [path addLineToPoint:CGPointMake(_originP.x + horizontalSpace * i, _originP.y-_chartHeight)];
                }
                path.lineWidth = widthOfBGLine / scale / 2;
                [path stroke];
            }
        }
    }
    //画出背景横线
    {
        if ([self.delegate respondsToSelector:@selector(colorForHorizontalSeparateLineOfIndex:)]) {
            //实现了颜色回调时进入该流程，严重影响性能
            BOOL respondsToPath = [self.delegate respondsToSelector:@selector(customHorizontalSeparateLinePath:styleOfIndex:)];
            for (NSUInteger i = 0; i<_numberOfHorizontalLines; i++) {
                UIBezierPath * path = [UIBezierPath bezierPath];
                [path moveToPoint:CGPointMake(_originP.x , _originP.y - verticalSpace * i)];
                [path addLineToPoint:CGPointMake(_originP.x + _chartWidth, _originP.y - verticalSpace * i)];
                path.lineWidth = widthOfBGLine / scale / 2;
                UIColor *color = [self.delegate colorForHorizontalSeparateLineOfIndex:i];
                CGContextSetStrokeColorWithColor(context, color.CGColor);
                if (respondsToPath) {
                    [self.delegate customHorizontalSeparateLinePath:path styleOfIndex:i];
                }
                [path stroke];
            }
        }else if(![_colorOfHorizontalLines isEqual:[UIColor clearColor]]){
            //未实现颜色回调并且不为无色时进入
            if ([self.delegate respondsToSelector:@selector(customHorizontalSeparateLinePath:styleOfIndex:)]) {
                //实现了路径回调时进入该流程，严重影响性能
                for (NSUInteger i = 0; i<_numberOfHorizontalLines; i++) {
                    UIBezierPath * path = [UIBezierPath bezierPath];
                    [path moveToPoint:CGPointMake(_originP.x , _originP.y - verticalSpace * i)];
                    [path addLineToPoint:CGPointMake(_originP.x + _chartWidth, _originP.y - verticalSpace * i)];
                    path.lineWidth = widthOfBGLine / scale / 2;
                    CGContextSetStrokeColorWithColor(context, _colorOfHorizontalLines.CGColor);
                    [self.delegate customHorizontalSeparateLinePath:path styleOfIndex:i];
                    [path stroke];
                }
            }else{
                CGContextSetStrokeColorWithColor(context, _colorOfHorizontalLines.CGColor);
                UIBezierPath * path = [UIBezierPath bezierPath];
                for (NSUInteger i = 0; i<_numberOfHorizontalLines; i++) {
                    [path moveToPoint:CGPointMake(_originP.x , _originP.y - verticalSpace * i)];
                    [path addLineToPoint:CGPointMake(_originP.x + _chartWidth, _originP.y - verticalSpace * i)];
                }
                path.lineWidth = widthOfBGLine / scale / 2;
                [path stroke];
            }
        }
    }
    //写出X轴单位
    {
        for (NSUInteger i = 0; i<_numberOfVerticalLines; i++) {
            CGPoint pointToDraw;
            NSString * title = [NSString stringWithFormat:@"%.2lf",_minValueOfHorizontal+_valueOfPreHorizontalGird*i];
            if ([self.dataSource respondsToSelector:@selector(titleOfHorizontalIndex:withValue:)]) {
                title = [self.dataSource titleOfHorizontalIndex:i withValue:_minValueOfHorizontal+_valueOfPreHorizontalGird*i];
            }
            CGSize size = [title sizeWithAttributes:_attributeOfHorizontalText];
            if (i==0) {
                pointToDraw = CGPointMake(_originP.x + horizontalSpace * i, _originP.y);
            }else if(i==_numberOfVerticalLines - 1){
                pointToDraw = CGPointMake(_originP.x + horizontalSpace * i - size.width, _originP.y);
            }else{
                pointToDraw = CGPointMake(_originP.x + horizontalSpace * i - size.width/2.0, _originP.y);
            }
            if([self.delegate respondsToSelector:@selector(titleOffsetOfHorizontalIndex:)]){
                CGSize offsetSize = [self.delegate titleOffsetOfHorizontalIndex:i];
                pointToDraw = CGPointMake(pointToDraw.x + offsetSize.width, pointToDraw.y + offsetSize.height);
            }
            [title drawAtPoint:pointToDraw withAttributes:_attributeOfHorizontalText];
        }
    }
    //写出Y轴刻度
    {
        for (NSUInteger i = 0; i<_numberOfHorizontalLines; i++) {
            CGPoint pointToDraw;
            NSString * title = [NSString stringWithFormat:@"%.2lf",_minValueOfVertical+_valueOfPreVerticalGird*i];
            if ([self.dataSource respondsToSelector:@selector(titleOfHorizontalIndex:withValue:)]) {
                title = [self.dataSource titleOfVerticalIndex:i withValue:_minValueOfVertical+_valueOfPreVerticalGird*i];
            }
            CGSize size = [title sizeWithAttributes:_attributeOfVerticalText];
            if (i==0) {
                pointToDraw = CGPointMake(_originP.x - size.width-5, _originP.y - verticalSpace * i - size.height);
            }else if(i==_numberOfHorizontalLines - 1){
                pointToDraw = CGPointMake(_originP.x - size.width-5, _originP.y - verticalSpace * i);
            }else{
                pointToDraw = CGPointMake(_originP.x - size.width-5, _originP.y - verticalSpace * i - size.height/2.0);
            }
            if([self.delegate respondsToSelector:@selector(titleOffsetOfVerticalIndex:)]){
                CGSize offsetSize = [self.delegate titleOffsetOfVerticalIndex:i];
                pointToDraw = CGPointMake(pointToDraw.x + offsetSize.width, pointToDraw.y + offsetSize.height);
            }
            [title drawAtPoint:pointToDraw withAttributes:_attributeOfVerticalText];
        }
    }
    
}

#pragma mark Touch Handler
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event{
    [super touchesMoved:touches withEvent:event];
    
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event{
    [super touchesEnded:touches withEvent:event];
    
}
- (void)touchesCancelled:(nullable NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event{
    [super touchesCancelled:touches withEvent:event];
}
#pragma mark Getter Setter
- (void)setNumberOfHorizontalLines:(NSUInteger)numberOfHorizontalLines{
#ifndef __OPTIMIZE__
    NSAssert(numberOfHorizontalLines>=2, @"numberOfHorizontalLines must larger than 1");
#else
    if (numberOfHorizontalLines < 2) {
        numberOfHorizontalLines = 2;
    }
#endif
    _numberOfHorizontalLines = numberOfHorizontalLines;
    [self rangeChanged];
}
- (void)setNumberOfVerticalLines:(NSUInteger)numberOfVerticalLines{
#ifndef __OPTIMIZE__
    NSAssert(numberOfVerticalLines>=2, @"numberOfHorizontalLines must larger than 1");
#else
    if (numberOfVerticalLines < 2) {
        numberOfVerticalLines = 2;
    }
#endif
    _numberOfVerticalLines = numberOfVerticalLines;
    [self rangeChanged];
}
- (void)setMaxValueOfHorizontal:(double)maxValueOfHorizontal{
    _maxValueOfHorizontal = maxValueOfHorizontal;
    _autoComputeHRange = NO;
    [self rangeChanged];
}
- (void)setMaxValueOfVertical:(double)maxValueOfVertical{
    _maxValueOfVertical = maxValueOfVertical;
    _autoComputeVRange = NO;
    [self rangeChanged];
}
- (void)setMinValueOfHorizontal:(double)minValueOfHorizontal{
    _minValueOfHorizontal = minValueOfHorizontal;
    _autoComputeHRange = NO;
    [self rangeChanged];
}
- (void)setMinValueOfVertical:(double)minValueOfVertical{
    _minValueOfVertical = minValueOfVertical;
    _autoComputeVRange = NO;
    [self rangeChanged];
}
- (void)setLines:(NSArray<KLTLineChartLine *> *)lines{
    _lines = [lines copy];
    if (_autoComputeVRange) {
        [self autoComputeVRage];
    }
    if (_autoComputeHRange) {
        [self autoComputeHRage];
    }
}
@end


