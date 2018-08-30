//
//  ViewController.m
//  CRAudioPlayer
//
//  Created by Chris on 2018/8/27.
//  Copyright © 2018年 Mars. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize slider;
@synthesize timer;
@synthesize crAQPlayer;

#pragma mark - View Life cycle.
- (void)viewDidLoad
{
    [super viewDidLoad];
    // 預設 Status 為 Prepare.
    playStatus = 0;
    // 先將 Slider 設為 0.
    [self.slider setValue:0];
    // 初始化 CRAudioPlayer.
    crAQPlayer = [[CRAudioQueuePlayer alloc] initSampleRate:16000 ChannelsNumber:1 BitsPerChannel:16 Volume:1.0 Delegate:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // 設置兩個 Button Image.
    [self.playButton setImage:[UIImage imageNamed:@"PlayBtn"] forState:UIControlStateNormal];
    [self.playButton setImage:[UIImage imageNamed:@"PlayBtnPress"] forState:UIControlStateSelected];
    [self.stopButton setImage:[UIImage imageNamed:@"StopBtn"] forState:UIControlStateNormal];
    [self.stopButton setImage:[UIImage imageNamed:@"StopBtnPress"] forState:UIControlStateSelected];
    // 將 Slider 最大值設為 AudioData 總長度.
    Float64 totalTime = [crAQPlayer getTotalTime];
    [self.slider setMaximumValue:totalTime];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - IBAction Method.
- (IBAction)playPress:(id)sender
{
    switch (playStatus)
    {
        case CRAudio_Prepare: // 此狀態下按下就會播放.
            
            playStatus = CRAudio_Playing;
            [self play];
            [self.playButton setImage:[UIImage imageNamed:@"PauseBtn"] forState: UIControlStateNormal];
            [self.playButton setImage:[UIImage imageNamed:@"PauseBtnPress"] forState: UIControlStateSelected];
            // 運行 Timer 讓每一秒 Slider 根據播放時間更新.
            if (self.timer == nil) {
                self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(startUpdateTimeStamp) userInfo:nil repeats:YES];
            }
            
            break;
            
        case CRAudio_Playing: // 此狀態下按下會變成暫停.
            
            playStatus = CRAudio_Pause;
            [self pause];
            [self.playButton setImage:[UIImage imageNamed:@"PlayBtn"] forState:UIControlStateNormal];
            [self.playButton setImage:[UIImage imageNamed:@"PlayBtnPress"] forState:UIControlStateSelected];
            
            break;
            
        case CRAudio_Pause: // 此狀態下按下會從暫停中恢復播放.
            
            playStatus = CRAudio_Playing;
            [self pause];
            [self.playButton setImage:[UIImage imageNamed:@"PauseBtn"] forState:UIControlStateNormal];
            [self.playButton setImage:[UIImage imageNamed:@"PauseBtnPress"] forState:UIControlStateSelected];
            
            break;
            
        default:
            break;
    }
}

- (IBAction)stopPress:(id)sender
{
    playStatus = CRAudio_Prepare;
    [self stop];
    
    [self.playButton setImage:[UIImage imageNamed:@"PlayBtn"] forState:UIControlStateNormal];
    [self.playButton setImage:[UIImage imageNamed:@"PlayBtnPress"] forState:UIControlStateSelected];
}


#pragma mark - Customer Setting CRAudio Methods.
- (void)play
{
    // 播放本地檔案.
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"mm" withExtension:@"pcm"];
    NSData *audioData = [NSData dataWithContentsOfURL:url];
    
    [crAQPlayer playWithData:audioData];
}

- (void)pause
{
    if (playStatus == CRAudio_Pause)
    {
        [crAQPlayer pauseWithStatus:YES];
    }
    else
    {
        [crAQPlayer pauseWithStatus:NO];
    }
}

- (void)stop
{
    playStatus = CRAudio_Prepare;
    [self stopUpdateTimeStamp];
    [crAQPlayer stopWithInImmediat:YES];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.playButton setImage:[UIImage imageNamed:@"PlayBtn"] forState:UIControlStateNormal];
        [self.playButton setImage:[UIImage imageNamed:@"PlayBtnPress"] forState:UIControlStateSelected];
        [self.slider setValue:0];
    });
}

- (void)startUpdateTimeStamp
{
    Float64 timeStamp = [self.crAQPlayer getCurrentTimeStamp];
    [self.slider setValue:timeStamp];
}

- (void)stopUpdateTimeStamp
{
    if (timer != nil && [timer isValid])
    {
        [timer invalidate];
        timer = nil;
    }
}


#pragma mark - CRAudioDelegate Methods.
- (void)didCRAudioPlayEnd
{
    [self stop];
}


@end

