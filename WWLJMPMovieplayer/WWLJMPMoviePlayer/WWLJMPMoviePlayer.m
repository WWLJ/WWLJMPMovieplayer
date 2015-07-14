//
//  WWLJMPMoviePlayer.m
//  WWLJMPMovieplayer
//
//  Created by 武文杰 on 15/7/13.
//  Copyright (c) 2015年 武文杰. All rights reserved.
//

#import "WWLJMPMoviePlayer.h"
#import "WWLJPlayerView.h"

///动画时间
static const CGFloat wVideoPlayerControllerAnimationTimeinterval = 0.3f;

@interface WWLJMPMoviePlayer ()
///控制面板view
@property (nonatomic, strong) WWLJPlayerView *videoControl;
///电影的背景
@property (nonatomic, strong) UIView *movieBackgroundView;
///是否是全屏状态
@property (nonatomic, assign) BOOL isFullscreenMode;
///初始的fream
@property (nonatomic, assign) CGRect originFrame;
///计时器
@property (nonatomic, strong) NSTimer *durationTimer;

@end


@implementation WWLJMPMoviePlayer

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        self.view.frame = frame;
        self.view.backgroundColor = [UIColor blackColor];
        self.controlStyle = MPMovieControlStyleNone;
        [self.view addSubview:self.videoControl];
        self.videoControl.frame = self.view.bounds;
        //添加监听  kvo
        [self configObserver];
        // 设置每个button的点击事件
        [self configControlAction];
        
    }
    return self;
}

#pragma mark - Override Method

- (void)setContentURL:(NSURL *)contentURL
{
    [self stop];
    [super setContentURL:contentURL];
    [self play];
}


#pragma mark - Publick Method
///放在window上面
- (void)showInWindow
{
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (!keyWindow) {
        keyWindow = [[[UIApplication sharedApplication] windows] firstObject];
    }
    [keyWindow addSubview:self.view];
    self.view.alpha = 0.0;
    //显示播放器
    [UIView animateWithDuration:wVideoPlayerControllerAnimationTimeinterval animations:^{
        self.view.alpha = 1.0;
    } completion:^(BOOL finished) {
        
    }];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

///点击关闭按钮
- (void)dismiss
{
    [self stopDurationTimer];
    [self stop];
    ///隐藏播放器
    [UIView animateWithDuration:wVideoPlayerControllerAnimationTimeinterval animations:^{
        self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        if (self.dimissCompleteBlock) {
            self.dimissCompleteBlock();
        }
    }];
    ///隐藏通知栏
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}


#pragma mark - Private Method
/// kvo  监听者
- (void)configObserver
{
    //监听屏幕旋转
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    // 监听播放状态
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMoviePlayerPlaybackStateDidChangeNotification) name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    // 监听加载
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMoviePlayerLoadStateDidChangeNotification) name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
    //缓冲
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMoviePlayerReadyForDisplayDidChangeNotification) name:MPMoviePlayerReadyForDisplayDidChangeNotification object:nil];
    //设置播放时间
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMovieDurationAvailableNotification) name:MPMovieDurationAvailableNotification object:nil];
}



- (void)configControlAction
{
    [self.videoControl.playButton addTarget:self action:@selector(playButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.pauseButton addTarget:self action:@selector(pauseButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.closeButton addTarget:self action:@selector(closeButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.fullScreenButton addTarget:self action:@selector(fullScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.shrinkScreenButton addTarget:self action:@selector(shrinkScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside];
   
    [self setProgressSliderMaxMinValues];
    [self monitorVideoPlayback];
}

// 监听播放状态
- (void)onMPMoviePlayerPlaybackStateDidChangeNotification
{
    if (self.playbackState == MPMoviePlaybackStatePlaying) {
        self.videoControl.pauseButton.hidden = NO;
        self.videoControl.playButton.hidden = YES;
        [self startDurationTimer];
        [self.videoControl.indicatorView stopAnimating];
        [self.videoControl autoFadeOutControlBar];
    } else {
        self.videoControl.pauseButton.hidden = YES;
        self.videoControl.playButton.hidden = NO;
        [self stopDurationTimer];
        if (self.playbackState == MPMoviePlaybackStateStopped) {
            [self.videoControl animateShow];
        }
    }
}

// 监听加载
- (void)onMPMoviePlayerLoadStateDidChangeNotification
{
    if (self.loadState & MPMovieLoadStateStalled) {
        [self.videoControl.indicatorView startAnimating];
    }
}

//缓冲  可以播放了
#warning 这个可能不对
- (void)onMPMoviePlayerReadyForDisplayDidChangeNotification
{
    NSLog(@"%@", @"可以播放了");
}

//设置播放时间
- (void)onMPMovieDurationAvailableNotification
{
    [self setProgressSliderMaxMinValues];
}

- (void)playButtonClick
{
    [self play];
    self.videoControl.playButton.hidden = YES;
    self.videoControl.pauseButton.hidden = NO;
}

- (void)pauseButtonClick
{
    [self pause];
    self.videoControl.playButton.hidden = NO;
    self.videoControl.pauseButton.hidden = YES;
}

- (void)closeButtonClick
{
    [self dismiss];
}

- (void)fullScreenButtonClick
{
    if (self.isFullscreenMode) {
        return;
    }
    self.originFrame = self.view.frame;
    CGFloat height = [[UIScreen mainScreen] bounds].size.width;
    CGFloat width = [[UIScreen mainScreen] bounds].size.height;
    CGRect frame = CGRectMake((height - width) / 2, (width - height) / 2, width, height);;
    [UIView animateWithDuration:0.3f animations:^{
        self.frame = frame;
        [self.view setTransform:CGAffineTransformMakeRotation(M_PI_2)];
    } completion:^(BOOL finished) {
        self.isFullscreenMode = YES;
        self.videoControl.fullScreenButton.hidden = YES;
        self.videoControl.shrinkScreenButton.hidden = NO;
    }];
}


- (void)shrinkScreenButtonClick
{
    if (!self.isFullscreenMode) {
        return;
    }
    [UIView animateWithDuration:0.3f animations:^{
        [self.view setTransform:CGAffineTransformIdentity];
        self.frame = self.originFrame;
    } completion:^(BOOL finished) {
        self.isFullscreenMode = NO;
        self.videoControl.fullScreenButton.hidden = NO;
        self.videoControl.shrinkScreenButton.hidden = YES;
    }];
}

//设置滑动条的Value值
- (void)setProgressSliderMaxMinValues {
    CGFloat duration = self.duration;
    self.videoControl.progressSlider.minimumValue = 0.f;
    self.videoControl.progressSlider.maximumValue = duration;
}

//开始接触滑动条,取消所有延时操作
- (void)progressSliderTouchBegan:(UISlider *)slider {
    [self pause];
    [self.videoControl cancelAutoFadeOutControlBar];
}

//根据活动条的值,改变当前播放时间,然后自动隐藏控制面板
- (void)progressSliderTouchEnded:(UISlider *)slider {
    [self setCurrentPlaybackTime:floor(slider.value)];
    [self play];
    [self.videoControl autoFadeOutControlBar];
}

//拖动滑动条实现改变
- (void)progressSliderValueChanged:(UISlider *)slider {
    double currentTime = floor(slider.value);
    double totalTime = floor(self.duration);
    [self setTimeLabelValues:currentTime totalTime:totalTime];
}

//改变播放时间的方法
- (void)monitorVideoPlayback
{
    double currentTime = floor(self.currentPlaybackTime);
    double totalTime = floor(self.duration);
    [self setTimeLabelValues:currentTime totalTime:totalTime];
    self.videoControl.progressSlider.value = ceil(currentTime);
}

//设置时间的
- (void)setTimeLabelValues:(double)currentTime totalTime:(double)totalTime {
    double minutesElapsed = floor(currentTime / 60.0);
    double secondsElapsed = fmod(currentTime, 60.0);
    NSString *timeElapsedString = [NSString stringWithFormat:@"%02.0f:%02.0f", minutesElapsed, secondsElapsed];
    
    double minutesRemaining = floor(totalTime / 60.0);;
    double secondsRemaining = floor(fmod(totalTime, 60.0));;
    NSString *timeRmainingString = [NSString stringWithFormat:@"%02.0f:%02.0f", minutesRemaining, secondsRemaining];
    
    self.videoControl.timeLabel.text = [NSString stringWithFormat:@"%@/%@",timeElapsedString,timeRmainingString];
}

//计时器
- (void)startDurationTimer
{
    self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(monitorVideoPlayback) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.durationTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopDurationTimer
{
    [self.durationTimer invalidate];
}

- (void)fadeDismissControl
{
    [self.videoControl animateHide];
}

//设备方向
-(void)deviceOrientationDidChange:(NSObject*)sender {
    UIDevice *device = [UIDevice currentDevice];
    switch (device.orientation) {
        case UIDeviceOrientationFaceUp:{
            NSLog(@"屏幕向上平躺");
            
        }
            break;
            
        case UIDeviceOrientationFaceDown:{
            NSLog(@"屏幕朝下平躺");
            
        }
            break;
        case UIDeviceOrientationLandscapeLeft:{
            NSLog(@"屏幕向左横置");
            if (self.isFullscreenMode) {
                return;
            }
            self.originFrame = self.view.frame;
            CGFloat height = [[UIScreen mainScreen] bounds].size.width;
            CGFloat width = [[UIScreen mainScreen] bounds].size.height;
            CGRect frame = CGRectMake((height - width) / 2, (width - height) / 2, width, height);;
            [UIView animateWithDuration:0.3f animations:^{
                self.frame = frame;
                [self.view setTransform:CGAffineTransformMakeRotation(M_PI_2)];
            } completion:^(BOOL finished) {
                self.isFullscreenMode = YES;
                self.videoControl.fullScreenButton.hidden = YES;
                self.videoControl.shrinkScreenButton.hidden = NO;
            }];
        }
            break;
            
        case UIDeviceOrientationLandscapeRight:{
            NSLog(@"屏幕向右横置");
            if (self.isFullscreenMode) {
                return;
            }
            self.originFrame = self.view.frame;
            CGFloat height = [[UIScreen mainScreen] bounds].size.width;
            CGFloat width = [[UIScreen mainScreen] bounds].size.height;
            CGRect frame = CGRectMake((height - width) / 2, (width - height) / 2, width, height);
            [UIView animateWithDuration:0.3f animations:^{
                self.frame = frame;
                [self.view setTransform:CGAffineTransformMakeRotation( - M_PI_2)];
            } completion:^(BOOL finished) {
                self.isFullscreenMode = YES;
                self.videoControl.fullScreenButton.hidden = YES;
                self.videoControl.shrinkScreenButton.hidden = NO;
            }];
            
        }
            break;
            
        case UIDeviceOrientationPortrait:
            NSLog(@"屏幕直立");
            [self shrinkScreenButtonClick];
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            NSLog(@"屏幕上下颠倒");
            [self shrinkScreenButtonClick];
            break;
            
        default:{
            NSLog(@"母鸡");
            
        }
            break;
    }
}




#pragma mark - Property

- (WWLJPlayerView *)videoControl
{
    if (!_videoControl) {
        _videoControl = [[WWLJPlayerView alloc] init];
    }
    return _videoControl;
}

- (UIView *)movieBackgroundView
{
    if (!_movieBackgroundView) {
        _movieBackgroundView = [UIView new];
        _movieBackgroundView.alpha = 0.0;
        _movieBackgroundView.backgroundColor = [UIColor blackColor];
    }
    return _movieBackgroundView;
}

- (void)setFrame:(CGRect)frame
{
    [self.view setFrame:frame];
    [self.videoControl setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self.videoControl setNeedsLayout];
    [self.videoControl layoutIfNeeded];
}


@end
