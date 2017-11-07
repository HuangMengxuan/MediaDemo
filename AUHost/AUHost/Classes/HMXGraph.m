//
//  HMXGraph.m
//  AUHost
//
//  Created by lsyy on 2017/10/26.
//  Copyright © 2017年 sonirock. All rights reserved.
//

#import "HMXGraph.h"
#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioToolbox.h>

@interface HMXGraph ()

@property (assign, nonatomic) double graphSampleRate;
@property (assign, nonatomic) double ioBufferDuration;
@property (strong, nonatomic) AVAudioSession *audioSession;
@property (assign, nonatomic) AUGraph audioGraph;
@property (assign, nonatomic) AudioUnit ioAudioUnit;

@end

@implementation HMXGraph

/**
 Setps for constructing an audio unit hosting app
 1. Configure your audio session.
 2. Specify audio units.
 3. Create an audio processing graph, then obtain the audio units.
 4. Configure the audio units.
 5. Connect the audio unit nodes.
 6. Provide a user interface.
 7. Initialize and then start the audio processing graph.
 */
- (instancetype)init {
    if (self = [super init]) {
        _graphSampleRate = 44100.0f;
        _ioBufferDuration = 0.023f;
    }
    return self;
}

- (void)configureAudioSession {
    NSError *audioSessionError = nil;
    
    // Obtain a reference to the singleton audio session object for your application.
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    // Request a hardware sample rate. The system may or may not be able to grant the request, depending on other audio activity on the device.
    [audioSession setPreferredSampleRate:self.graphSampleRate error:&audioSessionError];
    
    // Request a hardware I/O buffer duration. The default duration is about 23ms at a 44.1Hz sample rate, equivalent to a slice size of 1,024 samples.
    // You can request a smaller duration, down to about 0.005 ms (equivalent to 256 samples)
    [audioSession setPreferredIOBufferDuration:self.ioBufferDuration error:&audioSessionError];
    
    // Request the audio session category you want. The “play and record” category, specified here, supports audio input and output.
    [audioSession setMode:AVAudioSessionCategoryPlayAndRecord error:&audioSessionError];
    
    // Request activation of your audio session.
    [audioSession setActive:YES error:&audioSessionError];
    
    // After audio session activation, update your own sample rate variable according to the actual sample rate provided by the system.
    self.graphSampleRate = audioSession.sampleRate;
    self.ioBufferDuration = audioSession.IOBufferDuration;
}

- (void)createAUGraph {
    OSStatus status = noErr;
    
    AudioComponentDescription ioUnitDescription;
    ioUnitDescription.componentType = kAudioUnitType_Output;
    ioUnitDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    ioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    ioUnitDescription.componentFlags = 0;
    ioUnitDescription.componentFlagsMask = 0;
    
    AUGraph processingGraph;
    
    status = NewAUGraph(&processingGraph);
    
    AUNode remoteIONode;
    
    status = AUGraphAddNode(processingGraph, &ioUnitDescription, &remoteIONode);
    
    status = AUGraphOpen(processingGraph);
    
    self.audioGraph = processingGraph;
    
    status = AUGraphNodeInfo(processingGraph, remoteIONode, &ioUnitDescription, &_ioAudioUnit);
}

@end
