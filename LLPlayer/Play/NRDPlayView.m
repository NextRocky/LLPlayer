//
//  NRDPlayView.m
//  NRDPlay
//
//  Created by 罗李 on 16/10/26.
//  Copyright © 2016年 罗李. All rights reserved.
//

#import "NRDPlayView.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#define SELFWIDTH self.bounds.size.width
#define SELFHEIGHT self.bounds.size.height

#define SCREENW [UIScreen mainScreen].bounds.size.width
#define SCREENH [UIScreen mainScreen].bounds.size.height

typedef NS_ENUM(NSInteger, VideoPlayerState) {
    VideoPlayerStatePlay,
    VideoPlayerStatePause,
    VideoPlayerStateStop
};

//手指滑动状态记录
typedef NS_ENUM(NSInteger, GestureDirection){
    
    GestureDirectionHorizontalMoved, //水平划动
    GestureDirectionVerticalMoved    //垂直划动
    
};

@interface NRDPlayView ()
@property (nonatomic, assign) VideoPlayerState currentStatu;
@property (nonatomic,strong) AVPlayer *avPlayer;
@property (nonatomic,strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayerItem *item;
@property (nonatomic, strong) NSURL *url;

@property (nonatomic,assign) GestureDirection gestureDirection;
//  底部视图
@property (nonatomic,strong) UIView *bottomView;
//  背景图
@property (nonatomic,strong) UIImageView *backgroundImage;
//  播放按钮
@property (nonatomic, strong) UIButton *playerButton;
//  slider滚动条
@property (nonatomic,strong) UISlider *mySlider;
//  播放时间
@property (nonatomic,strong) UILabel *playTimeLab;
//  时长
@property (nonatomic,strong) UILabel *allTimeLab;
//  全屏按钮
@property (nonatomic,strong) UIButton *fullScreenBtn;
//  临时frame
@property (nonatomic, assign) CGRect tempFrame;
//  记录是否是全屏
@property (nonatomic, assign) BOOL ifFullScreen;
//  记录父控制器
@property (nonatomic,strong) UIView *superView;
//  定时器one
@property (nonatomic,strong) NSTimer *timer;
//  定时器Two
@property (nonatomic,strong) NSTimer *anotherTimer;
//  判断是否进入后台
@property (nonatomic, assign) BOOL isCallBack;
//  是否点击了slider
@property (nonatomic, assign) BOOL isClickSlider;
//  advance or retreat (前进后退界面)
@property (nonatomic,strong) UIView *advanceOrRetreatView;

//  调整音量
@property (nonatomic, assign) BOOL isAdjustVolume;
//  调整音量的slider
@property (nonatomic, strong) UISlider *volumeSlider;

//  菊花
@property (nonatomic, strong) UIView *loadDataView;
@property (nonatomic, strong) UIActivityIndicatorView *loadTurnView;

@end

@implementation NRDPlayView
static NRDPlayView *instance;

- (UIActivityIndicatorView *)loadTurnView
{
    if (!_loadTurnView) {
        _loadTurnView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self.loadDataView addSubview:_loadTurnView];
    }
    return _loadTurnView;
}
- (UIView *)loadDataView
{
    if (!_loadDataView) {
        _loadDataView = [[UIView alloc]init];
        [self addSubview:_loadDataView];
       
    }
    return _loadDataView;
}


#pragma mark - 快进快退界面
- (UIView *)advanceOrRetreatView
{
    if (!_advanceOrRetreatView) {
        _advanceOrRetreatView = [[UIView alloc]init];
        _advanceOrRetreatView.layer.cornerRadius = 5;
        _advanceOrRetreatView.layer.masksToBounds = YES;
    }
    return _advanceOrRetreatView;
}

#pragma mark - 全屏按钮
- (UIButton *)fullScreenBtn
{
    if (!_fullScreenBtn) {
        _fullScreenBtn = [[UIButton alloc]init];
        [_fullScreenBtn setImage:[UIImage imageNamed:@"screenBig"] forState:UIControlStateNormal];
        [_fullScreenBtn setImage:[UIImage imageNamed:@"screenSmall"] forState:UIControlStateSelected];
        [_fullScreenBtn addTarget:self action:@selector(clickActionFullScreen:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.bottomView addSubview:_fullScreenBtn];
    }
    return _fullScreenBtn;
}
#pragma mark- 总长度
- (UILabel *)allTimeLab
{
    if (!_allTimeLab) {
        _allTimeLab = [[UILabel alloc]init];
        _allTimeLab.text = @"00:00";
        _allTimeLab.font = [UIFont systemFontOfSize:15];
        [self.bottomView addSubview:_allTimeLab];
    }
    return _allTimeLab;
}

#pragma mark- 播放时间
-(UILabel *)playTime
{
    if (!_playTimeLab) {
        _playTimeLab = [[UILabel alloc]init];
        _playTimeLab.text = @"00:00";
        _playTimeLab.font = [UIFont systemFontOfSize:15];
        [self.bottomView addSubview:_playTimeLab];
    }
    return _playTimeLab;
}

#pragma mark- slider
-(UISlider *)mySlider
{
    if (!_mySlider) {
        _mySlider = [[UISlider alloc]init];
        [_mySlider setThumbImage:[UIImage imageNamed:@"Point"] forState:UIControlStateNormal];
        [_mySlider setMinimumTrackImage:[UIImage imageNamed:@"line"] forState:UIControlStateNormal];
        
//        [_mySlider addTarget:self action:@selector(sliderProgress:) forControlEvents:UIControlEventValueChanged];
        [self.bottomView addSubview:_mySlider];
        
    }
    return _mySlider;
}

#pragma mark- 播放按钮
- (UIButton *)playerButton
{
    if (!_playerButton) {
        _playerButton = [[UIButton alloc]init];
        
        UIImage *image = [UIImage imageNamed:@"Player"];
        [_playerButton setImage:image forState:UIControlStateNormal];
        
        [_playerButton setImage:[UIImage imageNamed:@"Pause"] forState:UIControlStateSelected];
        [_playerButton addTarget:self action:@selector(playerOrPause:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.bottomView addSubview:_playerButton];
    }
    return _playerButton;
}
#pragma mark- 背景图片
- (UIImageView *)backgroundImage
{
    if (!_backgroundImage) {
        _backgroundImage = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@""]];
        [self.bottomView addSubview:_backgroundImage];
    }
    return _backgroundImage;
}

#pragma mark - 懒加载(底部视图)
-(UIView *)bottomView
{
    if (!_bottomView) {
        _bottomView = [[UIView alloc]init];
        
        [self addSubview:_bottomView];
    }
    return _bottomView;
}
#pragma mark - 单利
+ (instancetype)sharedPlayer
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        instance = [[self alloc]init];
    });
    
    return instance;
}

- (void)playerMovieWithURL:(NSURL *)url
{
    self.url = url;

    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
        //  添加观察者
        [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    //  player
    self.avPlayer = [AVPlayer playerWithPlayerItem:item];
    //  layer
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    //  [self.layer addSublayer:self.playerLayer];
    [self.layer insertSublayer:self.playerLayer atIndex:0];
    //  设置属性
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.playerLayer.contentsScale = [UIScreen mainScreen].scale;
    //  播放
    //  [self.avPlayer play];
    [self.avPlayer pause];
    
    
    [self setupUI];
}

-(void)willMoveToSuperview:(UIView *)newSuperview
{
    if (self.superView == nil) {
        self.superView = newSuperview;
    }
    
}
-(void)setupUI
{
//    self.playerButton.backgroundColor = [UIColor blueColor];
//    self.bottomView.alpha = 0.1;
//    self.playTime.backgroundColor = [UIColor redColor];

    self.backgroundImage.backgroundColor = [UIColor blackColor];
    self.backgroundImage.alpha = 0.5;
    self.advanceOrRetreatView.backgroundColor = [UIColor blackColor];
    self.advanceOrRetreatView.alpha = 0.5;
    
    self.loadDataView.backgroundColor = [UIColor blackColor];
    self.loadDataView.alpha = 0.5;
    
    self.loadTurnView.color = [UIColor whiteColor];
    [self.loadTurnView startAnimating];
    
    //  记录当前frame
    if (self.tempFrame.size.width == 0) {
        self.tempFrame = self.bounds;
    }
    //  调取系统音量
    [self systemVolume];
    
    //  添加通知
    [self addNotification];
    
    //  slider 添加action
    [self configSliderAction];
    
    //  添加手势
    [self creatGesture];
    
    
    
}

#pragma mark - 设置frame
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.playerLayer.frame = self.layer.frame;
    

    CGFloat bottomViewW = [UIScreen mainScreen].bounds.size.width;
    CGFloat bottomViewH = 44;
    CGFloat bottomViewX = 0;
    CGFloat bottomViewY = self.frame.size.height - bottomViewH;
    self.bottomView.frame = CGRectMake(bottomViewX, bottomViewY,bottomViewW , bottomViewH);
    self.backgroundImage.frame = self.bottomView.bounds;
    //  播放按钮
    self.playerButton.frame = CGRectMake(2.5, 2.5, bottomViewH-5, bottomViewH-5);
    //  播放时间
    self.playTime.frame = CGRectMake(bottomViewH, 0, bottomViewH, bottomViewH);
    //  总时间
    self.allTimeLab.frame = CGRectMake(bottomViewW - bottomViewH * 2 - 2.5, 0, bottomViewH, bottomViewH);
    //  全屏
    self.fullScreenBtn.frame = CGRectMake(bottomViewW - bottomViewH, 0, bottomViewH - 5, bottomViewH - 5);
    
    //  slider
    CGFloat sliderX = CGRectGetMaxX(self.playTimeLab.frame);
    CGFloat sliderW = self.allTimeLab.frame.origin.x - sliderX;
    self.mySlider.frame = CGRectMake(sliderX, 0, sliderW, bottomViewH );
    
    //  快进快退
    self.advanceOrRetreatView.frame = CGRectMake(0, 0, 100, 50);
    self.advanceOrRetreatView.center = self.center;
    
    //  菊花
    self.loadDataView.frame = self.bounds;
    self.loadTurnView.frame =CGRectMake(0, 0, 50, 50);
    self.loadTurnView.center = self.loadDataView.center;

    
}
#pragma mark - 系统发送通知给self
- (void)addNotification {
    
    // 处理系设备旋转
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    //  接收屏幕旋转的通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil
     ];
    // app退到后台
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    // app进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterPlayGround)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
}
#pragma mark - 接受通知
- (void)onDeviceOrientationChange
{
    
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    switch (interfaceOrientation) {
            
        case UIInterfaceOrientationPortrait:
            //  修改为小屏幕
            [self changeSmallScreen];
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            
            [self changeSelfFrame2FullScreen];
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            [self changeSelfFrame2FullScreen];
            break;
            
        default:
            break;
    }
}
#pragma mark - 后台
- (void)appDidEnterBackground
{
    [self pause];
    self.isCallBack = YES;
}
#pragma mark- 前台
- (void)appDidEnterPlayGround
{
//    if (self.isCallBack) {
//        if (self.currentStatu == VideoPlayerStatePlay) {
//            [self play];
//            self.isCallBack = NO;
//        }
//    }
//    [self play];
}
#pragma mark- play
- (void)play {
    
    
    [self startTimer];
    self.playerButton.selected = YES;
    self.currentStatu = VideoPlayerStatePlay;
    [self.avPlayer play];
    
}
#pragma mark- pause
- (void)pause
{
    [self stopTimer];
    self.playerButton.selected = NO;
    self.currentStatu = VideoPlayerStatePause;
    [self.avPlayer pause];
}

#pragma mark- 开启定时器
- (void)startTimer
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:.2f target:self selector:@selector(updateTimeOnProgressAndTimeLabel) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

-(void)startAnotherTimer
{
    self.anotherTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(currentTimeShow) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.anotherTimer forMode:NSRunLoopCommonModes];
}
#pragma mark- 关闭定时器
- (void)stopTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

-(void)stopAnotherTimer
{
    [self.anotherTimer invalidate];
    self.anotherTimer = nil;
}
#pragma mark- 定时器调用的方法
- (void)updateTimeOnProgressAndTimeLabel {
    [self updateTimeOnProgress];
    [self updateTimeOnTimeLabel];
}

-(void)currentTimeShow
{
    NSTimeInterval currentTime = CMTimeGetSeconds(self.avPlayer.currentTime);
    self.playTimeLab.text = [self stringWithTime:currentTime];
}

#pragma mark- label显示
- (void)updateTimeOnTimeLabel
{

    NSTimeInterval currentTime = CMTimeGetSeconds(self.avPlayer.currentTime);
    if (!self.isClickSlider) {
        self.playTimeLab.text = [self stringWithTime:currentTime];
    }
    
    
    NSTimeInterval duration = CMTimeGetSeconds(self.avPlayer.currentItem.duration);
    self.allTimeLab.text = [self stringWithTime:duration];
    //  重复播放
    if (currentTime == duration) {
        [self pause];
        self.playTimeLab.text = @"00:00";
        self.allTimeLab.text = @"00:00";
        self.mySlider.value = 0;
        [self.avPlayer seekToTime:CMTimeMakeWithSeconds(0, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
}


- (NSString *)stringWithTime:(NSTimeInterval)time {
    NSInteger dMin = time / 60;
    NSInteger dSec = (NSInteger)time % 60;
    return [NSString stringWithFormat:@"%02ld:%02ld", dMin, dSec];
}

- (void)updateTimeOnProgress
{
    if (!self.isClickSlider) {
    self.mySlider.value = CMTimeGetSeconds(self.avPlayer.currentTime) / CMTimeGetSeconds(self.avPlayer.currentItem.duration);
    }
    

}
#pragma mark- 开始点击
- (void)progressSliderBegan:(UISlider *)slider
{

    //  点击了slider
    self.isClickSlider = YES;
    [self startAnotherTimer];
    
    //  添加快进的显示
    [self addSubview:self.advanceOrRetreatView];
    
}

- (void)progressSliderChange:(UISlider *)slider
{

}

- (void)progressSliderEnd:(UISlider *)slider
{
    //  停止定时器
    [self stopAnotherTimer];
    //  松开slider
    self.isClickSlider = NO;
    // 移除
    [self.advanceOrRetreatView removeFromSuperview];
    NSTimeInterval duration = CMTimeGetSeconds(self.avPlayer.currentItem.duration);
    NSTimeInterval currentTime = duration * slider.value;
    [self.avPlayer seekToTime:CMTimeMakeWithSeconds(currentTime, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self play];
}

#pragma mark - 小屏幕
- (void)changeSmallScreen {
    
    self.frame = self.tempFrame;
//    self.playerLayer.bounds = CGRectMake(0, 0, self.tempFrame.size.width, self.tempFrame.size.height);
    self.ifFullScreen = NO;
    self.fullScreenBtn.selected = NO;
    [self removeFromSuperview];
    [self.superView addSubview:self];

    
}
#pragma mark - 全屏计算
- (void)changeSelfFrame2FullScreen {
    
    self.bounds = [UIScreen mainScreen].bounds;//CGRectMake(0, 0, SCREENW, SCREENH);
    self.center = CGPointMake(SCREENW / 2, SCREENH / 2);
    self.playerLayer.bounds = CGRectMake(0, 0, SCREENW, SCREENH);
    self.playerLayer.position = CGPointMake(SCREENW / 2, SCREENH / 2);
    self.ifFullScreen = YES;
    self.fullScreenBtn.selected = YES;
    [self removeFromSuperview];
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    
}


#pragma mark- 播放或暂停
-(void)playerOrPause:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self play];
    }else
    {
        [self pause];
    }
    
}
#pragma mark- 全屏
-(void)clickActionFullScreen:(UIButton*)sender
{
    self.fullScreenBtn.selected = !self.fullScreenBtn.selected;
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:{
            [self interfaceOrientation:UIInterfaceOrientationLandscapeRight];
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            [self interfaceOrientation:UIInterfaceOrientationPortrait];
        }
            break;
        default:
            break;
    }
    NSLog(@"%d",sender.selected);


}
#pragma mark - 转横屏
- (void)interfaceOrientation:(UIInterfaceOrientation)orientation
{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = orientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
//    NSLog(@"%ld",[UIDevice currentDevice].orientation);
}
#pragma mark- 配置slider 的action
- (void)configSliderAction
{
    [self.mySlider addTarget:self action:@selector(progressSliderBegan:) forControlEvents:UIControlEventTouchDown];
    [self.mySlider addTarget:self action:@selector(progressSliderChange:) forControlEvents:UIControlEventValueChanged];
    
    [self.mySlider addTarget:self action:@selector(progressSliderEnd:) forControlEvents:UIControlEventTouchUpInside];
    [self.mySlider addTarget:self action:@selector(progressSliderEnd:) forControlEvents:UIControlEventTouchCancel];
    
}
#pragma mark- 创建手势
-(void)creatGesture
{
    //  创建轻点手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSCreenAction:)];
    
    tapGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapGesture];
    
    //  滑动手势
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(sliderOnScreenAction:)];
    
    [self addGestureRecognizer:panGesture];
}

#pragma mark- 手势实现方法
-(void)tapSCreenAction:(UITapGestureRecognizer *)tap
{
    if (tap.state == UIGestureRecognizerStateRecognized) {
        
        self.bottomView.hidden = !self.bottomView.hidden;
        
    }
}
-(void)sliderOnScreenAction:(UIPanGestureRecognizer *)pan
{
    CGPoint panPostion = [pan locationInView:self];
    CGPoint panVelocity = [pan velocityInView:self];
    
    //  判断是水平还是垂直位移
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{
            CGFloat X = fabs(panVelocity.x);
            CGFloat Y = fabs(panVelocity.y);
            if (X > Y) {
                //水平移动
                self.gestureDirection = GestureDirectionHorizontalMoved;
                [self progressSliderBegan:self.mySlider];
                
            }else if (X < Y){
                self.gestureDirection = GestureDirectionVerticalMoved;
                if (panPostion.x > self.bounds.size.width / 2) {
                    self.isAdjustVolume = YES;
                }else{
                    self.isAdjustVolume = NO;
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged:{
            switch (self.gestureDirection) {
                case GestureDirectionHorizontalMoved:{
                 
                    
                    
                    break;
                }
                case GestureDirectionVerticalMoved:
                    [self verticalMoved:panVelocity.y]; // 垂直移动方法只要y方向的值
                    NSLog(@"%f",panVelocity.y);
                    break;
                    
                default:
                    break;
            }
        }
            
            
        default:
            break;
    }
}
- (void)verticalMoved:(CGFloat)value
{
    if (self.isAdjustVolume) {
        // 更改系统的音量
        self.volumeSlider.value -= value / 1000;
    }else {
        //亮度
        [UIScreen mainScreen].brightness -= value / 10000;
//        NSString *brightness             = [NSString stringWithFormat:@"亮度%.0f%%",[UIScreen mainScreen].brightness/1.0*100];
//        self.tipsView.hidden      = NO;
//        self.tipsLabel.text        = brightness;
//        self.tipsImg.image = [UIImage imageNamed:@"Resources.bundle/Lightbulb"];
    }
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    
    if ([keyPath isEqualToString:@"loadedTimeRanges"]){
        
    }else if ([keyPath isEqualToString:@"status"]){
        if (playerItem.status == AVPlayerItemStatusReadyToPlay){
            NSLog(@"playerItem is ready");

            self.item = playerItem;
            
            [self.loadDataView removeFromSuperview];
        } else{
            NSLog(@"load break");
         
            // 岩石调用
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self playerMovieWithURL:self.url];
            });
            
        }
    }
}

-(void)systemVolume
{
    MPVolumeView *volumeView = [[MPVolumeView alloc]init];
    self.volumeSlider = nil;
    for (UIView *view in volumeView.subviews ) {
        if ([view isKindOfClass:NSClassFromString(@"MPVolumeSlider")]) {
            self.volumeSlider = (UISlider *)view;
            break;
        }
    }
    NSError *error;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    
    
}
@end
