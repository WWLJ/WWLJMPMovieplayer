//
//  ViewController.m
//  WWLJMPMovieplayer
//
//  Created by 武文杰 on 15/7/13.
//  Copyright (c) 2015年 武文杰. All rights reserved.
//

#import "ViewController.h"
#import "WWLJMPMoviePlayer.h"

@interface ViewController ()

@property (nonatomic, strong) WWLJMPMoviePlayer *videoController;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self playVideoWithURL:[self getNetworkUrl]];
}

-(NSURL *)getNetworkUrl{
//    NSString *urlStr = nil;
    
//    urlStr=[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *urlStr=@"http://221.229.164.133:80/play/63459C0B93BFB60816E70F5B0571C1EBF90D4A30.mp4";
    NSURL *url=[NSURL URLWithString:urlStr];
    return url;
}

- (void)playVideoWithURL:(NSURL *)url
{
    if (!self.videoController) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        self.videoController = [[WWLJMPMoviePlayer alloc] initWithFrame:CGRectMake(0, 0, width, width * (9.0/16.0))];
        [self.view addSubview:self.videoController.view];
    }
    self.videoController.contentURL = url;
}

@end
