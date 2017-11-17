//
//  HMXAudioFileWriter.m
//  AudioConverterTest
//
//  Created by lsyy on 2017/11/15.
//  Copyright © 2017年 sonirock. All rights reserved.
//

#import "HMXAudioFileWriter.h"

@interface HMXAudioFileWriter ()

@property (assign, nonatomic) AudioFileID audioFileID;

@property (assign, nonatomic) AudioFileTypeID audioFileType;
@property (assign, nonatomic) AudioStreamBasicDescription audioFormat;
@property (assign, nonatomic) CFURLRef audioFileURL;

@property (assign, nonatomic) SInt64 packetIndex;
@property (assign, nonatomic) SInt64 byteIndex;

@end

@implementation HMXAudioFileWriter

- (instancetype)initWithAudioFileType:(AudioFileTypeID)audioFileType audioFormat:(AudioStreamBasicDescription)audioFormat audioFileURL:(CFURLRef)audioFileURL {
    if (self = [super init]) {
        _audioFileType = audioFileType;
        _audioFormat = audioFormat;
        _audioFileURL = audioFileURL;
        [self configureAudioFile];
    }
    return self;
}

- (void)configureAudioFile {
    OSStatus result = AudioFileCreateWithURL(self.audioFileURL, self.audioFileType, &_audioFormat, kAudioFileFlags_EraseFile, &_audioFileID);
    if (result != noErr) {
        NSLog(@"create audio file failed, errorCode = %d", result);
        self.audioFileID = NULL;
        return;
    }
    
    result = AudioFileSetProperty(self.audioFileID, kAudioFilePropertyDataFormat, sizeof(self.audioFormat), &_audioFormat);
    if (result != noErr) {
        NSLog(@"set data format failed, errorCode = %d", result);
        self.audioFileID = NULL;
        return;
    }
    
    // Magic Cookie
    
    // Audio Layout
}

- (void)writeAudioDataWithAudioData:(void *)audioData dataSize:(UInt32)dataSize packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions packetNum:(UInt32)packetNum {
    OSStatus result = noErr;
    
    result = AudioFileWriteBytes(self.audioFileID, false, self.byteIndex, &dataSize, audioData);
    if (result != noErr) {
        NSLog(@"write audio bytes failed, errorCode = %d", result);
        return;
    }
    
//    OSStatus result = AudioFileWritePackets(self.audioFileID, false, dataSize, packetDescriptions, self.packetIndex, &packetNum, audioData);
//    if (result != noErr) {
//        NSLog(@"write audio packets failed, errorCode = %d", result);
//        return;
//    }
    self.packetIndex += packetNum;
    self.byteIndex += dataSize;
}

- (void)optimizeAudioFile {
    OSStatus result = AudioFileOptimize(self.audioFileID);
    if (result != noErr) {
        NSLog(@"optimize audio file failed, errorCode = %d", result);
        return;
    }
}

#pragma mark -- Getter/Setter
- (BOOL)available {
    return self.audioFileID != NULL;
}

@end
