//
//  CRAudioQueuePlayer.m
//
//  PCM raw data player.
//
//  Created by Chris on 2018/7/23.
//  Copyright © 2018年 Mars. All rights reserved.
//

#import "CRAudioQueuePlayer.h"

#define MIN_SIZE_PER_FRAME 7336056 // 每個包的大小.
#define QUEUE_BUFFER_SIZE 3 // 列隊數.

@interface CRAudioQueuePlayer()
{
    AudioQueueRef audioQueue;                                 // 音頻播放列隊.
    AudioStreamBasicDescription _audioDescription;            // 音頻詳細格式.
    AudioQueueBufferRef audioQueueBuffers[QUEUE_BUFFER_SIZE]; // 音頻緩存.
    BOOL audioQueueBufferUsed[QUEUE_BUFFER_SIZE];             // 判斷音頻緩存是否在使用.
    NSLock *sysnLock;                                         // 同步鎖.
    NSMutableData *tempData;                                  // 播放數據.
    OSStatus osState;                                         // 播放器狀態.
}

@end

@implementation CRAudioQueuePlayer

+ (void)initialize
{
    NSError *error = nil;
    
    // 若只想要播放, 請設置為 : AVAudioSessionCategoryPlayback.
    // 若只想要錄音, 請設置為 : AVAudioSessionCategoryRecord.
    // 若兩者皆想要, 請設置為 : AVAudioSessionCategoryMultiRoute.

    BOOL ret = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (!ret) {
        NSLog(@"### CRAudioQueuePlayer -> + Initialize : 設置聲音環境失敗! ###");
        return;
    }

    // 啟用 Audio Session.
    ret = [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (!ret)
    {
        NSLog(@"### CRAudioQueuePlayer -> + Initialize : 啟動 AudioSession Fail! ###");
        return;
    }
}

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
                      Delegate:(id<CRAudioDelegate>)delegate
{
    if (self = [super init])
    {
        _sampleRate = sampleRate;
        _channels = channels;
        _bitsPerChannel = bitsPerChannel;
        _volume = volume;
        _delegate = delegate;
    
        [self resetSetting]; // 實際執行設置 AudioQueueService Parameters.
    }
    return self;
}

// 實際初始化相關參數.
- (void)resetSetting
{
    [self stopWithInImmediat:YES]; // 確保安全先停止一次 Player.
    
    sysnLock = [[NSLock alloc]init];
    
    // 設置音頻參數.
    if (_audioDescription.mSampleRate <= 0) {

        // 採樣率.
        _audioDescription.mSampleRate = _sampleRate;

        // 音頻數據格式.
        _audioDescription.mFormatID = kAudioFormatLinearPCM;

        // 音頻尾部字節序.
        _audioDescription.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;

        // 音頻通道數.
        _audioDescription.mChannelsPerFrame = _channels;

        // 音頻數據包中的幀數, 對於未壓縮的音頻，值為1.對於可變比特率格式，該值是較大的固定數，例如對於 AAC 為 1024.
        _audioDescription.mFramesPerPacket = 1;

        // 一個音頻樣本的位數, 例如對於使用格式標誌的線性 PCM 音頻, 請參考 : mBitsPerChannel = 8 * sizeof (AudioSampleType); , 若設為 0 則代表為壓縮格式.
        _audioDescription.mBitsPerChannel = _bitsPerChannel;

        // 從音頻緩衝區中的一幀開始到下一幀開始的字節數。若設為 0 則代表為壓縮格式.
        _audioDescription.mBytesPerFrame = (_audioDescription.mBitsPerChannel / 8) * _audioDescription.mChannelsPerFrame;

        // 音頻數據包中的字節數。要指示可變數據包大小，請將此字段設置為 0, 對於使用可變數據包大小的格式，請使用結構指定每個數據包的大小.
        _audioDescription.mBytesPerPacket = _audioDescription.mBytesPerFrame * _audioDescription.mFramesPerPacket;

        // 將結構填充以強制進行均勻的 8 字節對齊。必須設置為 0.
        _audioDescription.mReserved = 0;

    }


    // 使用 Player 的內部線程播放 新建輸出.
    osState = AudioQueueNewOutput(&_audioDescription, AudioPlayerAQInputCallback, (__bridge void * _Nullable)(self), NULL, NULL, 0, &audioQueue);
    
    if (osState != noErr) {
        NSLog(@"### CRAudioQueuePlayer -> AudioQueueNewOutput is Fail! ###");
    }
    
    // 設置音量.
    osState = AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, _volume);
    
    if (osState != noErr) {
        NSLog(@"### CRAudioQueuePlayer -> AudioQueueSetParameter is Fail! ###");
    }
    
    
    // 初始化需要的緩衝區.
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {

        audioQueueBufferUsed[i] = NO; // 將所有 BufferUsed Flag 皆設為未使用狀態.
        
        int result = AudioQueueAllocateBuffer(audioQueue, MIN_SIZE_PER_FRAME, &audioQueueBuffers[i]);

        NSLog(@"### CRAudioQueuePlayer -> 第 %d 个 AudioQueueAllocateBuffer 初始化结果 %d (0表示成功)", i, result);

    }
}

/**
 播放數據流數據.
 *
 *@param data     -> 音頻數據來源.
 *
 */
- (void)playWithData:(NSData *)data
{
    if (audioQueue == nil || ![self checkBufferHasUsed]) {
        [self resetSetting];
        AudioQueueStart(audioQueue, NULL);
    }
    
    [sysnLock lock]; // 上鎖.
    
    UInt32 length = (UInt32)data.length;
    
    AudioQueueBufferRef audioQueueBuffer = NULL;
    
    // 取出音頻緩存數據.
    while (true) {
        audioQueueBuffer = [self getNotUsedBuffer];
        if (audioQueueBuffer != NULL) {
            break;
        }
    }
    
    // 將數據填充到緩存數組中並加入列隊內.
    audioQueueBuffer->mAudioDataByteSize = length; // 音頻數據長度.
    Byte *audioData = audioQueueBuffer->mAudioData; // 將數據指針指向填充的數據.
    memcpy(audioData, [data bytes], length); // 將 audioData 賦值即是給 audioQueueBuffer 賦值.
    AudioQueueEnqueueBuffer(audioQueue, audioQueueBuffer, 0, NULL); // 將 Buffer 加入 audioQueue, 系統自動播放.
    
    [sysnLock unlock]; // 解鎖.
}

- (BOOL)checkBufferHasUsed
{
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        if (YES == audioQueueBufferUsed[i]) {
            return YES;
        }
    }
    return NO;
}

- (AudioQueueBufferRef)getNotUsedBuffer
{
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        if (NO == audioQueueBufferUsed[i]) {
            audioQueueBufferUsed[i] = YES;
            return audioQueueBuffers[i];
        }
    }
    return NULL;
}

/**
 暫停播放器.
 *
 *@param status  -> 是否暫停 or 恢復播放 (YES: 暫停, NO: 恢復播放).
 *
 */
- (void)pauseWithStatus:(BOOL)status
{
    if (audioQueue != nil && status)
    {
        AudioQueuePause(audioQueue);
    }
    else if (audioQueue != nil && !status)
    {
        AudioQueueStart(audioQueue, NULL);
    }
}


/**
 停止播放器.
 *
 *@param inImmediate  -> 是否立即停止播放 (YES: 立即, NO: 播放完 Buffer 後停止).
 *
 */
- (void)stopWithInImmediat:(BOOL)inImmediate
{
    if(audioQueue != nil) {
        AudioQueueStop(audioQueue, inImmediate);
    }
    
    audioQueue = nil;
    sysnLock = nil;
}

// 重置播放器.
- (void)resetPlayer
{
    if (audioQueue != nil) {
        AudioQueueReset(audioQueue);
    }
}

// 取得總播放時長.
- (Float64)getTotalTime
{
    if (audioQueue != nil)
    {
        return (Float64) (MIN_SIZE_PER_FRAME * 8) / (_audioDescription.mSampleRate * _audioDescription.mBitsPerChannel);
    }
    
    return -1;
}

// 取得當前播放時長.
- (Float64)getCurrentTimeStamp
{
    if (audioQueue != nil)
    {
        AudioTimeStamp timeStamp;
        
        AudioQueueGetCurrentTime(audioQueue, NULL, &timeStamp, NULL);
        
        return timeStamp.mSampleTime / _audioDescription.mSampleRate;
    }
    
    return -1;
}

// ************************** 回調 **********************************

/**
 播放完 Buffer 的回調, 把 Buffer 狀態設為未使用.
 *
 *@param inUserData          -> UserData.
 *@param audioQueueRef       -> 當前播放列隊.
 *@param audioQueueBufferRef -> 已經使用過的 Buffer.
 *
 */
static void AudioPlayerAQInputCallback(void* inUserData, AudioQueueRef audioQueueRef, AudioQueueBufferRef audioQueueBufferRef)
{
    CRAudioQueuePlayer* player = (__bridge CRAudioQueuePlayer*)inUserData;
    [player resetBufferState:audioQueueBufferRef];
}

- (void)resetBufferState:(AudioQueueBufferRef)audioQueueBufferRef
{
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        // 將被播放完畢的 Buffer 設為未使用.
        if (audioQueueBufferRef == audioQueueBuffers[i]) {
            audioQueueBufferUsed[i] = NO;
        }
    }
    
    // 播放完 Buffer 後, 呼叫 Delegate Method, 讓使用 CRAudio 介面得知目前播放當前 Buffer.
    if (_delegate) [_delegate didCRAudioPlayEnd];
}

@end

