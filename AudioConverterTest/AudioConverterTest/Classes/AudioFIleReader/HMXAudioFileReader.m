//
//  HMXAudioFIleReader.m
//  AudioConverterTest
//
//  Created by lsyy on 2017/11/13.
//  Copyright © 2017年 sonirock. All rights reserved.
//

#import "HMXAudioFileReader.h"

@interface HMXAudioFileReader ()

@end

@implementation HMXAudioFileReader

- (instancetype)initWithFileURL:(NSURL *)fileURL fileType:(AudioFileTypeID)fileType {
    if (self = [super init]) {
        _audioFileType = fileType;
        _fileURL = fileURL;
//        [self configureAudioFileReader];
    }
    return self;
}

- (BOOL)configureAudioFileReader {
    return NO;
}

- (void)startParse {
    
}

@end
