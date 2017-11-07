//
//  HMXAudioConverterHardware.m
//  AUHost
//
//  Created by lsyy on 2017/10/26.
//  Copyright © 2017年 sonirock. All rights reserved.
//

#import "HMXAudioConverterHardware.h"

@interface HMXAudioConverterHardware ()

@property (assign, nonatomic) AudioStreamBasicDescription sourceFormat;
@property (assign, nonatomic) AudioStreamBasicDescription destinationFormat;

@property (assign, nonatomic) AudioConverterRef audioConverter;

@end

@implementation HMXAudioConverterHardware

- (OSStatus)configureAudioConverterWithSourceFormat:(AudioStreamBasicDescription)sourceFormat destinationFormat:(AudioStreamBasicDescription)destinationFormat {
    self.sourceFormat = sourceFormat;
    self.destinationFormat = destinationFormat;
    
    OSStatus result = AudioConverterNew(&_sourceFormat, &_destinationFormat, &_audioConverter);
    if (result != noErr) {
        NSLog(@"AudioConverterNew Error, code == %d", result);
        return result;
    }
    
    UInt32 propSize = 0;
    propSize = sizeof(self.sourceFormat);
    result = AudioConverterGetProperty(self.audioConverter, kAudioConverterCurrentInputStreamDescription, &propSize, &_sourceFormat);
    if (result != noErr) {
        NSLog(@"kAudioConverterCurrentInputStreamDescription == %d", result);
        return result;
    }
    
    propSize = sizeof(self.destinationFormat);
    result = AudioConverterGetProperty(self.audioConverter, kAudioConverterCurrentOutputStreamDescription, &propSize, &_destinationFormat);
    if (result != noErr) {
        NSLog(@"kAudioConverterCurrentOutputStreamDescription == %d", result);
        return result;
    }
    
    return result;
}

@end
