//
//  ViewController.m
//  LLPlayer
//
//  Created by 罗李 on 17/1/10.
//  Copyright © 2017年 罗李. All rights reserved.
//

#import "ViewController.h"
#import "NRDPlayView.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NRDPlayView *playerView = [NRDPlayView sharedPlayer];
    
    playerView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 300);
    
    //        NSURL *url = [[NSBundle mainBundle] URLForResource:@"02-第三方播放器及视频采集.mp4" withExtension:nil];
    
    NSURL *url = [NSURL URLWithString:@"http://101.44.1.121/mp4files/310000000356077D/clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"];
    
    [playerView playerMovieWithURL:url];
    
    [self.view addSubview:playerView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
