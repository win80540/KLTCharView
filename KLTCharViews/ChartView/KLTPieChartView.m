//
//  KLTPieCircleView.m
//  
//
//  Created by 田凯 on 15/11/20.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "KLTPieChartView.h"
#import <UIKit/NSStringDrawing.h>

static NSString * const kMasAnm = @"maskAnm";
static const CGFloat bg_space = 10;
static const CGFloat distence_line_circle = 4;
static const CGFloat distence_line_edge = 10;
static const CGFloat des_line_PointR = 2;
static const CGFloat pieSpace = 0.0015;
static const CGFloat minPieSpace = 0.008; //最小pie 比重小于该值会自动修补
#pragma mark - KLTPieItem
@interface KLTPieItem (){
    
}
@property (assign,nonatomic) double startPercentage;
@property (assign,nonatomic) double midPrecentage;
@property (assign,nonatomic) double endPercentage;
@property (assign,nonatomic) double percentage;
@property (assign,nonatomic) double text_offsetPre; //textView的角度偏移
@property (assign,nonatomic) BOOL showText; //因跟其他textView重叠而不予显示
@property (assign,nonatomic) BOOL isFixed; //是否因为比重太小而修补过
@end
@implementation KLTPieItem

@end

#pragma mark - KLTPieCircleView
@interface KLTPieChartView (){
    NSMutableArray<CAShapeLayer *> *_pieLayers;
    NSMutableArray<CAShapeLayer *> *_pieSpaceLayers;
    NSMutableArray<CAShapeLayer *> *_lineLayers;
    NSMutableArray<CAShapeLayer *> *_circleLayers;
    NSMutableArray<UIView *> *_textViews;
}

@property (strong, nonatomic) CAShapeLayer *maskAnimLayer;
@property (strong, nonatomic) CAShapeLayer *bgLayer;
//@property (strong, nonatomic) UIView * pieContainterView;
@property (strong, nonatomic) CALayer *pieContainerLayer;
@property (assign, nonatomic) double offsetAngular;  //整个图的角度偏移
@end

@implementation KLTPieChartView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configSelf];
    }
    return self;
}

- (void)displaywithAnimation:(BOOL)isAnimation{
    //刷新子Pie Layer
    [self freshPieSubLayer];
    
    if (self.showDescrition) {
        //刷新子 Line Layer
        [self freshLineSubLayer];
    }
    //是否需要动画
    if (isAnimation){
        [self beginAnim];
    }
}
- (void)beginAnim{
    WEAK_SELF(weakSelf);
    [self.layer setMask:self.maskAnmLayer];
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        self.layer.mask = nil;
        if (weakSelf.showDescrition) {
            [_lineLayers enumerateObjectsUsingBlock:^(CAShapeLayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj addAnimation:[weakSelf createStrokeEndAnim] forKey:@"kMasAnm"];
            }];
        }
    }];
    [self.maskAnmLayer addAnimation:[self createStrokeEndAnim] forKey:kMasAnm];
    [CATransaction commit];
}
#pragma mark private methods
- (void)configSelf{
    _startAnglePercent = 0.0;
    _pieBorderColor = [UIColor grayColor];
    _colorOfDescLine = [UIColor grayColor];
    self.layer.masksToBounds = YES;
}

- (CABasicAnimation *)createStrokeEndAnim{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.fromValue = @0;
    animation.toValue = @1;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.duration = 0.5f;
    animation.removedOnCompletion = YES;
    return animation;
}
- (void)freshPieSubLayer{
    //删除现有layer
    [_bgLayer removeFromSuperlayer];
    [_pieContainerLayer removeFromSuperlayer];
    
    _pieLayers = [@[] mutableCopy];
    _pieContainerLayer = [CALayer layer];
    
    WEAK_SELF(weakSelf);
    if (_pieItems.count>1) { //大于1个pie 需要有间隙
        [_pieItems enumerateObjectsUsingBlock:^(KLTPieItem * _Nonnull currentPie, NSUInteger idx, BOOL * _Nonnull stop) {
            if (currentPie.value != 0) {
                CAShapeLayer *pieLayer = [weakSelf newPieLayerWithRadius:_radius
                                                                   width:_pieWidth
                                                               fillColor:currentPie.pieColor
                                                         startPercentage:currentPie.startPercentage+pieSpace
                                                           endPercentage:currentPie.endPercentage-pieSpace];
                [_pieLayers addObject: pieLayer];
            }
        }];
    }else if(_pieItems.count == 1){ //只有1个pie 不需要有间隙
        KLTPieItem *currentPie = _pieItems[0];
        CAShapeLayer *pieLayer = [weakSelf newPieLayerWithRadius:_radius
                                                           width:_pieWidth
                                                       fillColor:currentPie.pieColor
                                                 startPercentage:currentPie.startPercentage
                                                   endPercentage:currentPie.endPercentage];
        [_pieLayers addObject: pieLayer];
    }
    
    //添加新背景环layer
    [self.layer addSublayer:self.bgLayer];
    
    //添加pieLayers 到当前layer
    [_pieLayers enumerateObjectsUsingBlock:^(CAShapeLayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [weakSelf.pieContainerLayer addSublayer:obj];
    }];
    
    [self.layer addSublayer:_pieContainerLayer];
}

- (BOOL)isCollisionRect:(CGRect)rect testRectArray:(NSArray<NSValue *>*)rectArray{
    __block BOOL collision = NO;
    if (CGRectIntersectsRect(self.bounds, rect)) {
        CGRect intersectionRect = CGRectIntersection(self.bounds, rect);
        if(intersectionRect.size.width == rect.size.width && intersectionRect.size.height == rect.size.height){
            [rectArray enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGRect existRect = [obj CGRectValue];
                if (CGRectIntersectsRect(existRect, rect)) {
                    collision = YES;
                    *stop = YES;
                }
            }];
            return collision;
        }
    }
    return YES;
}

- (void)freshLineSubLayer{
    //删除现有layer
    [_circleLayers enumerateObjectsUsingBlock:^(CAShapeLayer *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperlayer];
    }];
    _circleLayers = [@[] mutableCopy];
    
    [_lineLayers enumerateObjectsUsingBlock:^(CAShapeLayer *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperlayer];
    }];
    _lineLayers = [@[] mutableCopy];

    //删除现有Views
    [_textViews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    _textViews = [@[] mutableCopy];
    
    NSMutableArray<NSValue *> *rectArray = [@[] mutableCopy]; //可以显示的Rect数组 用于计算rect重叠
    CGPoint centerP = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    for (NSUInteger i=0; i<_pieItems.count; i++) {
        KLTPieItem *currentPie = _pieItems[i];
        if(currentPie.showText == NO){
            continue;
        }
        CGFloat textStartPrecentage = currentPie.midPrecentage+currentPie.text_offsetPre; //获取当前pie的中位百分比
        double angular = M_PI * 2 * textStartPrecentage +_offsetAngular;  //获取中位百分比的对应的角度
        CGPoint midPieP = CGPointMake(centerP.x-(_radius+bg_space+distence_line_circle)*cos(angular),
                                      centerP.y-(_radius+bg_space+distence_line_circle)*sin(angular));          //中位角度对应的 点
        CGPoint edgeP = CGPointMake(centerP.x-(_radius+bg_space+distence_line_circle+distence_line_edge)*cos(angular),
                                    centerP.y-(_radius+bg_space+distence_line_circle+distence_line_edge)*sin(angular)); //同角度延伸的点
        //计算文字所需要的szie
        CGPoint farP;
        CGSize sizeTile = [currentPie.title size];
        CGSize sizeDesc = [currentPie.desc size];
        CGFloat farLine = MAX(sizeTile.width, sizeDesc.width);
        
        //计算显示文字View的Rect
        CGRect rectTitle = (CGRect){CGPointMake(0, 0),sizeTile};
        CGRect rectDesc = (CGRect){CGPointMake(0, sizeDesc.height),sizeDesc};
        __block CGRect rectText = CGRectUnion(rectTitle, rectDesc);
        if (edgeP.x > centerP.x) {
            farP = CGPointMake(edgeP.x + farLine, edgeP.y);
            rectText.origin = CGPointMake(edgeP.x, edgeP.y-sizeTile.height);
        }else{
            farP = CGPointMake(edgeP.x - farLine, edgeP.y);
            rectText.origin = CGPointMake(farP.x, farP.y-sizeTile.height);
        }
        //检查是否跟已有View重叠
        if([self isCollisionRect:rectText testRectArray:rectArray]){
            //重叠 尝试偏移角度
            double flowSpace = (currentPie.endPercentage - currentPie.midPrecentage) /2;  //可以偏移的最大角度
            if (currentPie.text_offsetPre <= flowSpace) {
                //偏移角度
                currentPie.text_offsetPre += flowSpace * 0.2;
                //偏移重新计算所以i--
                i--;
            }else{
                //已经过了最大便宜角度 不予显示
                currentPie.showText = NO;
            }
            continue;
        }
        
        //可以添加该rectText
        [rectArray addObject:[NSValue valueWithCGRect:rectText]];
        
        {
            //生成textView
            UIView * textView = [[UIView alloc] initWithFrame:rectText];
            UILabel *lbTitle = [[UILabel alloc] initWithFrame:rectTitle];
            lbTitle.attributedText = currentPie.title;
            UILabel *lbDesc = [[UILabel alloc] initWithFrame:rectDesc];
            lbDesc.attributedText = currentPie.desc;
            [textView addSubview:lbTitle];
            [textView addSubview:lbDesc];
            
            [_textViews addObject:textView];
        }
        {
            //生成line开始时的小圆点
            CAShapeLayer *circleShaper = [CAShapeLayer layer];
            circleShaper.strokeColor = _colorOfDescLine.CGColor;
            circleShaper.fillColor = _colorOfDescLine.CGColor;
            UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:midPieP radius:des_line_PointR startAngle:0 endAngle:2*M_PI clockwise:NO];
            circleShaper.path = path.CGPath;
            
            [_circleLayers addObject:circleShaper];
        }
        {
            //生成line
            CAShapeLayer *lineShaper = [CAShapeLayer layer];
            lineShaper.strokeColor = _colorOfDescLine.CGColor;
            lineShaper.fillColor = [UIColor clearColor].CGColor;
            UIBezierPath *pathLine = [UIBezierPath bezierPath];
            [pathLine moveToPoint:midPieP];
            [pathLine addLineToPoint:edgeP];
            [pathLine addLineToPoint:farP];
            lineShaper.path = pathLine.CGPath;
            
            [_lineLayers addObject:lineShaper];
        }
        
    }
    
    //添加lineLayers 到当前layer
    WEAK_SELF(weakSelf);
    [_circleLayers enumerateObjectsUsingBlock:^(CAShapeLayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [weakSelf.layer addSublayer:obj];
    }];
    [_lineLayers enumerateObjectsUsingBlock:^(CAShapeLayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [weakSelf.layer addSublayer:obj];
    }];
    [_textViews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [weakSelf addSubview:obj];
    }];
    
}
- (CAShapeLayer *)newPieLayerWithRadius:(CGFloat)radius
                                  width:(CGFloat)width
                            fillColor:(UIColor *)strokeColor
                        startPercentage:(CGFloat)startPercentage
                          endPercentage:(CGFloat)endPercentage
{
    CAShapeLayer *pie = [CAShapeLayer layer];
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    
    UIBezierPath *bPath = [UIBezierPath bezierPathWithArcCenter:center
                                                        radius:radius - width/2.0
                                                    startAngle:-M_PI + M_PI * 2 * _startAnglePercent + M_PI * 2 * startPercentage + _offsetAngular
                                                      endAngle:-M_PI + M_PI * 2 * _startAnglePercent + M_PI * 2 * endPercentage + _offsetAngular
                                                     clockwise:YES];

    pie.fillColor = [UIColor clearColor].CGColor;
    pie.strokeColor = strokeColor.CGColor;
    
    pie.strokeStart = 0;
    pie.strokeEnd = 1;
    
    pie.lineWidth = width;
    pie.path = bPath.CGPath;
    
    return pie;
}



#pragma mark getter setter
- (void)setPieItems:(NSArray<KLTPieItem *> *)pieItems{
    if (pieItems.count==0) {
        return;
    }
    //以pieItems生成pieLayers
    //处理
    __block double sum = _value_100;
    if (sum == 0){
        [pieItems enumerateObjectsUsingBlock:^(KLTPieItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            sum += [obj value];
        }];
    }
    CGFloat fixedPercentage = 0;
    NSUInteger fixedPieNumders = 0;
    NSMutableArray *canAdjustPies = [@[] mutableCopy];
    for (NSUInteger i=0; i<pieItems.count; i++) {
        //第一次遍历修补小于最小宽度的pie
        KLTPieItem *currentPie = pieItems[i];
        currentPie.percentage = currentPie.value/sum;
        if (currentPie.percentage > 0 && currentPie.percentage < minPieSpace){
            fixedPercentage = minPieSpace - currentPie.percentage;
            fixedPieNumders ++;
            currentPie.isFixed = YES;
            currentPie.percentage = minPieSpace;
        }
    }
    for (NSUInteger i=0; i<pieItems.count; i++) {
        //第二次遍历找出可以出让宽度的pie
        KLTPieItem *currentPie = pieItems[i];
        if (currentPie.isFixed) {
            continue;
        }
        if(currentPie.percentage - fixedPercentage/(pieItems.count-fixedPieNumders)*4>minPieSpace){
            [canAdjustPies addObject:currentPie];
        }
    }
    for (KLTPieItem *currentPie in canAdjustPies) {
        //出让宽度
        currentPie.percentage = currentPie.percentage - fixedPercentage/canAdjustPies.count;
    }
    for (NSUInteger i=0; i<pieItems.count; i++) {
        KLTPieItem *currentPie = pieItems[i];
        currentPie.startPercentage = i>0?pieItems[i-1].endPercentage:0.0;
        currentPie.endPercentage = currentPie.startPercentage + currentPie.percentage;
        currentPie.midPrecentage = (currentPie.endPercentage + currentPie.startPercentage)/2; //获取当前pie的中位百分比
        currentPie.showText = YES;
        if (ABS(currentPie.midPrecentage - 0.25) <= 0.05) {         //不让其出现顶部垂直现象
            _offsetAngular -=  M_PI_4*0.30;
        }
    }
    NSMutableArray *notZeroPie = [NSMutableArray arrayWithCapacity:pieItems.count];
    [pieItems enumerateObjectsUsingBlock:^(KLTPieItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.percentage >= minPieSpace) {
            [notZeroPie addObject:obj];
        }
    }];
    _pieItems = [notZeroPie copy];
}

- (CAShapeLayer *)maskAnmLayer{
    if (_maskAnimLayer) {
        return _maskAnimLayer;
    }
    _maskAnimLayer = [self newPieLayerWithRadius:_radius+bg_space width:_pieWidth+bg_space*2 fillColor:[UIColor blackColor] startPercentage:0 endPercentage:1];
    return _maskAnimLayer;
}
- (CAShapeLayer *)bgLayer{
    if (_bgLayer) {
        return _bgLayer;
    }
    _bgLayer = [self newPieLayerWithRadius:_radius+bg_space width:_pieWidth+bg_space*2 fillColor:_pieBorderColor startPercentage:0 endPercentage:1];
    return _bgLayer;
}
@end
