//
//  HMXAudioFileStreamReader.m
//  AudioConverterTest
//
//  Created by lsyy on 2017/11/13.
//  Copyright © 2017年 sonirock. All rights reserved.
//

#import "HMXAudioFileStreamReader.h"

@interface HMXAudioFileStreamReader ()

@property (strong, nonatomic) NSFileHandle *mFileHandle;

@property (assign, nonatomic) AudioFileStreamID mAudioFileStreamID;
@property (assign, nonatomic) BOOL mDiscontinuity;
@property (assign, nonatomic, readwrite) BOOL available;


@property (assign, nonatomic, readwrite) AudioStreamBasicDescription audioFormat;
@property (assign, nonatomic, readwrite) NSData *magicData;

- (void)handleAudioProperty:(AudioFileStreamPropertyID)propertyID;
- (void)handleAudioFileStreamPackets:(const void *)packetsData packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions numberBytes:(UInt32)numberBytes numberPackets:(UInt32)numberPackets;

@end

static void HMXAudioPropertyListener(void *inClientData, AudioFileStreamID inAudioFileStream, AudioFileStreamPropertyID inPropertyID, AudioFileStreamPropertyFlags *ioFlags) {
    HMXAudioFileStreamReader *audioFileStream = (__bridge HMXAudioFileStreamReader *)(inClientData);
    [audioFileStream handleAudioProperty:inPropertyID];
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

//- (void)parseNext

- (BOOL)parseAudioData:(void *)audioData dataSize:(UInt32)dataSize {
    OSStatus status = AudioFileStreamParseBytes(self.mAudioFileStreamID, dataSize, audioData, self.mDiscontinuity ? kAudioFileStreamParseFlag_Discontinuity : 0);
    return status == noErr;
}

- (void)seekToTime:(NSTimeInterval)time {
    
}

#pragma mark -- Callback
- (void)handleAudioProperty:(AudioFileStreamPropertyID)propertyID {
    if (propertyID == kAudioFileStreamProperty_ReadyToProducePackets) {
//        self.readyToProducePackets = YES;
//        self.mDiscontinuity = YES;

        // 获取音频数据格式
        UInt32 propSize = sizeof(self.audioFormat);
        AudioStreamBasicDescription asbd = {0};
        AudioFileStreamGetProperty(self.mAudioFileStreamID, kAudioFileStreamProperty_DataFormat, &propSize, &asbd);
        self.audioFormat = asbd;

//        // 获取音频数据字节数
//        propSize = sizeof(self.audioDataByteCount);
//        AudioFileStreamGetProperty(self.mAudioFileStreamID, kAudioFileStreamProperty_AudioDataByteCount, &propSize, &_audioDataByteCount);
//
//        // 获取音频帧数
//        propSize = sizeof(self.audioDataPacketCount);
//        AudioFileStreamGetProperty(self.mAudioFileStreamID, kAudioFileStreamProperty_AudioDataPacketCount, &propSize, &_audioDataPacketCount);
//
//        // 获取采样率
//        propSize = sizeof(self.bitRate);
//        AudioFileStreamGetProperty(self.mAudioFileStreamID, kAudioFileStreamProperty_BitRate, &propSize, &_bitRate);
//
//        // 获取音频数据偏移量
//        propSize = sizeof(self.audioDataOffset);
//        AudioFileStreamGetProperty(self.mAudioFileStreamID, kAudioFileStreamProperty_DataOffset, &propSize, &_audioDataOffset);
        
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
        
    }
}

- (void)handleAudioFileStreamPackets:(const void *)packetsData packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions numberBytes:(UInt32)numberBytes numberPackets:(UInt32)numberPackets {
    if ([self.delegate respondsToSelector:@selector(audioFileReader:didLoadAudioPackets:numberBytes:packetDescriptions:numberPackets:)]) {
        [self.delegate audioFileReader:self didLoadAudioPackets:packetsData numberBytes:numberBytes packetDescriptions:packetDescriptions numberPackets:numberPackets];
    }
    
}

#pragma mark -- Getter/Setter
- (BOOL)available {
    return self.mAudioFileStreamID != NULL;
}

@end
