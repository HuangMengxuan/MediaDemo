//
//  PlaybackViewController.m
//  AudioQueueDemo
//
//  Created by 黄梦轩 on 2017/11/6.
//  Copyright © 2017年 黄梦轩. All rights reserved.
//

@import AudioToolbox;
#import "PlaybackViewController.h"

static const int kNumberBuffers = 3;                              // 1
typedef struct AQPlaybackState {
    AudioStreamBasicDescription   mDataFormat;                    // 2
    AudioQueueRef                 mQueue;                         // 3
    AudioQueueBufferRef           mBuffers[kNumberBuffers];       // 4
    AudioFileID                   mAudioFile;                     // 5
    UInt32                        bufferByteSize;                 // 6
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
    
    UInt32 numberByteReadFromFile = 0;
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
    // Do any additional setup after loading the view.
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
    OSStatus status = AudioQueueNewInput(&_mPlaybackState.mDataFormat, HandleOutputBuffer, &_mPlaybackState, NULL, kCFRunLoopCommonModes, 0, &_mPlaybackState.mQueue);
    
    if (status != noErr) {
        NSLog(@"failed while create audio queue");
        return;
    }
}

#pragma mark -- Button Action

- (IBAction)playButtonAction:(id)sender {
}

- (IBAction)stopButtonAction:(id)sender {
}


@end
