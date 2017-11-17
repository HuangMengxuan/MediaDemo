//
//  HMXAudioConverter.m
//  AudioConverterTest
//
//  Created by lsyy on 2017/11/13.
//  Copyright © 2017年 sonirock. All rights reserved.
//

#import "HMXAudioConverter.h"

@interface HMXAudioConverter ()

@property (assign, nonatomic, readwrite) AudioConverterRef audioConverter;
@property (assign, nonatomic) AudioStreamBasicDescription sourceASBD;
@property (assign, nonatomic) AudioStreamBasicDescription destinationASBD;
@property (assign, nonatomic) AudioBufferList outputBufferList;

@property (assign, nonatomic, readwrite) void *currentBufferData;
@property (assign, nonatomic, readwrite) UInt32 currentBufferDataLength;
@property (assign, nonatomic, readwrite) UInt32 currentNumberDataPackets;
@property (nonatomic, assign) AudioStreamPacketDescription *outputPacketDescriptions;

@end

static OSStatus audioConverterComplexInputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData) {
    
    HMXAudioConverter *audioConverter = (__bridge HMXAudioConverter *)(inUserData);
    
    // 没有修改ioNumberDataPackets时，默认值为1，如果Packet数量多于1，解码不会报错，但是音频数据出错
    *ioNumberDataPackets = audioConverter.currentNumberDataPackets;
    
    ioData->mNumberBuffers = 1;
    ioData->mBuffers[0].mData = audioConverter.currentBufferData;
    ioData->mBuffers[0].mDataByteSize = audioConverter.currentBufferDataLength;
    ioData->mBuffers[0].mNumberChannels = audioConverter.destinationASBD.mChannelsPerFrame;
    
    if (outDataPacketDescription) {
        if (audioConverter.outputPacketDescriptions) {
            *outDataPacketDescription = audioConverter.outputPacketDescriptions;
        } else {
            *outDataPacketDescription = NULL;
        }
    }
    
    return noErr;
}

@implementation HMXAudioConverter

- (instancetype)initWithSourceASBD:(AudioStreamBasicDescription)sourceASBD destinationASBD:(AudioStreamBasicDescription)destinationASBD {
    if (self = [super init]) {
        _sourceASBD = sourceASBD;
        _destinationASBD = destinationASBD;
    }
    return self;
}

- (void)initializeAudioConverter {
    OSStatus result = AudioConverterNew(&_sourceASBD, &_destinationASBD, &_audioConverter);
    if (result != noErr) {
        // kAudioFormatUnsupportedDataFormatError 1718449215
        NSLog(@"AudioConverterNew == %d", result);
        
        self.audioConverter = NULL;
        return;
    }
    
    UInt32 propSize = 0;
    propSize = sizeof(self.sourceASBD);
    result = AudioConverterGetProperty(self.audioConverter, kAudioConverterCurrentInputStreamDescription, &propSize, &_sourceASBD);
    if (result != noErr) {
        NSLog(@"kAudioConverterCurrentInputStreamDescription == %d", result);
        return;
    }
    
    propSize = sizeof(self.destinationASBD);
    result = AudioConverterGetProperty(self.audioConverter, kAudioConverterCurrentOutputStreamDescription, &propSize, &_destinationASBD);
    if (result != noErr) {
        NSLog(@"kAudioConverterCurrentOutputStreamDescription == %d", result);
        return;
    }
}


- (void)convertAudioData:(void *)audioData audioDataLength:(UInt32)audioDataLength packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions numberPackets:(UInt32)numberPackets {
    
    self.currentBufferData = audioData;
    self.currentBufferDataLength = audioDataLength;
    self.currentNumberDataPackets = numberPackets;
    self.outputPacketDescriptions = packetDescriptions;
    
    _outputBufferList.mNumberBuffers = 1;
    _outputBufferList.mBuffers[0].mNumberChannels = self.destinationASBD.mChannelsPerFrame;
    _outputBufferList.mBuffers[0].mDataByteSize = numberPackets * self.sourceASBD.mFramesPerPacket * self.destinationASBD.mBytesPerFrame * self.destinationASBD.mChannelsPerFrame;;
    _outputBufferList.mBuffers[0].mData = malloc(_outputBufferList.mBuffers[0].mDataByteSize);
    
    UInt32 ioOutputDataPacketSize = self.sourceASBD.mFramesPerPacket * numberPackets;
    AudioStreamPacketDescription *outPacketDescriptions = malloc(numberPackets * sizeof(AudioStreamPacketDescription));
    memset(outPacketDescriptions, 0, numberPackets * sizeof(AudioStreamPacketDescription));
    
    NSLog(@" audio converter  in audioDataSize = %d PacketSize = %d", audioDataLength, ioOutputDataPacketSize);
    
    OSStatus result = AudioConverterFillComplexBuffer(self.audioConverter, audioConverterComplexInputDataProc, (__bridge void * _Nullable)(self), &ioOutputDataPacketSize, &_outputBufferList, outPacketDescriptions);
    if (result != noErr) {
        NSLog(@"AudioConverterFillComplexBuffer = %d", result);
        return;
    } else {
        if ([self.delegate respondsToSelector:@selector(audioConverter:didConverterAudioData:dataSize:packetDescriptions:numberPackets:)]) {
            [self.delegate audioConverter:self didConverterAudioData:self.outputBufferList.mBuffers[0].mData dataSize:self.outputBufferList.mBuffers[0].mDataByteSize packetDescriptions:outPacketDescriptions numberPackets:numberPackets];
        }
    }
}

@end
