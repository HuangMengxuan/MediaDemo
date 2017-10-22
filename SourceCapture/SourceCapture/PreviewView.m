//
//  PreviewView.m
//  SourceCapture
//
//  Created by 黄梦轩 on 2017/10/22.
//  Copyright © 2017年 sonirock. All rights reserved.
//

#import "PreviewView.h"

@implementation PreviewView

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer {
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (void)setSession:(AVCaptureSession *)session {
    self.videoPreviewLayer.session = session;
}

- (AVCaptureSession *)session {
    return self.videoPreviewLayer.session;
}

@end
