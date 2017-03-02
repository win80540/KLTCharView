//
//  KLTLineChartView.m
//
//
//  Created by 田凯 on 15/11/21.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import <objc/message.h>
#import "KLTLineChartView.h"

#define ONMain(codeBlock) \
if ([[NSThread currentThread] isMainThread]) {\
{codeBlock;}\
}else{\
dispatch_sync(dispatch_get_main_queue(), ^{\
{codeBlock;} \
});\
}

static const CGFloat horizontalTitleSpace = 21; //x轴标题的默认高度
static const CGFloat verticalTitleSpaceDefaultMin = 0; //y轴标题的默认最小宽度
static const CGFloat verticalTitleSpaceDefaultMax = 100; //y轴标题的默认最大宽度
static const CGFloat horizontalPadding = 15;
static const CGFloat verticalPadding = 15;
static const CGFloat widthOfBGLine = 1; //表格的网格线宽度
//static const CGFloat widthOfLine = 1; //折线宽度
//static const CGFloat autoComputeVRangeMAXRate = 0.5; //顶部留空百分比
//static const CGFloat autoComputeVRangeMINRate = 0.3; //底部留空百分比
//static const CGFloat autoComputeHRangeMINRate = 0.0; //左部留空百分比
//static const CGFloat autoComputeHRangeMAXRate = 0.0; //右部留空百分比
static NSString * const lineTitleFormatDefaultStr = @"%.2lf";
static NSString * const kObserverTouching = @"isTouching";

#pragma mark - Interface

#pragma mark Private Class
@interface KLTLineChartLineBGView : UIView

@property (strong,nonatomic) KLTLineChartLine *line;
@property (assign,nonatomic) CGPoint originP;
@property (copy,nonatomic) UIBezierPath *path;
@property (nonatomic, assign) BOOL needGradient;

- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end

@interface KLTLineChartLineView : UIView{
    dispatch_queue_t _lockQueueForTipViewSet;
    BOOL _hasObserverTouching;
}

@property (weak, nonatomic) KLTLineChartView *parentView;
@property (strong, nonatomic) KLTLineChartLine *line;
@property (assign, nonatomic) CGPoint originP;
@property (strong, nonatomic) KLTLineChartLineBGView *bgView;
@property (strong, nonatomic) NSMutableSet *delayDeleteViewSet;             // 每个点都可以有的提示框
@property (strong, nonatomic) NSMutableSet *tipViewSet;             // 每个点都可以有的提示框
@property (strong, nonatomic) NSMutableSet *touchTipViewSet;        // 只有在触摸某个点时才显示的该点的提示框
@property (weak, nonatomic) UIView *touchTempTipView;               // 只有在触摸某个点时才显示的该点的提示框，会自动消失
@property (assign, nonatomic) CGPoint xyRate;                       // 绘制该图时数据单位与坐标单位的比值
@property (nonatomic, assign) BOOL needGradient;

- (void)buildUI;
@end

#pragma mark Public Class

@interface KLTLineChartPoint (){
    
}
@property (assign, nonatomic) CGFloat x;
@property (assign, nonatomic) CGFloat y;
@end

@interface KLTLineChartView (){
    BOOL _autoComputeVRange;
    BOOL _autoComputeHRange;
    NSMutableDictionary<NSString *, KLTLineChartLineView *> *_lineViews;
    UIView *_nodataTipView;
}
@property (assign, nonatomic) double verticalTitleSpace;     //y轴标题的默认宽度
@property (strong, nonatomic) UIView *containerView;
@property (strong, nonatomic) CAShapeLayer *bgLayer;
@property (assign, nonatomic) double valueOfPreHorizontalGird;
@property (assign, nonatomic) double valueOfPreVerticalGird;
@property (assign, nonatomic, readwrite) CGFloat chartWidth;
@property (assign, nonatomic, readwrite) CGFloat chartHeight;
@property (assign, nonatomic, readwrite) CGPoint originP;
@property (assign, nonatomic) BOOL isTouching;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;
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

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    return self;
}
- (void)layoutSubviews{
    if (!self.needGradient) {
        return;
    }
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
    [_path addLineToPoint:CGPointMake(SAFEFLOAT(endP.x), SAFEFLOAT(_originP.y))];
    [_path addLineToPoint:CGPointMake(SAFEFLOAT(startP.x), SAFEFLOAT(_originP.y))];
    [_path addLineToPoint:CGPointMake(SAFEFLOAT(startP.x), SAFEFLOAT(startP.y))];
    [_path fill];
}
@end

@implementation KLTLineChartLineView
- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        [self setBackgroundColor:[UIColor clearColor]];
        _touchTipViewSet = [NSMutableSet new];
        _delayDeleteViewSet = [NSMutableSet new];
        _lockQueueForTipViewSet = dispatch_queue_create("com.KLT.lineChartView.tipViewSetLockQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}
- (void)buildUI{
    
    {
        // 清理工作，其实在 KLTLineChartView 中 buildUI 每次都是新实例不需要清理，只是保险措施
        ONMain(
               for (UIView * tipView in self.tipViewSet) {
                   [tipView removeFromSuperview];
               }
               for (UIView * touchTipView in self.touchTipViewSet) {
                   [touchTipView removeFromSuperview];
               }
               [self.touchTempTipView removeFromSuperview];
               );
        [self.tipViewSet removeAllObjects];
        [self.touchTipViewSet removeAllObjects];
        self.touchTempTipView = nil;
    }
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [_line.points enumerateObjectsUsingBlock:^(KLTLineChartPoint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0) {
            [path moveToPoint:CGPointMake(SAFEFLOAT(obj.x), SAFEFLOAT(obj.y))];
        }else{
            [path addLineToPoint:CGPointMake(SAFEFLOAT(obj.x), SAFEFLOAT(obj.y))];
        }
    }];
    
    if (![_line.fillColor isEqual:[UIColor clearColor]]){
        //画出渐变填充色
        _bgView = [[KLTLineChartLineBGView alloc] initWithFrame:self.bounds];
        _bgView.needGradient = self.needGradient;
        _bgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _bgView.line = self.line;
        _bgView.originP = self.originP;
        _bgView.path = path;
        ONMain(
               [self addSubview:_bgView];
               );
    }
    
    //画出折线
    CAShapeLayer *lineShaperLayer = [CAShapeLayer layer];
    lineShaperLayer.path = path.CGPath;
    lineShaperLayer.lineWidth = self.line.lineWidth;
    lineShaperLayer.strokeColor = self.line.lineColor.CGColor;
    lineShaperLayer.fillColor = [UIColor clearColor].CGColor;
    ONMain(
           [self.layer addSublayer:lineShaperLayer];
           );
    
    if (_parentView.delegateOfTipView && [_parentView.delegateOfTipView respondsToSelector:@selector(lineChartView:tipViewOfPoint:inLine:avilibleRect:)])
        //如果响应 lineChartView:tipViewOfPoint:inLine:avilibleRect: 由于代理方法中可能会出现生成大量View的耗时代码，所以异步派发到后台线程，执行代理方法
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            CGRect avRect = self.bounds;
            [_line.points enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(KLTLineChartPoint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                UIView * tipView = [_parentView.delegateOfTipView lineChartView:_parentView tipViewOfPoint:obj inLine:_line avilibleRect:avRect];
                if (tipView && [tipView isKindOfClass:[UIView class]]) {
                    tipView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
                    [self addTipView:tipView];
                }
            }];
            if (self.tipViewSet.count > 0) {
                ONMain(
                       for (UIView * tipView in self.tipViewSet) {
                           [self addSubview:tipView];
                       }
                       );
            }
        });
}

- (void)touches:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event andType:(KLTLineChartTouchEventType)type {
    KLTLineChartView *parentView = _parentView;
    id<KLTLineChartTipViewDelegate> delegate = _parentView.delegateOfTipView;
    CGPoint location = [[touches anyObject] locationInView:self];
    
    __block KLTLineChartPoint *point = nil;
    [self.line.points enumerateObjectsUsingBlock:^(KLTLineChartPoint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.x >= location.x) {
            point = obj;
            *stop = YES;
        }
    }];
    if (point == nil) {
        point = [self.line.points lastObject];
    }
    
    switch (type) {
        case KLTLineChartTouchEventBegan:
        {
            if ([delegate respondsToSelector:@selector(lineChartView:touchTipViewOfPoint:inLine:eventType:avilibleRect:)]) {
                UIView *view = [delegate lineChartView:parentView touchTipViewOfPoint:point inLine:self.line eventType:type avilibleRect:self.bounds];
                if (view) {
                    [self.touchTipViewSet addObject:view];
                    [self addSubview:view];
                }
            }
            
            [self.touchTempTipView removeFromSuperview];
            if ([delegate respondsToSelector:@selector(lineChartView:autoRemoveTouchTipViewOfPoint:inLine:eventType:avilibleRect:)]) {
                UIView *view = [delegate lineChartView:parentView autoRemoveTouchTipViewOfPoint:point inLine:self.line eventType:type avilibleRect:self.bounds];
                if (view) {
                    self.touchTempTipView = view;
                    [self addSubview:view];
                }
            }
        }
            break;
        case KLTLineChartTouchEventMoved:
        {
            [self.touchTempTipView removeFromSuperview];
            if ([delegate respondsToSelector:@selector(lineChartView:autoRemoveTouchTipViewOfPoint:inLine:eventType:avilibleRect:)]) {
                UIView *view = [delegate lineChartView:parentView autoRemoveTouchTipViewOfPoint:point inLine:self.line eventType:type avilibleRect:self.bounds];
                if (view) {
                    self.touchTempTipView = view;
                    [self addSubview:view];
                }
            }
            
            if ([delegate respondsToSelector:@selector(lineChartView:touchTipViewOfPoint:inLine:eventType:avilibleRect:)]) {
                UIView *view = [delegate lineChartView:parentView touchTipViewOfPoint:point inLine:self.line eventType:type avilibleRect:self.bounds];
                if (view) {
                    [self.touchTipViewSet addObject:view];
                    [self addSubview:view];
                }
            }
        }
            
            break;
        case KLTLineChartTouchEventEnded:
        {
            [self.touchTempTipView removeFromSuperview];
            if ([delegate respondsToSelector:@selector(lineChartView:autoRemoveTouchTipViewOfPoint:inLine:eventType:avilibleRect:)]) {
                UIView *view = [delegate lineChartView:parentView autoRemoveTouchTipViewOfPoint:point inLine:self.line eventType:type avilibleRect:self.bounds];
                if (view) {
                    self.touchTempTipView = view;
                    [self addSubview:view];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [view removeFromSuperview];
                    });
                }
            }
            
            if ([delegate respondsToSelector:@selector(lineChartView:touchTipViewOfPoint:inLine:eventType:avilibleRect:)]) {
                UIView *view = [delegate lineChartView:parentView touchTipViewOfPoint:point inLine:self.line eventType:type avilibleRect:self.bounds];
                if (view) {
                    [self.touchTipViewSet addObject:view];
                    [self addSubview:view];
                }
            }
        }
            
            break;
        case KLTLineChartTouchEventCancelled:
        {
            [self.touchTempTipView removeFromSuperview];
            if ([delegate respondsToSelector:@selector(lineChartView:autoRemoveTouchTipViewOfPoint:inLine:eventType:avilibleRect:)]) {
                UIView *view = [delegate lineChartView:parentView autoRemoveTouchTipViewOfPoint:point inLine:self.line eventType:type avilibleRect:self.bounds];
                if (view) {
                    self.touchTempTipView = view;
                    [self addSubview:view];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [view removeFromSuperview];
                    });
                }
            }
            if ([delegate respondsToSelector:@selector(lineChartView:touchTipViewOfPoint:inLine:eventType:avilibleRect:)]) {
                UIView *view = [delegate lineChartView:parentView touchTipViewOfPoint:point inLine:self.line eventType:type avilibleRect:self.bounds];
                if (view) {
                    [self.touchTipViewSet addObject:view];
                    [self addSubview:view];
                }
            }
        }
            
            break;
            
        default:
            break;
    }
    [self setNeedsDisplay];
}

- (void)delayRemoveView:(UIView *)view {
    // 直接remove会导致touch事件中断，延迟执行
    ONMain([view setHidden:YES];);
    [self.delayDeleteViewSet addObject:view];
    if (!_hasObserverTouching) {
        _hasObserverTouching = YES;
        [self.parentView addObserver:self forKeyPath:kObserverTouching options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:kObserverTouching]) {
        if (![change[NSKeyValueChangeNewKey] boolValue]) {
            ONMain({
                NSSet *deleteArray = [self.delayDeleteViewSet copy];
                [deleteArray enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, BOOL * _Nonnull stop) {
                    if (self.parentView.isTouching) {
                        *stop = YES;
                        return;
                    }
                    [obj removeFromSuperview];
                    [self.delayDeleteViewSet removeObject:obj];
                }];
            });
        }
    }
}

- (void)dealloc {
    if (_hasObserverTouching) {
        _hasObserverTouching = NO;
        [self.parentView removeObserver:self forKeyPath:kObserverTouching];
    }
}

- (void)clearTipView {
    dispatch_barrier_async(_lockQueueForTipViewSet, ^{
        [_tipViewSet enumerateObjectsUsingBlock:^(UIView *  _Nonnull obj, BOOL * _Nonnull stop) {
            [self delayRemoveView:obj];
        }];
        [_tipViewSet removeAllObjects];
    });
}

- (void)clearTouchTipView {
    NSArray *oldArray = [self.touchTipViewSet copy];
    UIView *oldTempView = self.touchTempTipView;
    
    [self.touchTipViewSet removeAllObjects];
    self.touchTempTipView = nil;
    
    [oldTempView removeFromSuperview];
    [oldArray enumerateObjectsUsingBlock:^(UIView *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self delayRemoveView:obj];
    }];
}

- (void)addTipView:(UIView *)tipView{
    dispatch_barrier_async(_lockQueueForTipViewSet, ^{
        [_tipViewSet addObject:tipView];
    });
}
- (NSMutableSet<UIView *> *)tipViewSet{
    __block id ret = nil;
    dispatch_sync(_lockQueueForTipViewSet, ^{
        if (_tipViewSet == nil) {
            _tipViewSet = [NSMutableSet set];
        }
        ret = _tipViewSet;
    });
    return ret;
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

- (instancetype)init{
    if (self = [super init]) {
        [self __initSelf];
    }
    return self;
}

- (void)__initSelf{
    self.lineWidth = 1;
}

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

- (NSString *)identity {
    if (_identity) {
        return _identity;
    }
    
    _identity = [[NSUUID UUID] UUIDString];
    return _identity;
}

@end



@implementation KLTLineChartView

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self __initialize];
}

- (instancetype)init{
    if (self = [self initWithFrame:CGRectZero]) {
        
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
        
    }
    return self;
}

- (void)clearTipView {
    [_lineViews enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, KLTLineChartLineView * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj clearTipView];
    }];
}
- (void)clearTouchTipView {
    [_lineViews enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, KLTLineChartLineView * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj clearTouchTipView];
    }];
}
- (void)clearTipViewForLineIdentity:(NSString *)identity {
    [_lineViews[identity] clearTipView];
}
- (void)clearTouchTipViewForLineIdentity:(NSString *)identity {
    [_lineViews[identity] clearTouchTipView];
}

- (void)displayWithAnimation:(BOOL)isAnimation{
    void(^block)() =  ^{
        //清理view
        _lineViews = [NSMutableDictionary dictionary];
        [_containerView removeFromSuperview];
        [_nodataTipView removeFromSuperview];
        
        NSString * titleMin = nil;
        NSString * titleMax = nil;
        
        if ([self.dataSource respondsToSelector:@selector(titleOfHorizontalIndex:withValue:)]) {
            titleMin = [self.dataSource titleOfVerticalIndex:0 withValue:_minValueOfVertical];
            titleMax = [self.dataSource titleOfVerticalIndex:_numberOfHorizontalLines-1 withValue:_maxValueOfVertical];
        } else {
            titleMin = [NSString stringWithFormat:lineTitleFormatDefaultStr,_minValueOfVertical];
            titleMax = [NSString stringWithFormat:lineTitleFormatDefaultStr,_maxValueOfVertical];
        }
        CGSize sizeMax = [titleMax sizeWithAttributes:_attributeOfVerticalText];
        CGSize sizeMin = [titleMin sizeWithAttributes:_attributeOfVerticalText];
        CGFloat maxWith = MAX(sizeMax.width, sizeMin.width);
        maxWith = MIN(MAX(maxWith, verticalTitleSpaceDefaultMin), verticalTitleSpaceDefaultMax);
        
        self.verticalTitleSpace = maxWith;
        
        //计算图像高宽
        _chartWidth = SAFEFLOAT(self.bounds.size.width - _verticalTitleSpace-horizontalPadding*2);
        _chartHeight = SAFEFLOAT(self.bounds.size.height - (horizontalTitleSpace+verticalPadding)*2);
#ifdef DEBUG
        NSAssert(_chartWidth > 0 && _chartHeight > 0, @"错误的尺寸，一般出现在调用绑定时机错误时");
#endif
        if (_chartWidth <= 0){
            _chartWidth = 100;
        }
        if (_chartHeight <= 0){
            _chartHeight = 80;
        }
        //计算图表原点坐标
        _originP = CGPointMake(SAFEFLOAT(_verticalTitleSpace+horizontalPadding), SAFEFLOAT(_chartHeight+verticalPadding+horizontalTitleSpace));
        //重新生产contanerView
        _containerView = [[UIView alloc] initWithFrame:CGRectMake(_originP.x, SAFEFLOAT(verticalPadding+horizontalTitleSpace), _chartWidth, _chartHeight)];
        [_containerView setBackgroundColor:[UIColor clearColor]];
        [self addSubview:_containerView];
        
        if (self.showNoDataTips){
            
            if([self.delegateOfTipView respondsToSelector:@selector(lineChartView:nodataTipViewOfAvilibleRect:)]){
                ONMain(UIView *nodataTipView = [self.delegateOfTipView lineChartView:self nodataTipViewOfAvilibleRect:self.bounds];
                       if (nodataTipView) {
                           [self addSubview:nodataTipView];
                           _nodataTipView = nodataTipView;
                       });
            }
        }else{
            
            WEAK_SELF(weakSelf);
            
            //画出每一条线
            [self.lines enumerateObjectsUsingBlock:^(KLTLineChartLine * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                KLTLineChartLineView *lineView = [weakSelf createLineView:obj];
                [_lineViews setObject:lineView forKey:obj.identity];
                [_containerView addSubview:lineView];
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
        [self setNeedsDisplay];
    };
    
    if([NSThread isMainThread]){
        block();
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
    
}

#pragma mark Private Method
//设置一些初始化参数
- (void)__initialize{
    [self setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1]];
    [self setUserInteractionEnabled:YES];
    _autoComputeVRangeMAXRate = 0.5; //顶部留空百分比
    _autoComputeVRangeMINRate = 0.3; //底部留空百分比
    _autoComputeHRangeMINRate = 0.0; //左部留空百分比
    _autoComputeHRangeMAXRate = 0.0; //右部留空百分比
    _colorOfHorizontalLines = [UIColor colorWithWhite:0.8 alpha:1];
    _colorOfVerticalLines = [UIColor colorWithWhite:0.8 alpha:1];
    _numberOfHorizontalLines = 5;
    _numberOfVerticalLines = 5;
    _maxValueOfHorizontal = 100;
    _minValueOfHorizontal = 0;
    _maxValueOfVertical = 0.1;
    _minValueOfVertical = -0.1;
    _verticalTitleSpace = verticalTitleSpaceDefaultMin;
    _needGradient = YES;
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
    _valueOfPreHorizontalGird = SAFEFLOAT((_maxValueOfHorizontal - _minValueOfHorizontal) / (_numberOfVerticalLines-1));
    _valueOfPreVerticalGird = SAFEFLOAT((_maxValueOfVertical - _minValueOfVertical) / (_numberOfHorizontalLines-1));
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
    
    if (maxV == minV) {
        minV = maxV - ABS(maxV);
    }
    double rangeV = SAFEFLOAT(maxV - minV);
    //修改刻度范围
    _maxValueOfVertical = maxV+SAFEFLOAT(_autoComputeVRangeMAXRate)*rangeV;
    _minValueOfVertical = minV-SAFEFLOAT(_autoComputeVRangeMINRate)*rangeV;
    
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
    
    if (maxH == minH) {
        minH = maxH - ABS(maxH);
    }
    if (minH>=0) {
        minH = 0;
    }
    double rangeH = SAFEFLOAT(maxH - minH);
    //修改刻度范围
    _maxValueOfHorizontal = maxH+SAFEFLOAT(_autoComputeHRangeMAXRate)*rangeH;
    if (minH>=0) {
        _minValueOfHorizontal = 0;
    }else{
        _minValueOfHorizontal = minH-SAFEFLOAT(_autoComputeHRangeMINRate)*rangeH;
    }
    [self rangeChanged];
}

- (KLTLineChartLineView *)createLineView:(KLTLineChartLine *)line{
    //屏幕的点与值的比例
    CGFloat xRate = SAFEFLOAT((_maxValueOfHorizontal - _minValueOfHorizontal)/SAFEFLOAT(_chartWidth));
    CGFloat yRate = SAFEFLOAT((_maxValueOfVertical - _minValueOfVertical)/SAFEFLOAT(_chartHeight));
    //按比例计算出UI坐标点
    [line.points enumerateObjectsUsingBlock:^(KLTLineChartPoint * _Nonnull point, NSUInteger idx, BOOL * _Nonnull stop) {
        point.x = SAFEFLOAT((point.valueOfHorizontal - _minValueOfHorizontal) / xRate);
        point.y = SAFEFLOAT(_chartHeight - (point.valueOfVertical - _minValueOfVertical) / yRate);
    }];
    //添加折线图
    KLTLineChartLineView *lineView = [[KLTLineChartLineView alloc] initWithFrame:CGRectMake(0, 0, SAFEFLOAT(_chartWidth), SAFEFLOAT(_chartHeight))];
    lineView.needGradient = self.needGradient;
    lineView.originP = CGPointMake(0, SAFEFLOAT(_chartHeight));
    lineView.xyRate = CGPointMake(xRate, yRate);
    lineView.line = line;
    lineView.parentView = self;
    [lineView buildUI];
    return lineView;
}

#pragma mark Overload
- (void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    
    static CGFloat scale = 2.0;
    static dispatch_once_t t;
    
    dispatch_once(&t, ^{
        scale = SAFEFLOAT([UIScreen mainScreen].scale);
    });
    
    //计算图像高宽
    _chartWidth = SAFEFLOAT(rect.size.width - _verticalTitleSpace-horizontalPadding*2);
    _chartHeight = SAFEFLOAT(rect.size.height - (horizontalTitleSpace+verticalPadding)*2);
    //计算图表原点坐标
    _originP = CGPointMake(SAFEFLOAT(_verticalTitleSpace+horizontalPadding), SAFEFLOAT(_chartHeight+verticalPadding+horizontalTitleSpace));
    //计算横纵单元格距离
    CGFloat horizontalSpace = SAFEFLOAT(_chartWidth / (_numberOfVerticalLines-1));
    CGFloat verticalSpace = SAFEFLOAT(_chartHeight / (_numberOfHorizontalLines-1));
    
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
    self.isTouching = YES;
    if (self.showNoDataTips) {
        return;
    }
    
    [_lineViews enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, KLTLineChartLineView * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj touches:touches withEvent:event andType:KLTLineChartTouchEventBegan];
    }];
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event{
    [super touchesMoved:touches withEvent:event];
    self.isTouching = YES;
    if (self.showNoDataTips) {
        return;
    }
    
    [_lineViews enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, KLTLineChartLineView * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj touches:touches withEvent:event andType:KLTLineChartTouchEventMoved];
    }];
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event{
    [super touchesEnded:touches withEvent:event];
    self.isTouching = NO;
    if (self.showNoDataTips) {
        return;
    }
    
    [_lineViews enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, KLTLineChartLineView * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj touches:touches withEvent:event andType:KLTLineChartTouchEventEnded];
    }];
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event{
    [super touchesCancelled:touches withEvent:event];
    self.isTouching = NO;
    if (self.showNoDataTips) {
        return;
    }
    
    [_lineViews enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, KLTLineChartLineView * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj touches:touches withEvent:event andType:KLTLineChartTouchEventCancelled];
    }];
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

#pragma mark - tip category

static char kIdentity;
static char kContext;

@implementation KLTLineChartPoint(KLTTipInfo)

- (void)setIdentity:(NSString *)identity{
    objc_setAssociatedObject(self, &kIdentity, identity, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSString *)identity{
    return objc_getAssociatedObject(self, &kIdentity);
}

- (void)setContext:(id)context{
    objc_setAssociatedObject(self, &kContext, context, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (id)context{
    return objc_getAssociatedObject(self, &kContext);
}

@end

static char kDelegateTipView;
static char kDelegateTipViewShowNoDataTips;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation KLTLineChartView (KLTTipInfo)

- (void)setDelegateOfTipView:(id)delegateOfTipView{
    objc_setAssociatedObject(self, &kDelegateTipView, delegateOfTipView, OBJC_ASSOCIATION_ASSIGN);
}
- (id)delegateOfTipView{
    return objc_getAssociatedObject(self, &kDelegateTipView);
}

- (void)setShowNoDataTips:(BOOL)showNoDataTips{
    objc_setAssociatedObject(self, &kDelegateTipViewShowNoDataTips, @(showNoDataTips), OBJC_ASSOCIATION_RETAIN);
}
- (BOOL)showNoDataTips{
    NSNumber *number = objc_getAssociatedObject(self, &kDelegateTipViewShowNoDataTips);
    if (number) {
        return [number boolValue];
    }
    return NO;
}
#pragma clang diagnostic pop
@end

