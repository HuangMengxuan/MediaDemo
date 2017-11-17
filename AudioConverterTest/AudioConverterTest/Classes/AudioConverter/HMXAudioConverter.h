//
//  HMXAudioConverter.h
//  AudioConverterTest
//
//  Created by lsyy on 2017/11/13.
//  Copyright © 2017年 sonirock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
@class HMXAudioConverter;

@protocol HMXAudioConverterDelegate <NSObject>

- (void)audioConverter:(HMXAudioConverter *)audioConverter didConverterAudioData:(void *)audioData dataSize:(UInt32)dataSize packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions numberPackets:(UInt32)numberPackets;

@end

@interface HMXAudioConverter : NSObject

@property (assign, nonatomic) id<HMXAudioConverterDelegate> delegate;

- (instancetype)initWithSourceASBD:(AudioStreamBasicDescription)sourceASBD destinationASBD:(AudioStreamBasicDescription)destinationASBD;

- (void)initializeAudioConverter;

- (void)convertAudioData:(void *)audioData audioDataLength:(UInt32)audioDataLength packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions numberPackets:(UInt32)numberPackets;

@end
