//
//  WWLJPlayerView.h
//  WWLJMPMovieplayer
//
//  Created by iShareme on 15/7/13.
//  Copyright (c) 2015年 iShareme. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 *  自定义的控制面板
 *
 *  #pragma mark - playerView
 *
 */



@interface WWLJPlayerView : UIView
///上边栏
@property (nonatomic, strong) UIView *topBar;
///下边栏
@property (nonatomic, strong) UIView *bottomBar;
///播放按钮
@property (nonatomic, strong) UIButton *playButton;
///暂停按钮
@property (nonatomic, strong) UIButton *pauseButton;
///全屏按钮
@property (nonatomic, strong) UIButton *fullScreenButton;
///退出全屏按钮
@property (nonatomic, strong) UIButton *shrinkScreenButton;
///滑动条
@property (nonatomic, strong) UISlider *progressSlider;
///关闭按钮
@property (nonatomic, strong) UIButton *closeButton;
///时间label
@property (nonatomic, strong) UILabel *timeLabel;
///进度条
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;


- (void)animateHide;
- (void)animateShow;
- (void)autoFadeOutControlBar;
- (void)cancelAutoFadeOutControlBar;

@end
