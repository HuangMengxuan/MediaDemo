//
//  ViewController.m
//  AudioConverterTest
//
//  Created by lsyy on 2017/11/13.
//  Copyright © 2017年 sonirock. All rights reserved.
//

#import "HMXViewController.h"

@interface HMXViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *myTableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *myReaderSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *myCodecSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *myWriterSegment;

@property (strong, nonatomic) NSMutableArray<NSString *> *mFilePaths;
@property (copy, nonatomic) NSString *mCurrentPath;

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
    self.mCurrentPath = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
}

- (IBAction)startButtonAction:(id)sender {
    if (self.mCurrentPath == nil) {
        return;
    }
    
    NSString *extension = [self.mCurrentPath pathExtension];
    if ([extension isEqualToString:@"pcm"] || [extension isEqualToString:@"wav"]) {
        // 编码
    } else {
        // 解码
    }
}

- (IBAction)stopButtonAction:(id)sender {
}

@end
