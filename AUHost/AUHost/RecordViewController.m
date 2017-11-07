//
//  RecordViewController.m
//  AUHost
//
//  Created by lsyy on 2017/10/26.
//  Copyright © 2017年 sonirock. All rights reserved.
//
@import AVFoundation;
@import AudioToolbox;

struct RenderCallbackData {
    AudioUnit renderIOUnit;
}callbackData;

static OSStatus renderCallback (void                         *inRefCon,
                                AudioUnitRenderActionFlags     *ioActionFlags,
                                const AudioTimeStamp         *inTimeStamp,
                                UInt32                         inBusNumber,
                                UInt32                         inNumberFrames,
                                AudioBufferList              *ioData)
{
    OSStatus status = noErr;
    
    // We call AudioUnitRender on the input bus of AURemoteIO
    // This will store the audio data captured by the microphone in ioData
    status = AudioUnitRender(callbackData.renderIOUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
    
//    NSLog(@"inNumberFrames = %d  mNumberBuffers = %d  mBuffers[0].mDataByteSize = %d", inNumberFrames, ioData->mNumberBuffers, ioData->mBuffers[0].mDataByteSize);
    
    /*
    static NSString* filePath;
    if (filePath == nil) {
        NSArray* myPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* myDocPath = [myPaths objectAtIndex:0];
        filePath = [myDocPath stringByAppendingPathComponent:@"audioData.pcm"];
        
        NSFileManager* fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:filePath]) {
            [fileManager removeItemAtPath:filePath error:nil];
        }
        [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    }
    
    static FILE *fileHandler = NULL;
    if (fileHandler == NULL) {
        fileHandler = fopen(filePath.UTF8String, "wb");
    }
    fwrite(ioData->mBuffers[0].mData, 2, inNumberFrames, fileHandler);
    */
     
    return status;
}

#import "RecordViewController.h"

@interface RecordViewController ()

@property (assign, nonatomic) AudioUnit ioUnit;

@end

@implementation RecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureAudioChain];
    [self startIOUnit];
    
    kAudioFileEndOfFileError
}

- (void)configureAudioChain {
    [self configureAudioSession];
    [self configureIOUnit];
}

- (void)configureAudioSession {
    // Configure the audio session
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    NSError *error;
    
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    
    [audioSession setPreferredSampleRate:44100 error:&error];
    
    [audioSession setPreferredIOBufferDuration:0.01 error:&error];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVAudioSessionInterruptionNotification object:audioSession];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRouteChange:) name:AVAudioSessionRouteChangeNotification object:audioSession];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleServiceReset:) name:AVAudioSessionMediaServicesWereResetNotification object:audioSession];
    
    [audioSession setActive:YES error:&error];
}

- (void)configureIOUnit {
    AudioComponentDescription ioUnitDescription;
    ioUnitDescription.componentType = kAudioUnitType_Output;
    ioUnitDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    ioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    ioUnitDescription.componentFlags = 0;
    ioUnitDescription.componentFlagsMask = 0;
    
    AudioComponent component = AudioComponentFindNext(NULL, &ioUnitDescription);
    
    AudioComponentInstanceNew(component, &_ioUnit);
    
    // Enable input and output on AURemoteIO
    // Input is enabled on the input scope of input element
    // Output is enabled on the output scope of output element
    UInt32 enable = 1;
    AudioUnitSetProperty(self.ioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &enable, sizeof(enable));
    AudioUnitSetProperty(self.ioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &enable, sizeof(enable));
    
    // Explicilty set the input and output format
    AudioStreamBasicDescription asbd = {0};
    AVAudioFormat *audioFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16 sampleRate:44100 channels:1 interleaved:NO];
    asbd = *audioFormat.streamDescription;
    
    AudioUnitSetProperty(self.ioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &asbd, sizeof(asbd));
    AudioUnitSetProperty(self.ioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &asbd, sizeof(asbd));
    
    // Set the MaximumFramesPerSlice preoperty.
    // This value is used to describe to an audio unit the maximum number of samples it will be asked to produce on any single given call to AudioUnitRender
    UInt32 maxFramesPerSlice = 4096;
    AudioUnitSetProperty(self.ioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, sizeof(maxFramesPerSlice));
    
    UInt32 propSize = sizeof(UInt32);
    AudioUnitGetProperty(self.ioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, &propSize);
    
    callbackData.renderIOUnit = self.ioUnit;
    
    AURenderCallbackStruct callback;
    callback.inputProc = renderCallback;
    callback.inputProcRefCon = NULL;
    
    AudioUnitSetProperty(self.ioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callback, sizeof(callback));
    
    // Initalize the AURemoteIO instance(不initialize好像也能使用)
    AudioUnitInitialize(self.ioUnit);
}

- (OSStatus)startIOUnit {
    OSStatus result = AudioOutputUnitStart(self.ioUnit);
    return result;
}


- (void)handleInterruption:(NSNotification *)notification {
    
}

- (void)handleRouteChange:(NSNotification *)notification {
    
}

- (void)handleServiceReset:(NSNotification *)notification {
    
}

@end
