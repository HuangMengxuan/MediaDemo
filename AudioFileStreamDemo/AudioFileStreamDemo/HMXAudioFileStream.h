//
//  HMXAudioFileStream.h
//  AudioFileStreamDemo
//
//  Created by lsyy on 2017/11/4.
//  Copyright © 2017年 sonirock. All rights reserved.
//

@import AudioToolbox;
#import <Foundation/Foundation.h>

@interface HMXAudioFileStream : NSObject

@property (assign, nonatomic, readonly) AudioFileTypeID fileTypeID;
@property (assign, nonatomic, readonly) BOOL available;
@property (assign, nonatomic, readonly) BOOL readyToProducePackets;
@property (assign, nonatomic,readonly) AudioStreamBasicDescription audioDataFormat;
@property (assign, nonatomic, readonly) UInt64 audioDataByteCount;
@property (assign, nonatomic, readonly) UInt64 audioDataPacketCount;
@property (assign, nonatomic, readonly) SInt64 audioDataOffset;
@property (assign, nonatomic, readonly) UInt32 bitRate;
@property (assign, nonatomic, readonly) NSTimeInterval duration;
@property (copy, nonatomic, readonly) NSData *magicData;


- (instancetype)initWithFileTypeID:(AudioFileTypeID)fileTypeID;

- (BOOL)parseAudioData:(void *)audioData dataSize:(UInt32)dataSize;
- (void)seekToTime:(NSTimeInterval)time;

@end
