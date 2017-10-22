//
//  ViewController.m
//  AVPhotoCapture
//
//  Created by 黄梦轩 on 2017/10/22.
//  Copyright © 2017年 黄梦轩. All rights reserved.
//

#import "ViewController.h"
#import "PreviewView.h"

@interface ViewController () <AVCapturePhotoCaptureDelegate>

@property (weak, nonatomic) IBOutlet PreviewView *myPreviewView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *myLiveSegmentControl;
@property (weak, nonatomic) IBOutlet UIButton *myPhotoButton;

@property (strong, nonatomic) AVCaptureSession *mSession;
@property (strong, nonatomic) AVCaptureDeviceDiscoverySession *mDiscoverySession;
@property (strong, nonatomic) AVCaptureDevice *mCaptureDevice;
@property (strong, nonatomic) AVCaptureDeviceInput *mVideoDevceInput;
@property (strong, nonatomic) AVCapturePhotoOutput *mPhotoOutput;

@property (strong, nonatomic) dispatch_queue_t mSessionQueue;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

#pragma mark -- Interface Action
- (IBAction)captureButtonAction:(UIButton *)sender {
}

- (IBAction)liveSegmentedValueChanged:(UISegmentedControl *)sender {
}


@end
