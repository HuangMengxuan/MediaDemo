//
//  ViewController.m
//  SourceCapture
//
//  Created by lsyy on 2017/10/18.
//  Copyright © 2017年 sonirock. All rights reserved.
//

@import Photos;

#import "ViewController.h"
#import "PreviewView.h"

typedef NS_ENUM(NSInteger, HMXCaptureMode) {
    HMXCaptureModePhoto = 0,
    HMXCaptureModeMovie = 1
};


@interface ViewController () <AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate>

@property (weak, nonatomic) IBOutlet PreviewView *myPreviewView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *myCaptureModeSegment;
@property (weak, nonatomic) IBOutlet UIButton *myRecordButton;
@property (weak, nonatomic) IBOutlet UIButton *myPhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *myCameraButton;

@property (strong, nonatomic) AVCaptureSession *mSession;
@property (strong, nonatomic) AVCaptureDeviceDiscoverySession *mDiscoverySession;
@property (strong, nonatomic) AVCaptureDeviceInput *mVideoDeviceInput;
@property (strong, nonatomic) AVCaptureDeviceInput *mAudioDeviceInput;
@property (strong, nonatomic) AVCapturePhotoOutput *mPhotoOutput;
@property (strong, nonatomic) AVCaptureMovieFileOutput *mMovieOutput;

@property (assign, nonatomic) HMXCaptureMode mCaptureMode;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create a AVCaptureSession
    self.mSession = [[AVCaptureSession alloc] init];
    
    // Create a device discovery session
    NSArray *deviceTypes = @[AVCaptureDeviceTypeBuiltInDualCamera, AVCaptureDeviceTypeBuiltInWideAngleCamera];
    self.mDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
    
    /* discuss
     1. AVCaptureDeviceType
     2. AVMediaType
     3. AVCaptureDevicePosition
     */
    
    // Set up perview session
    self.myPreviewView.session = self.mSession;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self configureSession];
    [self.mSession startRunning];
    
}

- (void)configureSession {
    NSError *error = nil;
    
    [self.mSession beginConfiguration];
    
    // Set session preset
    self.mSession.sessionPreset = AVCaptureSessionPresetPhoto;
    
    /* discuss
     AVCaptureDeviceTypeBuiltInDualCamera 时创建失败
     AVCaptureDeviceTypeBuiltInWideAngleCamera 成功
     */
    
    // Choose camera
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    
    // obtain video device input
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (!videoDeviceInput) {
        NSLog(@"videoDeviceInput Error");
    }
    
    // Add video device input to session
    if ([self.mSession canAddInput:videoDeviceInput]) {
        [self.mSession addInput:videoDeviceInput];
        self.mVideoDeviceInput = videoDeviceInput;
    }
    
    // Add audio device input to session
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (!audioDeviceInput) {
        NSLog(@"Could not create audio device input to the session");
    }
    
    if ([self.mSession canAddInput:audioDeviceInput]) {
        [self.mSession addInput:audioDeviceInput];
        self.mAudioDeviceInput = audioDeviceInput;
    }
    
    // Add photo output to session
    AVCapturePhotoOutput *photoOutput = [[AVCapturePhotoOutput alloc] init];
    if ([self.mSession canAddOutput:photoOutput]) {
        [self.mSession addOutput:photoOutput];
        self.mPhotoOutput = photoOutput;
        
        self.mPhotoOutput.highResolutionCaptureEnabled = YES;
        self.mPhotoOutput.livePhotoCaptureEnabled = self.mPhotoOutput.livePhotoCaptureSupported;
        self.mPhotoOutput.depthDataDeliveryEnabled = self.mPhotoOutput.depthDataDeliverySupported;
    }
    
    [self.mSession commitConfiguration];
}

- (void)startRecording {
    
}

- (void)stopRecording {
    
}

- (void)changeCamera {
    AVCaptureDevice *captureDevice = self.mVideoDeviceInput.device;
    AVCaptureDevicePosition currentPosition = captureDevice.position;
    
    AVCaptureDevicePosition preferredPosition;
    AVCaptureDeviceType preferredDeviceType;
    
    switch (currentPosition) {
        case AVCaptureDevicePositionUnspecified:
        case AVCaptureDevicePositionFront:
            preferredPosition = AVCaptureDevicePositionBack;
            preferredDeviceType = AVCaptureDeviceTypeBuiltInDualCamera;
            break;
        case AVCaptureDevicePositionBack:
            preferredPosition = AVCaptureDevicePositionFront;
            preferredDeviceType = AVCaptureDeviceTypeBuiltInWideAngleCamera;
            break;
    }
    
    NSArray<AVCaptureDevice *> *captureDevices = self.mDiscoverySession.devices;
    
    AVCaptureDevice *newCaptureDevice = nil;
    
    for (AVCaptureDevice *captureDevice in captureDevices) {
        if (captureDevice.position == preferredPosition && captureDevice.deviceType == preferredDeviceType) {
            newCaptureDevice = captureDevice;
            break;
        }
    }
    
    if (newCaptureDevice == nil) {
        for (AVCaptureDevice *captureDevice in captureDevices) {
            if (captureDevice.position == preferredPosition) {
                newCaptureDevice = captureDevice;
                break;
            }
        }
    }
    
    if (newCaptureDevice) {
        AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:newCaptureDevice error:NULL];
        
        [self.mSession beginConfiguration];
        
        [self.mSession removeInput:self.mVideoDeviceInput];
        
        if ([self.mSession canAddInput:deviceInput]) {
            [self.mSession addInput:deviceInput];
            self.mVideoDeviceInput = deviceInput;
        } else {
            [self.mSession addInput:self.mVideoDeviceInput];
        }
        
        self.mPhotoOutput.livePhotoCaptureEnabled = self.mPhotoOutput.livePhotoCaptureSupported;
        self.mPhotoOutput.depthDataDeliveryEnabled = self.mPhotoOutput.depthDataDeliverySupported;
        
        
        [self.mSession commitConfiguration];
    }
}

- (IBAction)takePhotoButtonAction:(id)sender {
    AVCapturePhotoSettings *photoSettings;
    if ([self.mPhotoOutput.availablePhotoCodecTypes containsObject:AVVideoCodecTypeHEVC]) {
        photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey : AVVideoCodecTypeHEVC}];
    } else {
        photoSettings = [AVCapturePhotoSettings photoSettings];
    }
    
    [self.mPhotoOutput capturePhotoWithSettings:photoSettings delegate:self];
}

- (IBAction)recordButtonAction:(id)sender {
    NSString *title = self.mMovieOutput.isRecording ? @"Record" : @"Stop";
    [self.myRecordButton setTitle:title forState:UIControlStateNormal];
    
    if (self.mMovieOutput.isRecording) {
        [self.mMovieOutput stopRecording];
    } else {
        AVCaptureConnection *movieFileOutputConnection = [self.mMovieOutput connectionWithMediaType:AVMediaTypeVideo];
        movieFileOutputConnection.videoOrientation = self.myPreviewView.videoPreviewLayer.connection.videoOrientation;
        
        // Use HEVC codec if supported
        if ([self.mMovieOutput.availableVideoCodecTypes containsObject:AVVideoCodecTypeHEVC]) {
            [self.mMovieOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecTypeHEVC} forConnection:movieFileOutputConnection];
        }
        
        // Start recording to a temporary file
        NSString *outputFileName = [NSUUID UUID].UUIDString;
        NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];
        [self.mMovieOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
    }
}

- (IBAction)cameraButtonAction:(id)sender {
    [self changeCamera];
}

- (IBAction)captureModeChanged:(UISegmentedControl *)sender {
    self.mCaptureMode = sender.selectedSegmentIndex == 0 ? HMXCaptureModePhoto : HMXCaptureModeMovie;
    self.myRecordButton.enabled = self.mCaptureMode == HMXCaptureModeMovie;
    
    if (self.mCaptureMode == HMXCaptureModeMovie) {
        AVCaptureMovieFileOutput *movieFileoutput = [[AVCaptureMovieFileOutput alloc] init];
        
        if ([self.mSession canAddOutput:movieFileoutput]) {
            [self.mSession beginConfiguration];
            
            [self.mSession addOutput:movieFileoutput];
            self.mSession.sessionPreset = AVCaptureSessionPresetHigh;
            
            AVCaptureConnection *connection = [movieFileoutput connectionWithMediaType:AVMediaTypeVideo];
            
            if (connection.isVideoStabilizationSupported) {
                connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }
            
            [self.mSession commitConfiguration];
            
            self.mMovieOutput = movieFileoutput;
        }
    } else if (self.mCaptureMode == HMXCaptureModePhoto) {
        [self.mSession beginConfiguration];
        
        /*
         Remove the AVCaptureMovieFileOutput from the session because movie recording is not supported with AVCaptureSessionPresetPhoto.
         Additionally, Live photo capture is not supported when an AVCaptureMovieFileOutput is connected to the session.
         */
        
        // Remove the AVCaptureMovieFileOutput from the session
        [self.mSession removeOutput:self.mMovieOutput];
        self.mSession.sessionPreset = AVCaptureSessionPresetPhoto;
        self.mMovieOutput = nil;
        
        self.mPhotoOutput.livePhotoCaptureEnabled = self.mPhotoOutput.livePhotoCaptureSupported;
        self.mPhotoOutput.depthDataDeliveryEnabled = self.mPhotoOutput.depthDataDeliverySupported;
        
        [self.mSession commitConfiguration];
    }
}


#pragma mark -- AVCapturePhotoCaptureDelegate
- (void)captureOutput:(AVCapturePhotoOutput *)output willBeginCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    NSLog(@"willBeginCaptureForResolvedSettings");
}

- (void)captureOutput:(AVCapturePhotoOutput *)output willCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    NSLog(@"willCapturePhotoForResolvedSettings");
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    NSLog(@"didCapturePhotoForResolvedSettings");
}

// A callback fired when photos are ready to be delivered to you (RAW or processed).
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
    NSLog(@"didFinishProcessingPhoto");
    
    if (error != nil) {
        NSLog(@"didFinishProcessingPhoto Error");
    }
    
    if (photo == nil) {
        NSLog(@"didFinishProcessingPhoto no photo data");
    }
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
//                options.uniformTypeIdentifier =
                PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAsset];
                [creationRequest addResourceWithType:PHAssetResourceTypePhoto data:photo.fileDataRepresentation options:options];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                if ( ! success ) {
                    NSLog( @"Error occurred while saving photo to photo library: %@", error );
                }
            }];
        } else {
            NSLog(@"Not authorized to save photo");
        }
    }];
    
    
}

//  A callback fired when the photo capture is completed and no more callbacks will be fired.
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(NSError *)error {
    NSLog(@"didFinishCaptureForResolvedSettings");
    
    
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishRecordingLivePhotoMovieForEventualFileAtURL:(NSURL *)outputFileURL resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    NSLog(@"didFinishRecordingLivePhotoMovieForEventualFileAtURL");
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingLivePhotoToMovieFileAtURL:(NSURL *)outputFileURL duration:(CMTime)duration photoDisplayTime:(CMTime)photoDisplayTime resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(NSError *)error {
    NSLog(@"didFinishProcessingLivePhotoToMovieFileAtURL");
}

#pragma mark -- AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    
}

- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error {
    BOOL recordSuccessfully = YES;
    if (error.code != noErr) {
        id value = [error.userInfo objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value) {
            recordSuccessfully = [value boolValue];
        }
    }
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
                options.shouldMoveFile = YES;
                PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAsset];
                [creationRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:outputFileURL options:options];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                if ( ! success ) {
                    NSLog( @"Could not save movie to photo library: %@", error );
                }
            }];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
