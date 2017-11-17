//
//  HMXAudioFileWriter.h
//  AudioConverterTest
//
//  Created by lsyy on 2017/11/15.
//  Copyright © 2017年 sonirock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface HMXAudioFileWriter : NSObject

@property (assign, nonatomic, readonly) BOOL available;

- (instancetype)initWithAudioFileType:(AudioFileTypeID)audioFileType audioFormat:(AudioStreamBasicDescription)audioFormat audioFileURL:(CFURLRef)audioFileURL;

- (void)writeAudioDataWithAudioData:(void *)audioData dataSize:(UInt32)dataSize packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions packetNum:(UInt32)packetNum;

- (void)optimizeAudioFile;

@end
