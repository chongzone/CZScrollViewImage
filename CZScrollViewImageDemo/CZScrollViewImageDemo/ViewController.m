//
//  ViewController.m
//  CZCirclePhotosDemo
//
//  Created by chongzone on 15/5/6.
//  Copyright © 2015年 chongzone. All rights reserved.
//

#import "ViewController.h"

#import "CZScrollViewImage.h"

@interface ViewController ()

/** 滚动视图 */
@property (nonatomic, strong) CZScrollViewImage *scrollView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *titleInfo = @[@"One", @"Two", @"Three", @"Four"];
    
    //既有本地图片也有网络图片
    NSArray *imageURL = @[@"http://www.5068.com/u/faceimg/20140725173411.jpg",
                          [UIImage imageNamed:@"1"],
                          @"http://file27.mafengwo.net/M00/52/F2/wKgB6lO_PTyAKKPBACID2dURuk410.jpeg",
                          [UIImage imageNamed:@"2"],
                          [UIImage imageNamed:@"3"]
                          ];

    CGRect rect = CGRectMake(10, 100, CGRectGetWidth(self.view.frame) - 20, 350);
    
    _scrollView = [[CZScrollViewImage alloc] initWithFrame:rect imageURL:imageURL placeholderImage:@"placeholder" titleInfo:titleInfo titleInfoPosition:TitleInfoPositionLeft pageControlPosition:PageControlPositionRight completionClickImage:^(NSInteger imageIndex, NSString *imageURL) {
        NSLog(@"%lu - %@\n",imageIndex,imageURL);
    }];
    
    [_scrollView setPageControlWithCurrentImage:[UIImage imageNamed:@"current"] normalImage:[UIImage imageNamed:@"other"]];
    
    [self.view addSubview:_scrollView];
    
//    [_scrollView clearImageCache];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
