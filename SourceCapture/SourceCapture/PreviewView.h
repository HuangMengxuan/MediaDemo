//
//  PreviewView.h
//  SourceCapture
//
//  Created by 黄梦轩 on 2017/10/22.
//  Copyright © 2017年 sonirock. All rights reserved.
//

@import UIKit;
@import AVFoundation;

@interface PreviewView : UIView

@property (weak, nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (weak, nonatomic) AVCaptureSession *session;

@end
