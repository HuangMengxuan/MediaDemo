//
//  ViewController.m
//  AVPhotoCapture
//
//  Created by 黄梦轩 on 2017/10/22.
//  Copyright © 2017年 黄梦轩. All rights reserved.
//

@import Photos;

#import "ViewController.h"
#import "PreviewView.h"

typedef NS_ENUM(NSInteger, AVDeviceSetupResult) {
    AVDeviceSetupResultSuccess = 1,
    AVDeviceSetupResultNotAuthorized = 2,
    AVDeviceSetupResultConfigureSeesionFailed = 3
};

@interface ViewController () <AVCapturePhotoCaptureDelegate>

@property (weak, nonatomic) IBOutlet PreviewView *myPreviewView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *myLiveSegmentControl;
@property (weak, nonatomic) IBOutlet UIButton *myPhotoButton;

@property (strong, nonatomic) AVCaptureSession *mSession;
@property (strong, nonatomic) AVCaptureDeviceDiscoverySession *mDiscoverySession;
@property (strong, nonatomic) AVCaptureDevice *mCaptureDevice;
@property (strong, nonatomic) AVCaptureDeviceInput *mVideoDeviceInput;
@property (strong, nonatomic) AVCaptureDeviceInput *mAudioDeviceInput;
@property (strong, nonatomic) AVCapturePhotoOutput *mPhotoOutput;

@property (strong, nonatomic) dispatch_queue_t mSessionQueue;

@property (assign, nonatomic) AVDeviceSetupResult mDeviceSetupResult;

@property (strong, nonatomic) NSData *mPhotoData;
@property (strong, nonatomic) NSURL *mPhotoFileURL;

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
    self.mSession.sessionPreset = AVCaptureSessionPresetPhoto;
    
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
    AVCapturePhotoOutput *photoOutput = [[AVCapturePhotoOutput alloc] init];
    
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
    if ([self.mSession canAddOutput:photoOutput]) {
        [self.mSession addOutput:photoOutput];
        self.mPhotoOutput = photoOutput;
        
        // 将photoOutput添加到session之后， 各属性数据才是有效数据
        photoOutput.highResolutionCaptureEnabled = YES;
        photoOutput.livePhotoCaptureEnabled = photoOutput.livePhotoCaptureSupported;
        photoOutput.depthDataDeliveryEnabled = photoOutput.depthDataDeliverySupported;
    }
    
    [self.mSession commitConfiguration];
    
}

#pragma mark -- Interface Action
- (IBAction)captureButtonAction:(UIButton *)sender {
    /*
         Retrieve the video previewLayer's video orientation on the main queue before entring the session queue.
         We do the to ensure accessing UI elements on the main queue and session configure is done on the session queue.
     */
    AVCaptureVideoOrientation videoOrientation = self.myPreviewView.previewLayer.connection.videoOrientation;
    
    dispatch_async(self.mSessionQueue, ^{
        // Update the photo output's connection to match the video orientation of the video preview layer.
        AVCaptureConnection *connetion = [self.mPhotoOutput connectionWithMediaType:AVMediaTypeVideo];
        connetion.videoOrientation = videoOrientation;
        
        AVCapturePhotoSettings *photoSettings;
        if ([self.mPhotoOutput.availablePhotoCodecTypes containsObject:AVVideoCodecTypeHEVC]) {
            photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey : AVVideoCodecTypeHEVC}];
        } else {
            photoSettings = [AVCapturePhotoSettings photoSettings];
        }
        
        if ([self.mVideoDeviceInput.device isFlashAvailable]) {
            photoSettings.flashMode = AVCaptureFlashModeAuto;
        }
        
        photoSettings.highResolutionPhotoEnabled = YES;
        
        if (self.mPhotoOutput.livePhotoCaptureSupported) {
            self.mPhotoOutput.livePhotoCaptureEnabled = YES;
            
            NSString *livePhotoFileName = [[NSUUID UUID].UUIDString stringByAppendingPathExtension:@"mov"];
            NSString *livePhotoFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:livePhotoFileName];
            photoSettings.livePhotoMovieFileURL = [NSURL fileURLWithPath:livePhotoFilePath];
        }
        
        [self.mPhotoOutput capturePhotoWithSettings:photoSettings delegate:self];
    });
}

- (IBAction)liveSegmentedValueChanged:(UISegmentedControl *)sender {
}


#pragma mark -- AVCapturePhotoCaptureDelegate
/**
 The sequenece of delegate calls
 1. willBeginCaptureForResolvedSettings
 2. willCapturePhotoForResolvedSettings
 3. didCapturePhotoForResolvedSettings
 4. didFinishProcessingPhoto
 5. didFinishRecordingLivePhotoMovieForEventualFileAtURL
 6. didFinishProcessingLivePhotoToMovieFileAtURL
 7. didFinishCaptureForResolvedSettings
 */
- (void)captureOutput:(AVCapturePhotoOutput *)output willBeginCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    
}

- (void)captureOutput:(AVCapturePhotoOutput *)output willCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.myPreviewView.previewLayer.opacity = 0.0;
        [UIView animateWithDuration:0.5 animations:^{
            self.myPreviewView.previewLayer.opacity = 1.0;
        }];
    });
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
    if (error) {
        NSLog(@"Error capture photo: %@ ", error);
        return;
    }
    
    self.mPhotoData = photo.fileDataRepresentation;
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishCaptureForResolvedSettings:(nonnull AVCaptureResolvedPhotoSettings *)resolvedSettings error:(nullable NSError *)error {
    if (error) {
        NSLog(@"Error capture photo: %@ ", error);
        return;
    }
    
    if (self.mPhotoData == nil) {
        NSLog(@"Error capture photo: %@ ", error);
        return;
    }
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
                PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAsset];
                [creationRequest addResourceWithType:PHAssetResourceTypePhoto data:self.mPhotoData options:options];
                
                if (self.mPhotoFileURL) {
                    PHAssetResourceCreationOptions *livePhotoCompanionMovieResourceOptions = [[PHAssetResourceCreationOptions alloc] init];
                    livePhotoCompanionMovieResourceOptions.shouldMoveFile = YES;
                    [creationRequest addResourceWithType:PHAssetResourceTypePairedVideo fileURL:self.mPhotoFileURL options:livePhotoCompanionMovieResourceOptions];
                }
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                if (!success) {
                    NSLog(@"Error occurred while saving photo data to photo library");
                } else {
                    NSLog(@"Save photo data to photo library succeed");
                }
            }];
        } else {
            NSLog(@"No Authorized to save photo");
        }
    }];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingLivePhotoToMovieFileAtURL:(NSURL *)outputFileURL duration:(CMTime)duration photoDisplayTime:(CMTime)photoDisplayTime resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(NSError *)error {
    if (error) {
        NSLog(@"Error processing live photo companion movie: %@ ", error);
        return;
    }
    
    self.mPhotoFileURL = outputFileURL;
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishRecordingLivePhotoMovieForEventualFileAtURL:(NSURL *)outputFileURL resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    
}

@end
