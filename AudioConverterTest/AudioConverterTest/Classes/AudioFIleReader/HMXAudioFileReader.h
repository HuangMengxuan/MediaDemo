//
//  HMXAudioFIleReader.h
//  AudioConverterTest
//
//  Created by lsyy on 2017/11/13.
//  Copyright © 2017年 sonirock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
@class HMXAudioFileReader;

@protocol HMXAudioFileReaderDelegate <NSObject>

- (void)audioFileReader:(HMXAudioFileReader *)aduioFileReader didLoadAudioPackets:(const void *)packetsData numberBytes:(UInt32)numberBytes packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions numberPackets:(UInt32)numberPackets;

@end

@interface HMXAudioFileReader : NSObject

@property (strong, nonatomic, readonly) NSURL *fileURL;
@property (assign, nonatomic, readonly) AudioFileTypeID audioFileType;
@property (assign, nonatomic, readonly) AudioStreamBasicDescription audioFormat;
@property (assign, nonatomic, readonly) NSData *magicData;

@property (weak, nonatomic) id<HMXAudioFileReaderDelegate> delegate;

- (instancetype)initWithFileURL:(NSURL *)fileURL fileType:(AudioFileTypeID)fileType;

- (BOOL)configureAudioFileReader;

@end
