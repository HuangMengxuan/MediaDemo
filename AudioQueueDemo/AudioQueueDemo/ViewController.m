//
//  ViewController.m
//  AudioQueueDemo
//
//  Created by 黄梦轩 on 2017/11/2.
//  Copyright © 2017年 黄梦轩. All rights reserved.
//

@import AudioToolbox;
#import "ViewController.h"

static const int kNumberBuffers = 3; // 需要使用的缓冲区数量
static const int kMaxBufferSize = 0x50000; //缓冲区最大容量

typedef struct AQRecorderState {
    AudioStreamBasicDescription mDataFormat; // 写入音频文件的音频数据的格式
    AudioQueueRef mQueue;  // 音频队列
    AudioQueueBufferRef mBuffers[kNumberBuffers]; // 音频队列缓冲区数组
    AudioFileID mAudioFile;  // 保存音频数据的音频文件
    UInt32 mBufferBytesSize;  // 每个音频队列缓冲区存放音频数据的字节数
    SInt64 mCurrentPacket;   // 当前音频数据Packet的索引
    bool mIsRunning;         // 音频队列是否在运行
} AQRecorderState;

static void HandleInputBuffer (
                               void * __nullable               inUserData,
                               AudioQueueRef                   inAQ,
                               AudioQueueBufferRef             inBuffer,
                               const AudioTimeStamp *          inStartTime,
                               UInt32                          inNumberPackets,
                               const AudioStreamPacketDescription * __nullable inPacketDescs) {
    AQRecorderState *recorderStatus = inUserData; // 获取自定义结构体
    
    // 对于VBR数据，回调函数提供inNumberPackets
    // 对于CBR数据，回调函数提供inNumberPackets为0，需要自己计算。inNumberPackets = 数据总长度 / 每个Packet的数据的长度
    if (inNumberPackets == 0 && recorderStatus->mDataFormat.mBytesPerPacket != 0) {
        inNumberPackets = inBuffer->mAudioDataByteSize / recorderStatus->mDataFormat.mBytesPerPacket;
    }
    
    // 将音频数据写入音频文件
    OSStatus status = AudioFileWritePackets(recorderStatus->mAudioFile, false, inBuffer->mAudioDataByteSize, inPacketDescs, recorderStatus->mCurrentPacket, &inNumberPackets, inBuffer->mAudioData);
    
    // 如果音频文件写入成功，增加当前音频数据Packet的索引
    if (status == noErr) {
        recorderStatus->mCurrentPacket += inNumberPackets;
        
        NSLog(@"recorderStatus->mCurrentPacket = %lld", recorderStatus->mCurrentPacket);
    } else {
        NSLog(@"failed while write data to file");
    }
    
    // 如果音频队列已经停止运行则return
    if (recorderStatus->mIsRunning == false) {
        return;
    }
    
    // 将数据已经被写入音频文件的缓冲区加入音频队列
    AudioQueueEnqueueBuffer(recorderStatus->mQueue, inBuffer, 0, NULL);
}


/**
 从音频队列获取魔法饼干数据并为音频文件设置魔法饼干

 @param inQueue 录音的音频队列
 @param inFile 音频文件
 @return 成功则返回noErr
 */
OSStatus setMagicCookieForFile (AudioQueueRef inQueue, AudioFileID inFile) {
    OSStatus result = noErr;
    
    // 从音频队列获取魔法饼干的数据大小
    UInt32 cookieSize;
    result = AudioQueueGetPropertySize(inQueue, kAudioQueueProperty_MagicCookie, &cookieSize);
    if (result != noErr || cookieSize <= 0) {
        return result;
    }
    
    // 从音频队列获取魔法饼干的数据
    void *magicCookie = malloc(cookieSize);
    result = AudioQueueGetProperty(inQueue, kAudioQueueProperty_MagicCookie, magicCookie, &cookieSize);
    if (result != noErr) {
        free(magicCookie);
        return noErr;
    }
    
    // 设置魔法饼干到音频文件
    result = AudioFileSetProperty(inFile, kAudioFilePropertyMagicCookieData, cookieSize, magicCookie);
    free(magicCookie);
    
    return result;
}


/* 使用音频队列录音的步骤：
 1. 创建一个自定义结构体来管理状态、格式等信息
 2. 实现一个音频队列回调函数来执行实际录音
 3. 定义音频队列缓冲区的大小；如果录制需要使用魔法饼干的音频格式，则需要编写代码使用MagicCookie
 4. 填写自定义结构体的字段
 5. 创建一个音频队列，并创建一组音频队列缓冲区，同时还需要创建一个存放音频数据的音频文件
 6. 开始录音
 7. 完成后，停止录音。释放音频队列，音频队列会自动释放它的缓冲区
 
 */
@interface ViewController ()

@property (assign, nonatomic) AQRecorderState mRecorderState;
@property (copy, nonatomic) NSString *mFilePath;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AQRecorderState recorderStatus = {0};
    
    recorderStatus.mDataFormat.mFormatID = kAudioFormatLinearPCM;
    recorderStatus.mDataFormat.mBitsPerChannel = 16;
    recorderStatus.mDataFormat.mChannelsPerFrame = 2;
    recorderStatus.mDataFormat.mBytesPerFrame = recorderStatus.mDataFormat.mChannelsPerFrame * sizeof(SInt16);
    recorderStatus.mDataFormat.mFramesPerPacket = 1;
    recorderStatus.mDataFormat.mBytesPerPacket = recorderStatus.mDataFormat.mBytesPerFrame * recorderStatus.mDataFormat.mFramesPerPacket;
    recorderStatus.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger;
    recorderStatus.mDataFormat.mSampleRate = 44100.0f;
    
    self.mRecorderState = recorderStatus;
    
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    self.mFilePath = [docPath stringByAppendingPathComponent:@"test.wav"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self createAudioFile];
    [self createAudioQueue];
    _mRecorderState.mBufferBytesSize = [self obtainBufferSizeWithAudioQueue:self.mRecorderState.mQueue audioFromat:self.mRecorderState.mDataFormat seconds:2];
    [self createAudioQueueBuffers];
    setMagicCookieForFile(self.mRecorderState.mQueue, self.mRecorderState.mAudioFile);
}

- (void)createAudioQueue {
    OSStatus status = AudioQueueNewInput(&_mRecorderState.mDataFormat, HandleInputBuffer, &_mRecorderState, NULL, kCFRunLoopCommonModes, 0, &_mRecorderState.mQueue);
    
    if (status != noErr) {
        return;
    }
    
    UInt32 dataFormatSize = sizeof(self.mRecorderState.mDataFormat);
    AudioQueueGetProperty(self.mRecorderState.mQueue, kAudioQueueProperty_StreamDescription, &_mRecorderState.mDataFormat, &dataFormatSize);
}

- (void)createAudioFile {
    NSURL *filePathURL = [NSURL fileURLWithPath:self.mFilePath];
    OSStatus result = AudioFileCreateWithURL((__bridge CFURLRef)(filePathURL), kAudioFileWAVEType, &_mRecorderState.mDataFormat, kAudioFileFlags_EraseFile, &_mRecorderState.mAudioFile);
    if (result != noErr) {
        NSLog(@"failed while create audio file");
        
        // 1. 文件创建失败:kAudioFileUnsupportedDataFormatError
        // 如果文件格式是kAudioFileWAVEType，recorderStatus.mDataFormat.mFormatFlags必须是小端存储的
        // 如果recorderStatus.mDataFormat.mChannelsPerFrame大于2，会当做1个声道的来处理
        // 如果文件格式是kAudioFileAIFFType，recorderStatus.mDataFormat.mFormatFlags必须是大端存储的
    }
}

- (void)createAudioQueueBuffers {
    for (NSInteger i = 0; i < kNumberBuffers; i ++) {
        AudioQueueAllocateBuffer(self.mRecorderState.mQueue, self.mRecorderState.mBufferBytesSize, &_mRecorderState.mBuffers[i]);
        
        AudioQueueEnqueueBuffer(self.mRecorderState.mQueue, self.mRecorderState.mBuffers[i], 0, NULL);
    }
}

- (UInt32)obtainBufferSizeWithAudioQueue:(AudioQueueRef)audioQueue audioFromat:(AudioStreamBasicDescription)audioFormat seconds:(NSTimeInterval)seconds  {
    
    int maxPacketSize = audioFormat.mBytesPerPacket;
    if (maxPacketSize == 0) {
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        
        AudioQueueGetProperty(audioQueue, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize, &maxVBRPacketSize);
    }
    
    Float64 numberBytesForTime = audioFormat.mSampleRate * seconds * maxPacketSize  ;
    
    UInt32 bufferSize = MIN(kMaxBufferSize, numberBytesForTime);
    return bufferSize;
}

- (void)startRecord {
    _mRecorderState.mIsRunning = true;
    _mRecorderState.mCurrentPacket = 0;
    
    AudioQueueStart(self.mRecorderState.mQueue, NULL);
}

- (void)stopRecord {
    AudioQueueStop(self.mRecorderState.mQueue, true);
    _mRecorderState.mIsRunning = false;
}

- (void)finishRecord {
    AudioQueueDispose(self.mRecorderState.mQueue, true);
    AudioFileClose(self.mRecorderState.mAudioFile);
}

#pragma mark -- Button Action
- (IBAction)startButtonAction:(id)sender {
    NSLog(@"============== startRecord =================");
    [self startRecord];
}

- (IBAction)stopButtonAction:(id)sender {
    NSLog(@"============== stopRecord =================");
    [self stopRecord];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
