//
//  ViewController.h
//  CRAudioPlayer
//
//  Created by Chris on 2018/8/27.
//  Copyright © 2018年 Mars. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CRAudioQueuePlayer.h"

typedef enum {
    
    /* 準備 OK */
    CRAudio_Prepare = 0,
    /* 正在播放 */
    CRAudio_Playing = 1,
    /* 暫停 */
    CRAudio_Pause   = 2,
    /* 停止播放 */
    CRAudio_Stop    = 3,
    
} CRAudioPlayingStatus;

@interface ViewController : UIViewController<CRAudioDelegate>
{
    int playStatus; // 播放狀態.
}

@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (nonatomic, retain) NSTimer *timer; // 每秒更新 Slider 用 Timer.
@property (nonatomic, retain) CRAudioQueuePlayer *crAQPlayer;

- (IBAction)playPress:(id)sender;
- (IBAction)stopPress:(id)sender;

@end

