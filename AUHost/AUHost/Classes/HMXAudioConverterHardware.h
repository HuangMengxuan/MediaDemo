//
//  HMXAudioConverterHardware.h
//  AUHost
//
//  Created by lsyy on 2017/10/26.
//  Copyright © 2017年 sonirock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface HMXAudioConverterHardware : NSObject

- (OSStatus)configureAudioConverterWithSourceFormat:(AudioStreamBasicDescription)sourceFormat destinationFormat:(AudioStreamBasicDescription)destinationFormat;

@end
