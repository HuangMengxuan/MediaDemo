//
//  HMXAudioFileStreamReader.m
//  AudioConverterTest
//
//  Created by lsyy on 2017/11/13.
//  Copyright © 2017年 sonirock. All rights reserved.
//

#import "HMXAudioFileStreamReader.h"

static const NSInteger kAudioDataBytesPerRead = 0x5000; // 每次读取的音频文件Byte数

@interface HMXAudioFileStreamReader ()

@property (strong, nonatomic) NSFileHandle *mFileHandle;

@property (assign, nonatomic) AudioFileStreamID mAudioFileStreamID;
@property (assign, nonatomic) BOOL mDiscontinuity;
@property (assign, nonatomic, readwrite) BOOL available;

@property (strong, nonatomic) dispatch_queue_t mAudioReadQueue;
@property (assign, nonatomic) BOOL fileFinished;

@property (assign, nonatomic) UInt64 audioDataPacketCount;
@property (assign, nonatomic) UInt64 audioDataByteCount;
@property (assign, nonatomic) UInt32 bitRate;
@property (assign, nonatomic) SInt64 audioDataOffset;


- (void)handleAudioProperty:(AudioFileStreamPropertyID)propertyID;
- (void)handleAudioFileStreamPackets:(const void *)packetsData packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions numberBytes:(UInt32)numberBytes numberPackets:(UInt32)numberPackets;

@end

static void HMXAudioPropertyListener(void *inClientData, AudioFileStreamID inAudioFileStream, AudioFileStreamPropertyID inPropertyID, AudioFileStreamPropertyFlags *ioFlags) {
    HMXAudioFileStreamReader *audioFileStream = (__bridge HMXAudioFileStreamReader *)(inClientData);
    [audioFileStream handleAudioProperty:inPropertyID];
    *ioFlags = kAudioFileStreamPropertyFlag_CacheProperty;
}

static void HMXAudioFileStreamPacketsCallback(void *inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets, const void *inInputData, AudioStreamPacketDescription *inPacketDescriptions) {
    HMXAudioFileStreamReader *audioFileStream = (__bridge HMXAudioFileStreamReader *)(inClientData);
    [audioFileStream handleAudioFileStreamPackets:inInputData packetDescriptions:inPacketDescriptions numberBytes:inNumberBytes numberPackets:inNumberPackets];
}

@implementation HMXAudioFileStreamReader

- (BOOL)configureAudioFileReader {
    NSError *error;
    self.mFileHandle = [NSFileHandle fileHandleForReadingFromURL:self.fileURL error:&error];
    if (!self.mFileHandle || error) {
        return NO;
    }
    
    return [self openAudioFileStream];
}

- (BOOL)openAudioFileStream {
    OSStatus result = AudioFileStreamOpen((__bridge void * _Nullable)(self), HMXAudioPropertyListener, HMXAudioFileStreamPacketsCallback, self.audioFileType, &_mAudioFileStreamID);
    
    if (result != noErr) {
        self.mAudioFileStreamID = NULL;
        return NO;
    }
    
    return YES;
}

- (void)closeAudioFileStream {
    if (self.available) {
        AudioFileStreamClose(self.mAudioFileStreamID);
        self.mAudioFileStreamID = NULL;
    }
}

- (void)startParse {
    dispatch_async(self.mAudioReadQueue, ^{
        while (!self.fileFinished) {
            [self parseFollowData];
        }
    });
}

- (void)parseFollowData {
    NSData *audioData = [self.mFileHandle readDataOfLength:kAudioDataBytesPerRead];
    if (audioData.length < kAudioDataBytesPerRead) {
        self.fileFinished = YES;
    }
    BOOL result = [self parseAudioData:(void *)audioData.bytes dataSize:(UInt32)audioData.length];
    if (!result) {
        
    }
}

- (BOOL)parseAudioData:(void *)audioData dataSize:(UInt32)dataSize {
    OSStatus status = AudioFileStreamParseBytes(self.mAudioFileStreamID, dataSize, audioData, self.mDiscontinuity ? kAudioFileStreamParseFlag_Discontinuity : 0);
    return status == noErr;
}

- (void)seekToTime:(NSTimeInterval)time {
    
}

#pragma mark -- Callback
- (void)handleAudioProperty:(AudioFileStreamPropertyID)propertyID {
    
//    NSLog(@"handleAudioProperty = %d", propertyID);
    
    OSStatus result = noErr;
    UInt32 propSize = 0;
    
    if (propertyID == kAudioFileStreamProperty_ReadyToProducePackets) {
//        self.readyToProducePackets = YES;
//        self.mDiscontinuity = YES;

        // 获取音频数据格式
        propSize = sizeof(self.audioFormat);
        AudioStreamBasicDescription asbd = {0};
        AudioFileStreamGetProperty(self.mAudioFileStreamID, kAudioFileStreamProperty_DataFormat, &propSize, &asbd);
        self.audioFormat = asbd;

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
            free(magicCookieData);
        }
        
    } else if (propertyID == kAudioFileStreamProperty_AudioDataByteCount) {
        // 获取音频数据字节数
        propSize = sizeof(self.audioDataByteCount);
        result = AudioFileStreamGetProperty(self.mAudioFileStreamID, kAudioFileStreamProperty_AudioDataByteCount, &propSize, &_audioDataByteCount);
        if (result != noErr) {
            NSLog(@"read audio data byte count property failed, errorCode = %d", result);
        }
    } else if (propertyID == kAudioFileStreamProperty_AudioDataPacketCount) {
        // 获取音频帧数
        propSize = sizeof(self.audioDataPacketCount);
        result = AudioFileStreamGetProperty(self.mAudioFileStreamID, kAudioFileStreamProperty_AudioDataPacketCount, &propSize, &_audioDataPacketCount);
        if (result != noErr) {
            NSLog(@"read audio data packet count property failed, errorCode = %d", result);
        }
    }
}

- (void)handleAudioFileStreamPackets:(const void *)packetsData packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions numberBytes:(UInt32)numberBytes numberPackets:(UInt32)numberPackets {
    
    static UInt32 packetCount = 0;
    packetCount += numberPackets;
    
    
    static UInt64 byteCount = 0;
    byteCount += numberBytes;
    
    
    
    if ([self.delegate respondsToSelector:@selector(audioFileReader:didLoadAudioPackets:numberBytes:packetDescriptions:numberPackets:)]) {
        [self.delegate audioFileReader:self didLoadAudioPackets:packetsData numberBytes:numberBytes packetDescriptions:packetDescriptions numberPackets:numberPackets];
    }
}

#pragma mark -- Getter/Setter
- (BOOL)available {
    return self.mAudioFileStreamID != NULL;
}

- (dispatch_queue_t)mAudioReadQueue {
    if (_mAudioReadQueue == nil) {
        _mAudioReadQueue = dispatch_queue_create("audio read queue", DISPATCH_QUEUE_SERIAL);
    }
    return _mAudioReadQueue;
}

@end
