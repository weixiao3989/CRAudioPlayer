//
//  CRAudioQueuePlayer.h
//
//  PCM raw data player.
//
//  Created by Chris on 2018/7/23.
//  Copyright © 2018年 Mars. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@protocol CRAudioDelegate;

@interface CRAudioQueuePlayer : NSObject

// 採樣率.
@property(nonatomic, assign) Float64 sampleRate;
// 聲道數.
@property(nonatomic, assign) UInt32 channels;
// 樣本位數.
@property(nonatomic, assign) UInt32 bitsPerChannel;
// 音量.
@property(nonatomic, assign) CGFloat volume;
// CallBack Delegate.
@property(nonatomic, assign) id<CRAudioDelegate> delegate;


/**
 初始化播放器.
 *
 *@param sampleRate     -> 聲音採樣率.
 *@param channels       -> 音頻聲道數 (1: 單聲道, 2: 雙聲道).
 *@param bitsPerChannel -> 每個採樣點的樣本位數, 一般為 8 or 16.
 *@param volume         -> 音量.
 *@param delegate       -> 設定代理.
 *
 */
- (instancetype)initSampleRate:(Float64)sampleRate
                ChannelsNumber:(UInt32)channels
                BitsPerChannel:(UInt32)bitsPerChannel
                        Volume:(CGFloat)volume
                      Delegate:(id<CRAudioDelegate>)delegate;

/**
 播放數據流數據.
 *
 *@param data     -> 音頻數據來源.
 *
 */
- (void)playWithData:(NSData *)data;

/**
 暫停播放器.
 *
 *@param status  -> 是否暫停 or 恢復播放 (YES: 暫停, NO: 恢復播放).
 *
 */
- (void)pauseWithStatus:(BOOL)status;

/**
 停止播放器.
 *
 *@param inImmediate  -> 是否立即停止播放 (YES: 立即, NO: 播放完 Buffer 後停止).
 *
 */
- (void)stopWithInImmediat:(BOOL)inImmediate;

// 重置播放器.
- (void)resetPlayer;

// 取得總播放時長.
- (Float64)getTotalTime;

// 取得當前播放時長.
- (Float64)getCurrentTimeStamp;

@end

// 設置代理事件, 讓使用此 Audio 的頁面可以透過代理事件知道播放完畢等狀態.
@protocol CRAudioDelegate

- (void)didCRAudioPlayEnd;

@end

