//
//  ViewController.m
//  SourceCapture
//
//  Created by lsyy on 2017/10/18.
//  Copyright © 2017年 sonirock. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (strong, nonatomic) AVCaptureSession *mSession;
@property (strong, nonatomic) AVCaptureDevice *mAudioDevice;
@property (strong, nonatomic) AVCaptureConnection *mAudioConnection;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mSession = [[AVCaptureSession alloc] init];
}

- (void)setupAudioCapture {
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
