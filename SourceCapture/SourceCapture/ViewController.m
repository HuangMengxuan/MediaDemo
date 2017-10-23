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

typedef NS_ENUM(NSInteger, AVDeviceSetupResult) {
    AVDeviceSetupResultSuccess = 1,
    AVDeviceSetupResultNotAuthorized = 2,
    AVDeviceSetupResultConfigureSeesionFailed = 3
};


@interface ViewController () <AVCaptureFileOutputRecordingDelegate>

@property (weak, nonatomic) IBOutlet PreviewView *myPreviewView;
@property (weak, nonatomic) IBOutlet UIButton *myRecordButton;
@property (weak, nonatomic) IBOutlet UIButton *myCameraButton;


@property (strong, nonatomic) AVCaptureSession *mSession;
@property (strong, nonatomic) AVCaptureDeviceDiscoverySession *mDiscoverySession;
@property (strong, nonatomic) AVCaptureDevice *mCaptureDevice;
@property (strong, nonatomic) AVCaptureDeviceInput *mVideoDeviceInput;
@property (strong, nonatomic) AVCaptureDeviceInput *mAudioDeviceInput;
@property (strong, nonatomic) AVCaptureMovieFileOutput *mMovieFileOutput;

@property (strong, nonatomic) dispatch_queue_t mSessionQueue;

@property (assign, nonatomic) AVDeviceSetupResult mDeviceSetupResult;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create queue for comminute with AVCaptureSession
    self.mSessionQueue = dispatch_queue_create("capture session queue", DISPATCH_QUEUE_SERIAL);
    
    self.mDeviceSetupResult = AVDeviceSetupResultSuccess;
    [self checkDeviceAuthorization];
    
    dispatch_async(self.mSessionQueue, ^{
        [self configureCaptureSession];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    dispatch_async(self.mSessionQueue, ^{
        switch (self.mDeviceSetupResult) {
            case AVDeviceSetupResultSuccess:
                [self.mSession startRunning];
                break;
            case AVDeviceSetupResultNotAuthorized:
                
                break;
            case AVDeviceSetupResultConfigureSeesionFailed:
                
                break;
        }
    });
}

- (void)checkDeviceAuthorization {
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (authorizationStatus) {
        case AVAuthorizationStatusNotDetermined: {
            // the user has not yet made a choice regarding whether the client can access the hardware
            dispatch_suspend(self.mSessionQueue);
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (!granted) {
                    NSLog(@"not authorized!");
                    self.mDeviceSetupResult = AVDeviceSetupResultNotAuthorized;
                }
                dispatch_resume(self.mSessionQueue);
            }];
        }
            break;
        case AVAuthorizationStatusRestricted:
            // the client is not authorized to access the hardware for the media type. the user cannot change the client's status.
            self.mDeviceSetupResult = AVDeviceSetupResultNotAuthorized;
            break;
        case AVAuthorizationStatusDenied:
            // the user explicitly denied access to the hardware supporting a media type for the client.
            self.mDeviceSetupResult = AVDeviceSetupResultNotAuthorized;
            break;
        case AVAuthorizationStatusAuthorized:
            // the client is authorized to access the hardware supporting a meida type.
            
            break;
    }
}

- (void)configureCaptureSession {
    if (self.mDeviceSetupResult != AVDeviceSetupResultSuccess) {
        return;
    }
    
    NSError *error;
    
    // Create the AVCaptureSession
    self.mSession = [[AVCaptureSession alloc] init];
    
    // Set up session preset
    self.mSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Set up the preview view
        self.myPreviewView.session = self.mSession;
    });
    
    // Create the
    NSArray<AVCaptureDeviceType> *deviceTypes = @[AVCaptureDeviceTypeBuiltInDualCamera, AVCaptureDeviceTypeBuiltInWideAngleCamera];
    self.mDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
    
    // Choose video device
    // First choose the back dual camera, otherwise default to a back wide angle camera
    // If the back wide angle camera is not available, default to the front wide angle camera
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDualCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    if (videoDevice == nil) {
        videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
        
        if (videoDevice == nil) {
            videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
        }
    }
    
    if (videoDevice == nil) {
        self.mDeviceSetupResult = AVDeviceSetupResultConfigureSeesionFailed;
        NSLog(@"Obtain video capture device failed.");
        return;
    }
    
    // Obtain video input
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (videoDeviceInput == nil) {
        NSLog(@"Could not create video device input, %@", error);
        self.mDeviceSetupResult = AVDeviceSetupResultConfigureSeesionFailed;
        return;
    }
    
    // Obtain audio input
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (audioDeviceInput == nil) {
        NSLog(@"Could not create audio device input, %@", error);
    }
    
    // Obtain photo output
    AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    // Configure session
    [self.mSession beginConfiguration];
    
    // Add video input
    if ([self.mSession canAddInput:videoDeviceInput]) {
        [self.mSession addInput:videoDeviceInput];
        self.mVideoDeviceInput = videoDeviceInput;
    }
    
    // Add audio input
    if (audioDeviceInput) {
        if ([self.mSession canAddInput:audioDeviceInput]) {
            [self.mSession addInput:audioDeviceInput];
            self.mAudioDeviceInput = audioDeviceInput;
        }
    }
    
    // Add photo output
    if ([self.mSession canAddOutput:movieFileOutput]) {
        [self.mSession addOutput:movieFileOutput];
        self.mMovieFileOutput = movieFileOutput;
        
    }
    
    [self.mSession commitConfiguration];
    
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
        
        
        [self.mSession commitConfiguration];
    }
}


- (IBAction)recordButtonAction:(id)sender {
    NSString *title = self.mMovieFileOutput.isRecording ? @"Record" : @"Stop";
    [self.myRecordButton setTitle:title forState:UIControlStateNormal];
    
    if (self.mMovieFileOutput.isRecording) {
        [self.mMovieFileOutput stopRecording];
    } else {
        AVCaptureConnection *movieFileOutputConnection = [self.mMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        movieFileOutputConnection.videoOrientation = self.myPreviewView.videoPreviewLayer.connection.videoOrientation;
        
        // Use HEVC codec if supported
        if ([self.mMovieFileOutput.availableVideoCodecTypes containsObject:AVVideoCodecTypeHEVC]) {
            [self.mMovieFileOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecTypeHEVC} forConnection:movieFileOutputConnection];
        }
        
        // Start recording to a temporary file
        NSString *outputFileName = [NSUUID UUID].UUIDString;
        NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];
        [self.mMovieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
    }
}

- (IBAction)cameraButtonAction:(id)sender {
    [self changeCamera];
}

#pragma mark -- AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    
}

- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error {
    if (error) {
        NSLog(@"Movie file finished error: %@", error);
        return;
    }
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
                options.shouldMoveFile = YES;
                PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAsset];
                [creationRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:outputFileURL options:options];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                if (success) {
                    NSLog(@"Save movie data to photo library succeed");
                } else {
                    NSLog(@"Save movie data to photo library failed");
                }
            }];
        } else {
            NSLog(@"Not authorized write movie data to photo library");
        }
    }];
}


@end
