//
//  WWLJMPMoviePlayer.h
//  WWLJMPMovieplayer
//
//  Created by 武文杰 on 15/7/13.
//  Copyright (c) 2015年 武文杰. All rights reserved.
//
@import MediaPlayer;
#import <UIKit/UIKit.h>

@interface WWLJMPMoviePlayer : MPMoviePlayerController

@property (nonatomic, copy)void(^dimissCompleteBlock)(void);
@property (nonatomic, assign) CGRect frame;

///初始化
- (instancetype)initWithFrame:(CGRect)frame;
- (void)showInWindow;
- (void)dismiss;
///设置播放网址
- (void)setContentURL:(NSURL *)contentURL;

@end
