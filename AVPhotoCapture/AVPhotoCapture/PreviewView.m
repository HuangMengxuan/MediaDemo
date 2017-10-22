//
//  PreviewView.m
//  AVPhotoCapture
//
//  Created by 黄梦轩 on 2017/10/22.
//  Copyright © 2017年 黄梦轩. All rights reserved.
//

#import "PreviewView.h"

@implementation PreviewView

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (void)setSession:(AVCaptureSession *)session {
    self.previewLayer.session = session;
}

- (AVCaptureSession *)session {
    return self.previewLayer.session;
}

@end
