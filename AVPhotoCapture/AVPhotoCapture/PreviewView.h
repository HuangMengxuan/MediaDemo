//
//  PreviewView.h
//  AVPhotoCapture
//
//  Created by 黄梦轩 on 2017/10/22.
//  Copyright © 2017年 黄梦轩. All rights reserved.
//

@import AVKit;
@import AVFoundation;

@interface PreviewView : UIView

@property (weak, nonatomic, readonly) AVCaptureVideoPreviewLayer *previewLayer;
@property (weak, nonatomic) AVCaptureSession *session;

@end
