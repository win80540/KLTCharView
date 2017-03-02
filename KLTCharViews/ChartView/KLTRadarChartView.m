//
//  KLTRadarChartView.m
//  KLTCharViews
//
//  Created by 田凯 on 3/1/17.
//  Copyright © 2017 netease. All rights reserved.
//

#import "KLTRadarChartView.h"

static NSString * const kException = @"KLTRadrChartView Exception";
static CGFloat const s_starArc = - M_PI_2;

@implementation KLTRadarChartDataDimension

- (instancetype)init {
    self = [super init];
    if (self) {
        _value = 0;
        _max = 1;
        _min = 0;
    }
    return self;
}

@end

@interface KLTRadarChartView_Inner : UIView

@property (nonatomic, weak) KLTRadarChartView *parentView;
@property (nonatomic, assign) NSUInteger dataIndex;
@property (nonatomic, assign) NSUInteger numberOfDimensions;
@property (nonatomic, strong) NSArray<KLTRadarChartDataDimension *> *dimensionDatas;

- (void)configParamParentView:(KLTRadarChartView *)parentView numberOfDimensions:(NSUInteger)numberOfDimensions dataIndex:(NSUInteger)dataIndex;
- (void)displayWithAnimation:(BOOL)isAnimation;

@end

@interface KLTRadarChartView () {
    CGFloat _length;
    NSUInteger _numberOfData;
    NSUInteger _numberOfDimensions;
    BOOL _isAnimation;
}

@property (nonatomic, assign) CGFloat paddingTop;
@property (nonatomic, assign) CGFloat paddingBottom;
@property (nonatomic, assign) CGFloat paddingLeft;
@property (nonatomic, assign) CGFloat paddingRight;
@property (nonatomic, strong) UIColor *defaultBgColorOfLongitude;
@property (nonatomic, strong) UIColor *defaultBgColorOfLatitude;

@end

@implementation KLTRadarChartView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _bgColor = [UIColor clearColor];
        _defaultBgColorOfLongitude = [UIColor colorWithRed:0.68 green:0.68 blue:0.68 alpha:1];
        _defaultBgColorOfLatitude = [UIColor colorWithRed:0.87 green:0.87 blue:0.87 alpha:1];
        _numberOfLatitude = 1;
        _widthOfLongitude = 1;
        _widthOfLatitude = 1;
        _paddingTop = _paddingBottom = 5;
        _paddingLeft = _paddingRight = 5;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self initWithFrame:CGRectMake(0, 0, 10, 10)];
    return self;
}

- (void)displayWithAnimation:(BOOL)isAnimation {
    [self setNeedsDisplay];
    NSAssert(self.dataSource, @"you must provide a dataSource delegate");
    if (self.dataSource == nil) {
        return;
    }
    [[self.subviews copy] enumerateObjectsUsingBlock:^(UIView *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    
    NSUInteger numberOfData = 0;
    NSUInteger numberOfDimensions = 0;
    if ([self.dataSource respondsToSelector:@selector(numberOfData:)]) {
         numberOfData = [self.dataSource numberOfData:self];
    }
    if ([self.dataSource respondsToSelector:@selector(numberOfDimensions:)]) {
        numberOfDimensions = [self.dataSource numberOfDimensions:self];
    }
    _isAnimation = isAnimation;
    _numberOfData = numberOfData;
    _numberOfDimensions = numberOfDimensions;
}

- (void)displayBGFinished {
    NSUInteger numberOfData = _numberOfData;
    NSUInteger numberOfDimensions = _numberOfDimensions;
    BOOL isAnimation = _isAnimation;
    CGFloat length = _length;
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect childRect = CGRectMake(center.x - length, center.y - length, length * 2, length * 2);
        for (NSUInteger dataIdx = 0; dataIdx < numberOfData; dataIdx++) {
            KLTRadarChartView_Inner *childView = [[KLTRadarChartView_Inner alloc] initWithFrame:childRect];
            [childView configParamParentView:self numberOfDimensions:numberOfDimensions dataIndex:dataIdx];
            [self addSubview:childView];
            [childView displayWithAnimation:isAnimation];
        }
    });
}

- (void)drawRect:(CGRect)rect {
    static CGFloat scale = 2.0;
    static dispatch_once_t t;
    dispatch_once(&t, ^{
        scale = SAFEFLOAT([UIScreen mainScreen].scale);
    });
    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    NSUInteger numberOfDimensions = 0;
    double arcItem = 0;
    if ([self.dataSource respondsToSelector:@selector(numberOfDimensions:)]) {
        numberOfDimensions = [self.dataSource numberOfDimensions:self];
    }
    if (numberOfDimensions < 2) {
        @throw [NSException exceptionWithName:kException reason:@"numberOfDimensions must be 2 or more" userInfo:nil];
    }
    arcItem = 2 * M_PI/numberOfDimensions;
    
    CGFloat maxWidth = 0;
    CGFloat maxHeight = 0;
    NSMutableArray *titles = nil;
    if ([self.dataSource respondsToSelector:@selector(titleForDimesionIdx:inView:)]) {
        // 为了自适应，第一次遍历标题，计算最大尺寸
        titles = [NSMutableArray arrayWithCapacity:numberOfDimensions];
        for (NSUInteger i = 0; i < numberOfDimensions; i++) {
            NSAttributedString *title = [self.dataSource titleForDimesionIdx:i inView:self];
            if (title) {
                CGSize size = [title size];
                maxWidth = MAX(maxWidth, size.width);
                maxHeight = MAX(maxHeight, size.height);
                [titles addObject:title];
            } else {
                [titles addObject:[NSNull null]];
            }
        }
    }
    
    // 根据标题计算的半径
    CGFloat length = MIN(CGRectGetHeight(rect) - 2 * maxHeight, CGRectGetWidth(rect) - 2 * maxWidth) / 2;
    // 根据Padding计算的半径
    CGFloat paddingLength = MIN(CGRectGetHeight(rect) - _paddingTop - _paddingBottom, CGRectGetWidth(rect) - _paddingLeft - _paddingRight) / 2;
    length = MIN(length, paddingLength);
    if (titles && titles.count == numberOfDimensions) {
        for (NSUInteger i = 0; i < numberOfDimensions; i++) {
            NSAttributedString *title = titles[i];
            if (![title isKindOfClass:[NSAttributedString class]]) {
                continue;
            }
            CGSize size = [title size];
            CGPoint startP = CGPointMake(center.x + length * cos(s_starArc + arcItem * i), center.y + length * sin(s_starArc + arcItem * i));
            // 根据所处的位置，调整绘制标题的起点，避免与雷达图重叠
            if (startP.x == center.x) {
                startP.x -= size.width / 2;
            } else if (startP.x < center.x) {
                startP.x -= size.width;
            }
            if (startP.y == center.y) {
                startP.y -= size.height / 2;
            } else if (startP.y < center.y) {
                startP.y -= size.height;
            }
            [title drawAtPoint:startP];
        }
    }
    
    if (self.widthOfLongitude > 0) {
        // 画出经线
        BOOL customColor = [self.delegate respondsToSelector:@selector(colorForBackgroundLongitudeAtIndex:total:inView:)];
        bool customPath = [self.delegate respondsToSelector:@selector(customBackgroundLongitudePath:styleOfIndex:total:inView:)];
        
        if (customColor || customPath) {
            for (NSUInteger i = 0; i<numberOfDimensions; i++) {
                UIBezierPath *path = [UIBezierPath bezierPath];
                path.lineWidth = self.widthOfLongitude / scale / 2;
                if (customPath) {
                    [self.delegate customBackgroundLongitudePath:path styleOfIndex:i total:numberOfDimensions inView:self];
                }
                [path moveToPoint:center];
                [path addLineToPoint:CGPointMake(center.x + length * cos(s_starArc + arcItem * i), center.y + length * sin(s_starArc + arcItem * i))];
                if (customColor) {
                    CGContextSetStrokeColorWithColor(ctx, [self.delegate colorForBackgroundLongitudeAtIndex:i total:numberOfDimensions inView:self].CGColor);
                } else {
                  CGContextSetStrokeColorWithColor(ctx, self.defaultBgColorOfLongitude.CGColor);
                }
                [path stroke];
            }
        } else {
            // 无定制时最优处理
            UIBezierPath *path = [UIBezierPath bezierPath];
            for (NSUInteger i = 0; i<numberOfDimensions; i++) {
                [path moveToPoint:center];
                [path addLineToPoint:CGPointMake(center.x + length * cos(s_starArc + arcItem * i), center.y + length * sin(s_starArc + arcItem * i))];
            }
            path.lineWidth = self.widthOfLongitude / scale / 2;
            CGContextSetStrokeColorWithColor(ctx, self.defaultBgColorOfLongitude.CGColor);
            [path stroke];
        }
    }
    
    if (self.numberOfLatitude > 0 && self.widthOfLatitude > 0) {
        // 画出纬线
        BOOL customColor = [self.delegate respondsToSelector:@selector(colorForBackgroundLatitudeAtIndex:total:inView:)];
        BOOL customPath = [self.delegate respondsToSelector:@selector(customBackgroundLatitudePath:styleOfIndex:total:inView:)];
        
        if (customColor || customPath) {
            NSUInteger numOfSeg= self.numberOfLatitude;
            for (NSUInteger j = 1; j <= numOfSeg; j++) {
                UIBezierPath *path = [UIBezierPath bezierPath];
                path.lineWidth = self.widthOfLatitude / scale / 2;
                if (customPath) {
                    [self.delegate customBackgroundLatitudePath:path styleOfIndex:j-1 total:numOfSeg inView:self];
                }
                CGFloat currentLength = length / numOfSeg * j;
                [path moveToPoint:CGPointMake(center.x + currentLength * cos(s_starArc + arcItem * 0), center.y + currentLength * sin(s_starArc + arcItem * 0))];
                for (int i = 0; i < numberOfDimensions; i++) {
                    [path addLineToPoint:CGPointMake(center.x + currentLength * cos(s_starArc + arcItem * (i + 1)), center.y + currentLength * sin(s_starArc + arcItem * (i + 1)))];
                }
                if (customColor) {
                    CGContextSetStrokeColorWithColor(ctx, [self.delegate colorForBackgroundLatitudeAtIndex:j-1 total:numOfSeg inView:self].CGColor);
                } else {
                    CGContextSetStrokeColorWithColor(ctx, self.defaultBgColorOfLatitude.CGColor);
                }
                [path stroke];
            }
        } else {
            // 无定制时最优处理
            NSUInteger numOfSeg= self.numberOfLatitude;
            UIBezierPath *path = [UIBezierPath bezierPath];
            for (NSUInteger j = 1; j <= numOfSeg; j++) {
                CGFloat currentLength = length / numOfSeg * j;
                [path moveToPoint:CGPointMake(center.x + currentLength * cos(s_starArc + arcItem * 0), center.y + currentLength * sin(s_starArc + arcItem * 0))];
                for (NSUInteger i = 0; i<numberOfDimensions; i++) {
                    [path addLineToPoint:CGPointMake(center.x + currentLength * cos(s_starArc + arcItem * (i + 1)), center.y + currentLength * sin(s_starArc + arcItem * (i + 1)))];
                }
            }
            path.lineWidth = self.widthOfLatitude / scale / 2;
            CGContextSetStrokeColorWithColor(ctx, self.defaultBgColorOfLatitude.CGColor);
            [path stroke];
        }
    }

    _length = length;
    [self displayBGFinished];
}

@end

@implementation KLTRadarChartView_Inner

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)configParamParentView:(KLTRadarChartView *)parentView numberOfDimensions:(NSUInteger)numberOfDimensions dataIndex:(NSUInteger)dataIndex {
    self.parentView = parentView;
    self.numberOfDimensions = numberOfDimensions;
    self.dataIndex = dataIndex;
}

- (void)displayWithAnimation:(BOOL)isAnimation {
    [self setNeedsDisplay];
    if ([self.parentView.dataSource respondsToSelector:@selector(dimensionForIndex:dataIndex:inView:)]) {
        static CGFloat scale = 2.0;
        static dispatch_once_t t;
        dispatch_once(&t, ^{
            scale = SAFEFLOAT([UIScreen mainScreen].scale);
        });
        
        if (isAnimation) {
            CGFloat duration = 0.5f;
            CABasicAnimation *scaleAnim = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
            scaleAnim.fromValue = @0.1;
            scaleAnim.toValue = @1.0;
            scaleAnim.fillMode = kCAFillModeForwards;
            scaleAnim.duration = duration;
            scaleAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            [self.layer addAnimation:scaleAnim forKey:@"scaleAnim"];
        }
        
        CGFloat length = CGRectGetWidth(self.bounds) / 2;
        CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        double arcItem = 2 * M_PI / self.numberOfDimensions;
        
        BOOL customLatitudePath = [self.parentView.delegate respondsToSelector:@selector(customLatitudePath:dataIdx:inView:)];
        BOOL customLatitudeColor = [self.parentView.delegate respondsToSelector:@selector(colorForDimensionValueLatitudeAtDataIdx:inView:)];
        BOOL customFillColor = [self.parentView.delegate respondsToSelector:@selector(colorForDimensionValueFillAtDataIdx:inView:)];
        
        BOOL customLongitudePath = [self.parentView.delegate respondsToSelector:@selector(customLongitudePath:styleOfIndex:total:dataIdx:inView:)];
        BOOL customLongitudeColor = [self.parentView.delegate respondsToSelector:@selector(colorForDimensionValueLongitudeAtIndex:total:dataIdx:inView:)];
        
        BOOL customDescView = [self.parentView.delegate respondsToSelector:@selector(valueDescriptionViewForIdx:dataIdx:data:point:availableRect:inView:)];
        
        CAShapeLayer *fillLayer = nil;
        UIBezierPath *fillPath = nil;
        UIColor *strokeColor = [UIColor blackColor];
        UIColor *fillColor = [UIColor clearColor];
        if (customLatitudeColor) {
            UIColor *t_strokeColor = [self.parentView.delegate colorForDimensionValueLatitudeAtDataIdx:self.dataIndex inView:self.parentView];
            if ([t_strokeColor isKindOfClass:[UIColor class]]) {
                strokeColor = t_strokeColor;
            }
        }
        if (customFillColor) {
            UIColor *t_fillColor = [self.parentView.delegate colorForDimensionValueFillAtDataIdx:self.dataIndex inView:self.parentView];
            if ([fillColor isKindOfClass:[UIColor class]]) {
                fillColor = t_fillColor;
            }
        }
        if ([fillColor isEqual:[UIColor clearColor]] && [strokeColor isEqual:[UIColor clearColor]]) {
            // 当即无填充色又无描边色时可以忽略fillLayer
        } else {
            fillLayer = [CAShapeLayer layer];
            fillPath = [UIBezierPath bezierPath];
            [self.layer addSublayer:fillLayer];
        }

        CGPoint startPoint = CGPointZero;
        for (NSUInteger dimensionIdx = 0; dimensionIdx < self.numberOfDimensions; dimensionIdx++) {
            KLTRadarChartDataDimension *dimensionData = [self.parentView.dataSource dimensionForIndex:dimensionIdx dataIndex:self.dataIndex inView:self.parentView];
            NSAssert(dimensionData.value >= dimensionData.min && dimensionData.value <= dimensionData.max , @"dimensionData.value must between (min~max)");
            NSAssert(dimensionData.max > dimensionData.min, @"please make sure dimensionData max > min");
            if ([dimensionData isKindOfClass:[KLTRadarChartDataDimension class]]) {
                CGFloat rate = (dimensionData.value - dimensionData.min) / (dimensionData.max - dimensionData.min);
                rate = !isnan(rate) ? rate : 1;
                CGFloat currentLength = length * rate;
                CGPoint currentPoint = CGPointMake(center.x + currentLength * cos(s_starArc + arcItem * dimensionIdx), center.y + currentLength * sin(s_starArc + arcItem * dimensionIdx));
                if (fillLayer) {
                    // 绘制纬线和填充色
                    if (fillPath) {
                        fillPath.lineWidth = 2.0 / scale / 2;
                        if (customLatitudePath) {
                            [self.parentView.delegate customLatitudePath:fillPath dataIdx:self.dataIndex inView:self.parentView];
                        }
                        if (dimensionIdx == 0) {
                            startPoint = CGPointMake(center.x + currentLength * cos(s_starArc + arcItem * 0), center.y + currentLength * sin(s_starArc + arcItem * 0));
                            [fillPath moveToPoint:startPoint];
                        } else if (dimensionIdx == self.numberOfDimensions - 1) {
                            [fillPath addLineToPoint:currentPoint];
                            [fillPath addLineToPoint:startPoint];
                        } else {
                            [fillPath addLineToPoint:currentPoint];
                        }
                        
                    }
                    fillLayer.strokeColor = strokeColor.CGColor;
                    fillLayer.fillColor = fillColor.CGColor;
                    fillLayer.path = fillPath.CGPath;
                }
                if (customLongitudeColor) {
                    // 因为默认是透明的所以不绘制，而当实现了代理时需要进一步判断是否绘制
                    UIColor *strokeLineColor = [UIColor clearColor];
                    UIColor *temp = [self.parentView.delegate colorForDimensionValueLongitudeAtIndex:dimensionIdx total:self.numberOfDimensions dataIdx:self.dataIndex inView:self.parentView];
                    if ([temp isKindOfClass:[UIColor class]]) {
                        strokeLineColor = temp;
                    }
                    if ([strokeLineColor isEqual:[UIColor clearColor]]) {
                        // 虽然实现了代理，但还是透明的，不需要绘制
                        continue;
                    } else {
                        // 绘制经线
                        CAShapeLayer *dimenstionLayer = [CAShapeLayer layer];
                        UIBezierPath *path = [UIBezierPath bezierPath];
                        path.lineWidth = 2.0 / scale / 2;
                        if (customLongitudePath) {
                            [self.parentView.delegate customLongitudePath:path styleOfIndex:dimensionIdx total:self.numberOfDimensions dataIdx:self.dataIndex inView:self.parentView];
                        }
                        [path moveToPoint:center];
                        [path addLineToPoint:currentPoint];
                        dimenstionLayer.fillColor = [UIColor clearColor].CGColor;
                        dimenstionLayer.strokeColor = [strokeLineColor CGColor];
                        dimenstionLayer.path = path.CGPath;
                        [self.layer addSublayer:dimenstionLayer];
                    }
                }
                if (customDescView) {
                    // 标题的描述视图
                    UIView *descView = [self.parentView.delegate valueDescriptionViewForIdx:dimensionIdx dataIdx:self.dataIndex data:dimensionData point:currentPoint availableRect:self.bounds inView:self.parentView];
                    if ([descView isKindOfClass:[UIView class]]) {
                        [self addSubview:descView];
                    }
                }
                
            } else {
                @throw [NSException exceptionWithName:kException reason:@"dimensionForIndex:dataIndex:view: must return a KLTRadarChartDataDimension class object" userInfo:nil];
            }
        }
        
    }
}

@end
