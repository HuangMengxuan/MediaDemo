//
//  ViewController.m
//  AudioConverterTest
//
//  Created by lsyy on 2017/11/13.
//  Copyright © 2017年 sonirock. All rights reserved.
//

#import "HMXViewController.h"
#import "HMXAudioFileStreamReader.h"
#import "HMXAudioConverter.h"
#import "HMXAudioFileWriter.h"

@interface HMXViewController () <UITableViewDelegate, UITableViewDataSource, HMXAudioFileReaderDelegate, HMXAudioConverterDelegate>

@property (weak, nonatomic) IBOutlet UITableView *myTableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *myReaderSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *myCodecSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *myWriterSegment;

@property (strong, nonatomic) NSMutableArray<NSString *> *mFilePaths;
@property (copy, nonatomic) NSString *mCurrentPath;


@property (strong, nonatomic) HMXAudioFileReader *mAudioFileReader;
@property (strong, nonatomic) HMXAudioConverter *mAudioConverter;
@property (strong, nonatomic) HMXAudioFileWriter *mAudioFileWriter;


@end

@implementation HMXViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mFilePaths = [@[] mutableCopy];
    
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *fileArray = [fileManager contentsOfDirectoryAtPath:docPath error:NULL];
    for (NSString *string in fileArray) {
        [self.mFilePaths addObject:[docPath stringByAppendingPathComponent:string]];
    }
    
    self.myTableView.delegate = self;
    self.myTableView.dataSource = self;
}

#pragma mark -- UITableViewDelegate & UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.mFilePaths.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TableViewCellIdentifier"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TableViewCellIdentifier"];
    }
    cell.textLabel.text = self.mFilePaths[indexPath.row].lastPathComponent;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.mCurrentPath = self.mFilePaths[indexPath.row];
}

#pragma mark -- HMXAudioFileReaderDelegate
- (void)audioFileReader:(HMXAudioFileReader *)aduioFileReader didLoadAudioPackets:(const void *)packetsData numberBytes:(UInt32)numberBytes packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions numberPackets:(UInt32)numberPackets {
    if (self.mAudioConverter == nil) {
        AudioStreamBasicDescription destinationASBD = {44100.0f, kAudioFormatLinearPCM, (kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger), 4, 1, 4, 2, 16, 0};
        self.mAudioConverter = [[HMXAudioConverter alloc] initWithSourceASBD:aduioFileReader.audioFormat destinationASBD:destinationASBD];
        self.mAudioConverter.delegate = self;
        [self.mAudioConverter initializeAudioConverter];
    }
    [self.mAudioConverter convertAudioData:(void *)packetsData audioDataLength:numberBytes packetDescriptions:packetDescriptions numberPackets:numberPackets];
}

#pragma mark -- HMXAudioConverterDelegate
- (void)audioConverter:(HMXAudioConverter *)audioConverter didConverterAudioData:(void *)audioData dataSize:(UInt32)dataSize packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions numberPackets:(UInt32)numberPackets {
    [self.mAudioFileWriter writeAudioDataWithAudioData:audioData dataSize:dataSize packetDescriptions:packetDescriptions packetNum:numberPackets];
}

- (IBAction)startButtonAction:(id)sender {
    if (self.mCurrentPath == nil) {
        return;
    }
    
    NSString *extension = [self.mCurrentPath pathExtension];
    if ([extension isEqualToString:@"pcm"] /*|| [extension isEqualToString:@"wav"]*/) {
        // 编码
    } else {
        // 解码
        self.mAudioFileReader = [[HMXAudioFileStreamReader alloc] initWithFileURL:[NSURL fileURLWithPath:self.mCurrentPath] fileType:0];
        self.mAudioFileReader.delegate = self;
        [self.mAudioFileReader configureAudioFileReader];
        [self.mAudioFileReader startParse];
        
        NSString *path = [self.mCurrentPath.stringByDeletingPathExtension stringByAppendingPathExtension:@"wav"];
        NSURL *url = [NSURL fileURLWithPath:path];
        CFURLRef urlRef = (__bridge CFURLRef)(url);
        AudioStreamBasicDescription destinationASBD = {44100.0f, kAudioFormatLinearPCM, (kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger), 4, 1, 4, 2, 16, 0};
        self.mAudioFileWriter = [[HMXAudioFileWriter alloc] initWithAudioFileType:kAudioFileWAVEType audioFormat:destinationASBD audioFileURL:urlRef];
        CFRelease(urlRef);
    }
}

- (IBAction)stopButtonAction:(id)sender {
    [self.mAudioFileWriter optimizeAudioFile];
}

@end
