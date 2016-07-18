//
//  CZScrollViewImage.m
//
//  Created by chongzone on 15/3/15.
//  Copyright © 2015年 chongzone. All rights reserved.
//

#import "CZScrollViewImage.h"

/**
 *  默认滚动间隔 这里设置最低 1.5seconds
 */
static const CGFloat kScrollInterval = 1.5f;

/**
 *  归档缓存路径
 */
#define kArchiveFile(str) [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:str]

/**
 *  UIScrollView 滚动方向
 */
typedef NS_ENUM(NSUInteger, ScrollImageDirection) {
    ScrollImageDirectionNone,
    ScrollImageDirectionLeft,
    ScrollImageDirectionRight
};

@interface CZScrollViewImage ()<UIScrollViewDelegate> {
    CGFloat _scrollW;
    CGFloat _scrollH;
}

@property (nonatomic, assign) NSInteger currentImageIndex;
@property (nonatomic, assign) NSInteger nextImageIndex;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) NSTimer *scrollTimer;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *currentImageView;
@property (nonatomic, strong) UIImageView *nextImageView;

/** 加载完毕后的存储的图片数组 */
@property (nonatomic, strong) NSMutableArray *imageArray;

/** 内存缓存的图片字典 */
@property (nonatomic, strong) NSMutableDictionary *imageDict;

/** 内存缓存的队列字典 */
@property (nonatomic, strong) NSMutableDictionary *operationDict;

/** 队列对象 */
@property (nonatomic, strong) NSOperationQueue *operationQueue;

/** 滚动视图的方向 */
@property (nonatomic, assign) ScrollImageDirection scrollImageDirection;

@end

@implementation CZScrollViewImage

-(instancetype)initWithFrame:(CGRect)frame {
    if ([super initWithFrame:frame]) {
        [self setUpControls];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ([super initWithCoder:aDecoder]) {
        [self setUpControls];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
                     imageURL:(NSArray *)imageURL
             placeholderImage:(NSString *)placeholderImage
                    titleInfo:(NSArray *)titleInfo
            titleInfoPosition:(TitleInfoPosition)titleInfoPosition
          pageControlPosition:(PageControlPosition)pageControlPosition
         completionClickImage:(completionClick)completionClickImage {
    if (self = [super init]) {
        self.frame           = frame;
        _placeholderImage    = [UIImage imageNamed:placeholderImage];

        self.imageURL        = imageURL;
        self.titleInfo       = titleInfo;
        self.completionClick = completionClickImage;

        _titleInfoPosition   = titleInfoPosition;
        _pageControlPosition = pageControlPosition;
    }
    return self;
}

+ (instancetype)scrollImageWithFrame:(CGRect)frame
                             mageURL:(NSArray *)imageURL
                    placeholderImage:(NSString *)placeholderImage
                           titleInfo:(NSArray *)titleInfo
                   titleInfoPosition:(TitleInfoPosition)titleInfoPosition
                 pageControlPosition:(PageControlPosition)pageControlPosition
                completionClickImage:(completionClick)completionClickImage {
    
    return [[self alloc] initWithFrame:frame
                              imageURL:imageURL
                      placeholderImage:placeholderImage
                             titleInfo:titleInfo
                     titleInfoPosition:titleInfoPosition
                   pageControlPosition:pageControlPosition
                  completionClickImage:completionClickImage];
}

#pragma mark - 设置视图内的控件

- (void)setUpControls {
    _imageArray     = [NSMutableArray array];
    _imageDict      = [NSMutableDictionary dictionary];
    _operationDict  = [NSMutableDictionary dictionary];
    _operationQueue = [NSOperationQueue new];
    
    _scrollView     = [UIScrollView new];
    [self addSubview:_scrollView];
    
    _scrollView.bounces                        = NO;
    _scrollView.delegate                       = self;
    _scrollView.pagingEnabled                  = YES;
    _scrollView.clipsToBounds                  = YES;
    _scrollView.backgroundColor                = [UIColor whiteColor];

    _scrollView.contentInset                   = UIEdgeInsetsZero;//保证存在导航栏时不会导致scrollView的子控件下移64个单位
    _scrollView.showsVerticalScrollIndicator   = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    
    _pageControl = [UIPageControl new];
    [self addSubview:_pageControl];
    
    /**
     *  bringSubviewToFront 保证该视图保持在UI前面，对应的方法（sendSubviewToBack）则保持该视图在UI背面
     */
    [self bringSubviewToFront:_pageControl];
    
    _pageControl.hidesForSinglePage          = YES;
    _pageControl.userInteractionEnabled      = NO;


    _currentImageView                        = [UIImageView new];
    _currentImageView.userInteractionEnabled = YES;
    [_scrollView addSubview:_currentImageView];
    
    [_currentImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickImageView)]];
    
    _nextImageView = [UIImageView new];
    [_scrollView addSubview:_nextImageView];
    
    //默认开启定时循环
    _cycleScroll = YES;
    
    /**
     *  控件初始化完毕监听系统内存警告
     */
    [[NSNotificationCenter defaultCenter] addObserver:[UIApplication sharedApplication] selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    _scrollView.frame = self.bounds;
    
    _scrollW  = CGRectGetWidth(self.bounds);
    _scrollH  = CGRectGetHeight(self.bounds);
    
    _scrollView.contentOffset = CGPointMake(_scrollW, 0);
    _scrollView.contentSize   = _imageArray.count > 1 ? CGSizeMake(_scrollW * 3, 0) : CGSizeMake(_scrollW, 0);

    _currentImageView.frame   = CGRectMake(_scrollW, 0, _scrollW, _scrollH);

    
    if (_pageControlPosition == PageControlPositionNone) return;
    
    _pageControl.numberOfPages = _imageArray.count;
    
    /**
     *  自定义pageControl --- sizeForNumberOfPages == numberOfPages + 4
     *  系统的pageControl --- sizeForNumberOfPages == numberOfPages
     */
    CGSize size = [_pageControl sizeForNumberOfPages:_imageArray.count + 4];
    
    switch (_pageControlPosition) {
        case PageControlPositionLeft: {
            _pageControl.frame  = CGRectMake(20, _scrollH - size.height, size.width, size.height);
        }
            break;
        case PageControlPositionCenter: {
            _pageControl.frame  = CGRectMake(0, _scrollH - size.height, size.width, size.height);
            _pageControl.center = CGPointMake(_scrollW / 2, _pageControl.center.y);
        }
            break;
        case PageControlPositionRight: {
            _pageControl.frame  = CGRectMake(_scrollW - size.width - 20, _scrollH - size.height, size.width, size.height);
        }
            break;
        default:
            break;
    }
    self.titleLabel.frame = CGRectMake(0, _scrollH - size.height, _scrollW, size.height);
}

- (void)clickImageView {
    !self.completionClick ? :self.completionClick(self.currentImageIndex,_imageArray[self.currentImageIndex]);
}

/**
 *  对于滚动图片来说，上面的提示文字不是必须的，lazy处理
 */
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        [self addSubview:_titleLabel];
        
        //给文字背景设置黑色的蒙版 alpha 默认0.3 font 默认15
        _titleLabel.backgroundColor = [UIColor blackColor];
        _titleLabel.alpha           = 0.3;

        _titleLabel.font            = [UIFont systemFontOfSize:15];
        _titleLabel.textColor       = [UIColor whiteColor];
    }
    return _titleLabel;
}

- (void)setTitleInfo:(NSArray *)titleInfo {
    if (!titleInfo.count) {
        self.titleLabel.hidden = YES;
        return;
    }
    _titleInfo = titleInfo;
    
    //处理文字信息个数少于图片个数情况
    if (titleInfo.count < _imageArray.count) {
        NSMutableArray *titleInfos = [NSMutableArray arrayWithArray:titleInfo];
        for (NSInteger index = titleInfo.count; index < _imageArray.count; index ++) {
            [titleInfos addObject:@""];
        }
        _titleInfo = titleInfos;
    }
    
    /**
     *  处理首次加载图片导致延时显示文字信息 文字不需加载
     */
    self.titleLabel.text = [titleInfo firstObject];
    
    if (_titleInfoPosition == TitleInfoPositionNone) return;
    
    switch (_titleInfoPosition) {
        case TitleInfoPositionLeft: {
            self.titleLabel.textAlignment = NSTextAlignmentLeft;
        }
            break;
        case TitleInfoPositionCenter: {
            self.titleLabel.textAlignment = NSTextAlignmentCenter;
        }
            break;
        case TitleInfoPositionRight: {
            self.titleLabel.textAlignment = NSTextAlignmentRight;
        }
            break;
        default:
            break;
    }
}

- (void)setPlaceholderImage:(UIImage *)placeholderImage {
    _placeholderImage = placeholderImage;
    
}

/**
 *  设置分页控件的图片
 *  两个图片都不能为空，否则设置无效
 *  不设置则为系统默认
 */
- (void)setPageControlWithCurrentImage:(UIImage *)currentImage normalImage:(UIImage *)normalImage {
    if (!currentImage || !normalImage) return;
    
    [_pageControl setValue:normalImage forKey:@"_pageImage"];
    [_pageControl setValue:currentImage forKey:@"_currentPageImage"];
}

/**
 *  这个方法会在子视图添加到父视图或者离开父视图时调用
 */
- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (!newSuperview) { //解决当父View释放时，当前视图因为被Timer强引用而不能释放的问题
        [self stopTimer];
    }
    else {
        [self startTimer];
    }
}

- (void)setScrollInterval:(NSTimeInterval)scrollInterval {
    _scrollInterval = scrollInterval;
    [self startTimer];
}

- (void)startTimer {
    if (_imageArray.count <=1 ) {
        _cycleScroll = NO; 
        return;
    }
    
    if (_cycleScroll){
        self.scrollTimer = [NSTimer timerWithTimeInterval:_scrollInterval < 1.5 ? kScrollInterval : _scrollInterval target:self selector:@selector(nextScrollImage) userInfo:nil repeats:YES];
        
        [[NSRunLoop currentRunLoop] addTimer:self.scrollTimer forMode:NSRunLoopCommonModes];
    }else {
        [self stopTimer];
    }
}

- (void)stopTimer {
    [self.scrollTimer invalidate];
    self.scrollTimer = nil;
}

- (void)nextScrollImage {
    [self.scrollView setContentOffset:CGPointMake(CGRectGetWidth(self.frame) * 2, 0) animated:YES];
}

//根据滚动的方向更新下标、下张图片
- (void)setScrollImageDirection:(ScrollImageDirection)scrollImageDirection {
    if (scrollImageDirection == ScrollImageDirectionNone) return;
    
    _scrollImageDirection = scrollImageDirection;
    
    switch (scrollImageDirection) {
        case ScrollImageDirectionLeft: {
            self.nextImageView.frame = CGRectMake(_scrollW * 2, 0, _scrollW, _scrollH);
            self.nextImageIndex      = (self.currentImageIndex + 1 == _imageArray.count) ? 0 : self.currentImageIndex + 1;
        }
            break;
            case ScrollImageDirectionRight: {
            self.nextImageView.frame = CGRectMake(0, 0, _scrollW, _scrollH);
            self.nextImageIndex      = self.nextImageIndex < 0 ? _imageArray.count - 1 : self.currentImageIndex - 1 < 0? _imageArray.count - 1: self.currentImageIndex - 1;
        }
            break;
        default:
            break;
    }
    self.nextImageView.image =  _imageArray[self.nextImageIndex];
}

//根据UIScrollView的偏移量判断视图滚动的方向
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetX           = scrollView.contentOffset.x;
    self.scrollImageDirection = offsetX > _scrollW? ScrollImageDirectionLeft : offsetX < _scrollW ? ScrollImageDirectionRight : ScrollImageDirectionNone;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self stopTimer];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self startTimer];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self deceleratedScrollImage:scrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self deceleratedScrollImage:scrollView];
}

//滚动结束更新下标、显示的图片
- (void)deceleratedScrollImage:(UIScrollView *)scrollView {
    if (self.scrollView.contentOffset.x == _scrollW) return;
    
    self.currentImageIndex        = self.nextImageIndex;
    self.pageControl.currentPage  = self.currentImageIndex;//currentPage默认为0

    self.currentImageView.image   = self.nextImageView.image;
    self.currentImageView.frame   = CGRectMake(_scrollW, 0, _scrollW, _scrollH);

    //保证滚动视图永远在中间位置
    self.scrollView.contentOffset = CGPointMake(_scrollW, 0);
    
    if (_titleInfo.count) {
        self.titleLabel.text = _titleInfo[self.currentImageIndex];
    }
}

/**
 *  处理外界传入的图片数组
 */
- (void)setImageURL:(NSArray *)imageURL{
    _imageURL = imageURL;
    
    for (NSInteger index = 0; index < imageURL.count; index ++) {
        NSLog(@"imageURL --- %@",imageURL[index]);
        
        if ([imageURL[index] isKindOfClass:[UIImage class]]) { //本地图片
            [_imageArray addObject:imageURL[index]];
        }else { //网络图片
            [self downloadScrollImage:index];
        }
        
        self.scrollView.scrollEnabled = _imageArray.count > 1 ? YES : NO;
        self.scrollView.contentSize   = _imageArray.count > 1 ? CGSizeMake(_scrollW * 3, 0) : CGSizeMake(_scrollW, 0);
        self.currentImageView.image   = [_imageArray firstObject];
    }
}

#pragma mark - 下载图片

- (void)downloadScrollImage:(NSInteger)index {
    /**
     *  这里以参与轮播的图片为字典key
     */
    NSString *imageKey = _imageURL[index];
    
    //1. 从内存缓存中取图片
    UIImage *image = self.imageDict[imageKey];
    
    if (image) { // 内存中有图片
        _imageArray[index] = image; //添加图片到数组
        return;
    }
    
    //2. 从沙盒缓存中取图片
    NSString *imageCache = kArchiveFile(@"CZScrollViewImage");
    
    //获取imageKey的完整文件名(附带文件后缀)
    NSString *fullFile = [imageKey lastPathComponent];
    
    //拼接完整的路径 “／”
    NSString *completePath = [imageCache stringByAppendingPathComponent:fullFile];

    //获取沙盒数据
    NSData *imageData = [NSData dataWithContentsOfFile:completePath];
    
    if (imageData) { //沙盒中存在图片
        image                = [UIImage imageWithData:imageData];
        _imageArray[index]   = image;
        _imageDict[imageKey] = image;//存到缓存的图片字典
        return;
    }
    
    //3. 下载图片 - 先设置其占位图
    _imageArray[index] = _placeholderImage;
    
    //从缓存队列中查找图片
    NSBlockOperation *cacheQueue = self.operationDict[imageKey];
    
    if (cacheQueue) return; //这张图片有下载任务
    
    //创建一个队列
    cacheQueue = [NSBlockOperation blockOperationWithBlock:^{
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageKey]];
        
        if (imageData == nil) { //数据加载失败
            [_operationDict removeObjectForKey:imageKey]; //移除对应的队列
            return;
        }
        
        UIImage *image       = [UIImage imageWithData:imageData];
        _imageArray[index]   = image;
        _imageDict[imageKey] = image;
        
        if (_currentImageIndex == index){
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                _currentImageView.image = image;
            }];
        }
        
        [imageData writeToFile:completePath atomically:YES]; //文件写入沙盒
        [_operationDict removeObjectForKey:imageKey];
    }];
    
    [_operationQueue addOperation:cacheQueue]; //添加到队列中
    [_operationDict setObject:cacheQueue forKey:imageKey]; //存到缓存的操作队列字典
}

/**
 *  清除沙盒存储的图片缓存
 */
- (void)clearImageCache {
    [self clearCache:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]];
}

/**
 *  根据沙盒路径清除缓存
 */
- (void)clearCache:(NSString *)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        
        NSArray *childerFiles = [fileManager subpathsAtPath:path];
        for (NSString *fileName in childerFiles) {
            
            NSString *absolutePath = [path stringByAppendingPathComponent:fileName];
            [fileManager removeItemAtPath: absolutePath error:nil];
        }
    }
}

/**
 *  移除系统的通知
 */
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:[UIApplication sharedApplication] name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

@end
