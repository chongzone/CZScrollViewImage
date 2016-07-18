//
//  CZScrollViewImage.h
//
//  Created by chongzone on 15/3/15.
//  Copyright © 2015年 chongzone. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^completionClick)(NSInteger imageIndex, NSString *imageURL);

/**
 *  UIPageControl 圆点位置
 */
typedef NS_ENUM(NSUInteger, PageControlPosition){
    PageControlPositionNone,
    PageControlPositionLeft,
    PageControlPositionCenter,
    PageControlPositionRight
};

/**
 *  图片上面文字信息 TitleInfo 显示位置
 */
typedef NS_ENUM(NSUInteger, TitleInfoPosition){
    TitleInfoPositionNone,
    TitleInfoPositionLeft,
    TitleInfoPositionCenter,
    TitleInfoPositionRight
};

/**
 *  循环滚动的实现
 */
@interface CZScrollViewImage : UIView

/** 滚动图片数组（本地、网络） */
@property (nonatomic, strong) NSArray *imageURL;

/** 文字信息数组，默认不显示 */
@property (nonatomic, strong) NSArray *titleInfo;

/** 显示图片的占位图 */
@property (nonatomic, strong) UIImage *placeholderImage;

/** 分页控件，默认在底部中间 */
@property (nonatomic, strong) UIPageControl *pageControl;

/** 滚动间隔，默认为2s */
@property (nonatomic, assign) NSTimeInterval scrollInterval;

/** 是否定时循环滚动，默认循环YES */
@property (nonatomic, assign, getter=isCyleScroll) BOOL cycleScroll;

/** 点击图片的触发动作 */
@property (nonatomic, copy  ) completionClick     completionClick;

/** 设置文字信息对应的位置，默认左边 */
@property (nonatomic, assign) TitleInfoPosition   titleInfoPosition;

/** 设置分页控件显示位置 */
@property (nonatomic, assign) PageControlPosition pageControlPosition;

/** 开启定时器 */
- (void)startTimer;

/** 关闭定时器 */
- (void)stopTimer;

/** 清除内存中的图片缓存 */
- (void)clearImageCache;

/**
 *  自定义分页控件的point颜色
 *
 *  @param currentImage 显示的点颜色
 *  @param normalImage  默认的点颜色
 */
- (void)setPageControlWithCurrentImage:(UIImage *)currentImage normalImage:(UIImage *)normalImage;

/**
 *  图片滚动的初始化方法
 *
 *  @param frame                视图滚动的范围
 *  @param imageURL             传入的图片数组
 *  @param placeholderImage     加载前的图片占位图
 *  @param titleInfo            图片上面的文字信息
 *  @param titleInfoPosition    文字信息的位置
 *  @param pageControlPosition  分页控件的位置
 *  @param completionClickImage 点击图片完成后触发的动作
 *
 *  @return 图片滚动的初始化
 */
- (instancetype)initWithFrame:(CGRect)frame
                     imageURL:(NSArray *)imageURL
             placeholderImage:(NSString *)placeholderImage
                    titleInfo:(NSArray *)titleInfo titleInfoPosition:(TitleInfoPosition)titleInfoPosition
          pageControlPosition:(PageControlPosition)pageControlPosition
         completionClickImage:(completionClick)completionClickImage;

+ (instancetype)scrollImageWithFrame:(CGRect)frame
                             mageURL:(NSArray *)imageURL
                    placeholderImage:(NSString *)placeholderImage
                           titleInfo:(NSArray *)titleInfo
                   titleInfoPosition:(TitleInfoPosition)titleInfoPosition
                 pageControlPosition:(PageControlPosition)pageControlPosition
                completionClickImage:(completionClick)completionClickImage;

@end
