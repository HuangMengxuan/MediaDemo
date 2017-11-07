//
//  PlaybackViewController.m
//  AudioQueueDemo
//
//  Created by 黄梦轩 on 2017/11/6.
//  Copyright © 2017年 黄梦轩. All rights reserved.
//

@import AudioToolbox;
#import "PlaybackViewController.h"

static const int kNumberBuffers = 3; // 需要使用的缓冲区数量
static const int kMaxBufferSize = 0x50000; //缓冲区最大容量
static const int kMinBufferSize = 0x4000; //缓冲区最小容量

// 1
typedef struct AQPlaybackState {
    AudioStreamBasicDescription   mDataFormat;                    // 2
    AudioQueueRef                 mQueue;                         // 3
    AudioQueueBufferRef           mBuffers[kNumberBuffers];       // 4
    AudioFileID                   mAudioFile;                     // 5
    UInt32                        mBufferByteSize;                 // 6
    SInt64                        mCurrentPacket;                 // 7
    UInt32                        mNumPacketsToRead;              // 8
    AudioStreamPacketDescription  *mPacketDescs;                  // 9
    bool                          mIsRunning;                     // 10
} AQPlaybackState;

static void HandleOutputBuffer(void * __nullable inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    AQPlaybackState *playbackSattus = (AQPlaybackState *)inUserData;
    
    if (playbackSattus->mIsRunning == false) {
        return;
    }
    
    //numberByteReadFromFile需要传入有效的值
    UInt32 numberByteReadFromFile = playbackSattus->mBufferByteSize;
    
    UInt32 numPackets = playbackSattus->mNumPacketsToRead;
    
    OSStatus status = AudioFileReadPacketData(playbackSattus->mAudioFile, false, &numberByteReadFromFile, playbackSattus->mPacketDescs, playbackSattus->mCurrentPacket, &numPackets, inBuffer->mAudioData);
    if (status != noErr) {
        NSLog(@"failed while read audio data");
    }
    if (numPackets > 0) {
        inBuffer->mAudioDataByteSize = numberByteReadFromFile;
        AudioQueueEnqueueBuffer(playbackSattus->mQueue, inBuffer, playbackSattus->mPacketDescs ? numPackets : 0, playbackSattus->mPacketDescs);
        playbackSattus->mCurrentPacket += numPackets;
    } else {
        AudioQueueStop(playbackSattus->mQueue, false);
        playbackSattus->mIsRunning = false;
    }
    
}

@interface PlaybackViewController ()

@property (assign, nonatomic) AQPlaybackState mPlaybackState;
@property (copy, nonatomic) NSString *mFilePath;

@end

@implementation PlaybackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AQPlaybackState playbackState = {0};
    self.mPlaybackState = playbackState;
    
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    self.mFilePath = [docPath stringByAppendingPathComponent:@"test.wav"];
    
    self.mFilePath = [[NSBundle mainBundle] pathForResource:@"思念是一种病-张震岳" ofType:@"mp3"];
    self.mFilePath = [[NSBundle mainBundle] pathForResource:@"test1" ofType:@"wav"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _mPlaybackState.mIsRunning = true;
    [self openAudioFile];
    [self createAudioQueue];
    [self createAudioQueueBuffers];
}

- (void)openAudioFile {
    NSURL *filePathURL = [NSURL fileURLWithPath:self.mFilePath];
    OSStatus result = AudioFileOpenURL((__bridge CFURLRef _Nonnull)(filePathURL), kAudioFileReadPermission, 0, &_mPlaybackState.mAudioFile);
    if (result != noErr) {
        NSLog(@"failed while open audio file");
        return;
    }
    
    UInt32 propSize = sizeof(self.mPlaybackState.mDataFormat);
    result = AudioFileGetProperty(self.mPlaybackState.mAudioFile, kAudioFilePropertyDataFormat, &propSize, &_mPlaybackState.mDataFormat);
    if (result != noErr) {
        NSLog(@"failed while read asbd of audio file");
    }
}

- (void)createAudioQueue {
    OSStatus result = AudioQueueNewOutput(&_mPlaybackState.mDataFormat, HandleOutputBuffer, &_mPlaybackState, NULL, kCFRunLoopCommonModes, 0, &_mPlaybackState.mQueue);
    
    if (result != noErr) {
        NSLog(@"failed while create audio queue");
        return;
    }
    
    UInt32 maxPacketSize = 0;
    UInt32 propSize = sizeof(maxPacketSize);
    result = AudioFileGetProperty(self.mPlaybackState.mAudioFile, kAudioFilePropertyPacketSizeUpperBound, &propSize, &maxPacketSize);
    
    if (result != noErr) {
        NSLog(@"failed while read max packet size");
        
        // 1. WAV文件获取kAudioFilePropertyPacketSizeUpperBound属性失败
    }
    
    
    _mPlaybackState.mBufferByteSize = [self obtainBufferSizeWithAudioFormat:self.mPlaybackState.mDataFormat maxPacketSize:maxPacketSize seconds:0.5];
    _mPlaybackState.mCurrentPacket = 0;
    _mPlaybackState.mNumPacketsToRead = _mPlaybackState.mBufferByteSize / maxPacketSize;
    
    if (self.mPlaybackState.mDataFormat.mFramesPerPacket == 0 || self.mPlaybackState.mDataFormat.mBytesPerPacket == 0) {
        // VBR Format
        _mPlaybackState.mPacketDescs = malloc(self.mPlaybackState.mNumPacketsToRead * sizeof(AudioStreamPacketDescription));
    } else {
        _mPlaybackState.mPacketDescs = NULL;
    }
    
    [self configureMagicCookie];
}

- (UInt32)obtainBufferSizeWithAudioFormat:(AudioStreamBasicDescription)audioFormat maxPacketSize:(UInt32)maxPacketSize seconds:(NSTimeInterval)seconds{
    
    UInt32 bufferSize = 0;
    
    if (audioFormat.mFramesPerPacket == 0) {
        bufferSize = audioFormat.mSampleRate * seconds * maxPacketSize;
    } else {
        bufferSize = kMaxBufferSize > maxPacketSize ? kMaxBufferSize : maxPacketSize;
    }
    
    if (bufferSize > kMaxBufferSize && bufferSize > maxPacketSize) {
        bufferSize = kMaxBufferSize;
    } else {
        bufferSize = MIN(bufferSize, kMinBufferSize);
    }
    
    return bufferSize;
}

- (void)configureMagicCookie {
    UInt32  cookieSize = sizeof(UInt32);
    UInt32 writable = 0;
    OSStatus result = AudioFileGetPropertyInfo(self.mPlaybackState.mAudioFile, kAudioFilePropertyMagicCookieData, &cookieSize, &writable);
    
    // 1. mp3文件不支持kAudioFilePropertyMagicCookieData
    if (result == noErr && cookieSize > 0) {
        void *magicCookie = malloc(cookieSize);
        result = AudioFileGetProperty(self.mPlaybackState.mAudioFile, kAudioFilePropertyMagicCookieData, &cookieSize, magicCookie);
        if (result != noErr) {
            NSLog(@"failed while get magic cookie of audio file");
            return;
        }
        
        result = AudioQueueSetProperty(self.mPlaybackState.mQueue, kAudioQueueProperty_MagicCookie, magicCookie, cookieSize);
        if (result != noErr) {
            NSLog(@"failed while set magic cookie to audio queue");
            return;
        }
        
        free(magicCookie);
    }
}

- (void)createAudioQueueBuffers {
    for (NSInteger i = 0; i < kNumberBuffers; i ++) {
        AudioQueueAllocateBuffer(self.mPlaybackState.mQueue, self.mPlaybackState.mBufferByteSize, &_mPlaybackState.mBuffers[i]);
        
        HandleOutputBuffer(&_mPlaybackState, self.mPlaybackState.mQueue, self.mPlaybackState.mBuffers[i]);
    }
}

- (void)configureAudioQueueVolume:(Float32)volume {
    OSStatus result = AudioQueueSetParameter(self.mPlaybackState.mQueue, kAudioQueueParam_Volume, volume);
    if (result != noErr) {
        NSLog(@"failed while set volume for audio queue");
    }
}

- (void)startPlayback {
    OSStatus result = AudioQueueStart(self.mPlaybackState.mQueue, NULL);
    if (result != noErr) {
        NSLog(@"failed while start playback");
    }
}

- (void)stopPlayback {
    OSStatus result = AudioQueueStop(self.mPlaybackState.mQueue, false);
    if (result != noErr) {
        NSLog(@"failed while stop playback");
    }
}

#pragma mark -- Button Action

- (IBAction)playButtonAction:(id)sender {
    [self startPlayback];
}

- (IBAction)stopButtonAction:(id)sender {
    [self stopPlayback];
}


@end
