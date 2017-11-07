//
//  HMXAudioFileStream.m
//  AudioFileStreamDemo
//
//  Created by lsyy on 2017/11/4.
//  Copyright © 2017年 sonirock. All rights reserved.
//

#import "HMXAudioFileStream.h"

@interface HMXAudioFileStream ()

@property (assign, nonatomic) AudioFileStreamID mAudioFileStreamID;
@property (assign, nonatomic) BOOL mDiscontinuity;

@property (assign, nonatomic, readwrite) AudioFileTypeID fileTypeID;
@property (assign, nonatomic, readwrite) BOOL available;
@property (assign, nonatomic, readwrite) BOOL readyToProducePackets;
@property (assign, nonatomic, readwrite) AudioStreamBasicDescription audioDataFormat;
@property (assign, nonatomic, readwrite) UInt64 audioDataByteCount;
@property (assign, nonatomic, readwrite) UInt64 audioDataPacketCount;
@property (assign, nonatomic, readwrite) SInt64 audioDataOffset;
@property (assign, nonatomic, readwrite) UInt32 bitRate;
@property (assign, nonatomic, readwrite) NSTimeInterval duration;
@property (copy, nonatomic, readwrite) NSData *magicData;

- (void)handleAudioProperty:(AudioFileStreamPropertyID)propertyID;
- (void)handleAudioFileStreamPackets:(const void *)packetsData packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions numberBytes:(UInt32)numberBytes numberPackets:(UInt32)numberPackets;

@end

static void HMXAudioPropertyListener(void *inClientData, AudioFileStreamID inAudioFileStream, AudioFileStreamPropertyID inPropertyID, AudioFileStreamPropertyFlags *ioFlags) {
    HMXAudioFileStream *audioFileStream = (__bridge HMXAudioFileStream *)(inClientData);
    [audioFileStream handleAudioProperty:inPropertyID];
}

static void HMXAudioFileStreamPacketsCallback(void *inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets, const void *inInputData, AudioStreamPacketDescription *inPacketDescriptions) {
    HMXAudioFileStream *audioFileStream = (__bridge HMXAudioFileStream *)(inClientData);
    [audioFileStream handleAudioFileStreamPackets:inInputData packetDescriptions:inPacketDescriptions numberBytes:inNumberBytes numberPackets:inNumberPackets];
}

@implementation HMXAudioFileStream

- (instancetype)initWithFileTypeID:(AudioFileTypeID)fileTypeID {
    if (self = [super init]) {
        _fileTypeID = fileTypeID;
        [self openAudioFileStream];
    }
    return self;
}

- (BOOL)openAudioFileStream {
    OSStatus status = AudioFileStreamOpen((__bridge void * _Nullable)(self), HMXAudioPropertyListener, HMXAudioFileStreamPacketsCallback, self.fileTypeID, &(_mAudioFileStreamID));
    
    if (status != noErr) {
        self.mAudioFileStreamID = NULL;
    }
    return status == noErr;
}

- (void)closeAudioFileStream {
    if (self.available) {
        AudioFileStreamClose(self.mAudioFileStreamID);
        self.mAudioFileStreamID = NULL;
    }
}

#pragma mark -- Public Method
- (BOOL)parseAudioData:(void *)audioData dataSize:(UInt32)dataSize {
    OSStatus status = AudioFileStreamParseBytes(self.mAudioFileStreamID, dataSize, audioData, self.mDiscontinuity ? kAudioFileStreamParseFlag_Discontinuity : 0);
    return status == noErr;
}

- (void)seekToTime:(NSTimeInterval)time {
    
}

#pragma mark -- Callback
- (void)handleAudioProperty:(AudioFileStreamPropertyID)propertyID {
    if (propertyID == kAudioFileStreamProperty_ReadyToProducePackets) {
        self.readyToProducePackets = YES;
        self.mDiscontinuity = YES;
        
        // 获取音频数据格式
        UInt32 propSize = sizeof(self.audioDataFormat);
        AudioFileStreamGetProperty(self.mAudioFileStreamID, kAudioFileStreamProperty_DataFormat, &propSize, &_audioDataFormat);
        
        // 获取音频数据字节数
        propSize = sizeof(self.audioDataByteCount);
        AudioFileStreamGetProperty(self.mAudioFileStreamID, kAudioFileStreamProperty_AudioDataByteCount, &propSize, &_audioDataByteCount);
        
        // 获取音频帧数
        propSize = sizeof(self.audioDataPacketCount);
        AudioFileStreamGetProperty(self.mAudioFileStreamID, kAudioFileStreamProperty_AudioDataPacketCount, &propSize, &_audioDataPacketCount);
        
        // 获取采样率
        propSize = sizeof(self.bitRate);
        AudioFileStreamGetProperty(self.mAudioFileStreamID, kAudioFileStreamProperty_BitRate, &propSize, &_bitRate);
        
        // 获取音频数据偏移量
        propSize = sizeof(self.audioDataOffset);
        AudioFileStreamGetProperty(self.mAudioFileStreamID, kAudioFileStreamProperty_DataOffset, &propSize, &_audioDataOffset);
        
        // 获取MagicCookie
        propSize = 0;
        Boolean writable = false;
        OSStatus status = AudioFileStreamGetPropertyInfo(self.mAudioFileStreamID, kAudioFileStreamProperty_MagicCookieData, &propSize, &writable);
        if (status == noErr) {
            void *magicCookieData = malloc(propSize);
            status = AudioFileStreamGetProperty(self.mAudioFileStreamID, kAudioFileStreamProperty_MagicCookieData, &propSize, magicCookieData);
            if (status == noErr) {
                self.magicData = [NSData dataWithBytes:magicCookieData length:propSize];
            }
        }
        
    }
}

- (void)handleAudioFileStreamPackets:(const void *)packetsData packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions numberBytes:(UInt32)numberBytes numberPackets:(UInt32)numberPackets {
    
}

#pragma mark -- Getter/Setter
- (BOOL)available {
    return self.mAudioFileStreamID != NULL;
}

@end
