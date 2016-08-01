//
//  GuestViewController.m
//  RTMPCDemo
//
//  Created by jianqiangzhang on 16/7/21.
//  Copyright © 2016年 EricTao. All rights reserved.
//

#import "GuestViewController.h"
#import <RTMPCHybirdEngine/RTMPCGuestKit.h>
#import "ASHUD.h"


@interface GuestViewController ()<RTMPCGuestRtmpDelegate, RTMPCGuestRtcDelegate> {
    bool use_cap_;
}
@property (nonatomic, strong) UIView *mainView;  // 主屏幕
@property (nonatomic, strong) UIButton *handupButton;
@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic, strong) RTMPCGuestKit *guestKit;

@property (nonatomic, strong) NSMutableArray *remoteArray;

@end

@implementation GuestViewController
- (void)dealloc {
    if (self.guestKit) {
        self.guestKit = nil;
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES];
    self.view.backgroundColor = [UIColor whiteColor];
    self.remoteArray = [[NSMutableArray alloc] initWithCapacity:3];
    
    [self.view addSubview:self.mainView];
    [self.view addSubview:self.handupButton];
    [self.view addSubview:self.closeButton];
    
    self.guestKit = [[RTMPCGuestKit alloc] initWithDelegate:self];
    self.guestKit.rtc_delegate = self;
    [self.guestKit StartRtmpPlay:self.livingItem.rtmp_url andRender:self.mainView];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"hostID",@"hosterId",self.livingItem.rtmp_url,@"rtmp_url",self.livingItem.hls_url,@"hls_url",[self getTopName],@"topic",self.livingItem.andyrtcId,@"anyrtcId", nil];
    
    NSString *jsonString = [self JSONTOString:dict];
    
    [self.guestKit JoinRTCLine:self.livingItem.andyrtcId andCustomID:@"test_ios_plul" andCustomName:@"Eric_Guest" andUserData:jsonString ];
}
- (void)viewDidUnload
{
    [self.guestKit clear];
}
#pragma mark - private method
- (NSString*)JSONTOString:(id)obj {
    NSString *jsonString = nil;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}
- (NSString*)getTopName {
    NSArray *array = @[@"测试Anyrtc",@"Anyrtc真心效果好",@"欢迎用Anyrtc",@"视频云提供商DYNC"];
    return [array objectAtIndex:(int)arc4random()%(array.count-1)];
}

#pragma mark -  RTMPCGuestRtmpDelegate
// rtmp 连接成功
- (void)OnRtmplayerOK
{
    NSLog(@"OnRtmplayerOK");
}
// rtmp 播放状态  cacheTime:当前延迟时间 curBitrate:当期码率大小
- (void)OnRtmplayerStatus:(int) cacheTime withBitrate:(int) curBitrate
{
    
}
// rtmp 播放器缓存时间
- (void)OnRtmplayerCache:(int) time
{
    
}
// rtmp 播放器关闭
- (void)OnRtmplayerClosed:(int) errcode
{
    
}
#pragma mark - RTMPCGuestRtcDelegate
// 加入RTC
- (void)OnRTCJoinLineResult:(int) code/*0:OK */ withReason:(NSString*)strReason
{
    NSLog(@"OnRTCJoinLineResult: %d", code);
    if (code != 0) {
        if (code == 101) {
            [ASHUD showHUDWithCompleteStyleInView:self.view content:@"主播还未开启直播" icon:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.navigationController popViewControllerAnimated:YES];
            });
        }
    }
}
// 自己请求主播连麦得到的回复回调
- (void)OnRTCApplyLineResult:(int) code/*0:OK */
{
    if(code == 0) {
        if(!use_cap_) {
            use_cap_ = true;
            // 找一个view
            UIView *videoView = [self getVideoViewWithStrID:@"MEVIDEOVIEW"];
            UIButton *cButton = [UIButton buttonWithType:UIButtonTypeCustom];
            cButton.frame = CGRectMake(CGRectGetWidth(videoView.frame)-30,10, 20, 20);
            [cButton addTarget:self action:@selector(cButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
            [cButton setImage:[UIImage imageNamed:@"close_preview"] forState:UIControlStateNormal];
            [videoView addSubview:cButton];
            
            [self.view addSubview:videoView];
            [self.guestKit SetVideoCapturer:videoView andUseFront:YES];
        }
    }else{
        [ASHUD showHUDWithCompleteStyleInView:self.view content:@"主播拒绝了你的连麦请求" icon:nil];
        self.handupButton.hidden = NO;
    }
}
// 其他用户连线了主播
- (void)OnRTCOtherLineOpen:(NSString*)strLivePeerID withCustomID:(NSString*)strCustomID withUserData:(NSString*)strUserData
{
    
}
// 其他用户离开了连麦互动
- (void)OnRTCOtherLineClose:(NSString*)strLivePeerID
{
    for (int i=0; i<self.remoteArray.count; i++) {
        NSDictionary *dict = [self.remoteArray objectAtIndex:i];
        if ([[dict.allKeys firstObject] isEqualToString:strLivePeerID]) {
            UIView *videoView = [dict objectForKey:strLivePeerID];
            [videoView removeFromSuperview];
            [self.remoteArray removeObjectAtIndex:i];
            [self layout:i];
            break;
        }
    }
}
// 主播关闭了你的连线（通->关）
- (void)OnRTCHangupLine
{
    // 主播挂断你的连线
    use_cap_ = NO;
    self.handupButton.hidden = NO;
    for (int i=0;i<self.remoteArray.count;i++) {
        NSDictionary *dict = [self.remoteArray objectAtIndex:i];
        if ([[dict.allKeys firstObject] isEqualToString:@"MEVIDEOVIEW"]) {
            UIView *videoView = [dict objectForKey:@"MEVIDEOVIEW"];
            [videoView removeFromSuperview];
            [self.remoteArray removeObjectAtIndex:i];
            [self layout:i];
            break;
        }
    }
    // 清空自己摄像头~
    [self.guestKit HangupRTCLine];
    
}
// RTC 关闭
- (void)OnRTCLineLeave:(int) code/*0:OK */ withReason:(NSString*)strReason
{
    // 主播离开了
    [ASHUD showHUDWithCompleteStyleInView:self.view content:@"主播关闭了直播" icon:nil];
    if (self.guestKit) {
        [self.guestKit clear];
        self.guestKit = nil;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self.navigationController popViewControllerAnimated:YES];
    });
}
// 视频显示
- (void)OnRTCOpenVideoRender:(NSString*)strLivePeerID {
    NSLog(@"OnRTCOpenVideoRender:%@",strLivePeerID);
    UIView *video = [self getVideoViewWithStrID:strLivePeerID];
    [self.view addSubview:video];
    [self.guestKit SetRTCVideoRender:strLivePeerID andRender:video];
}
// 视频离开
- (void)OnRTCCloseVideoRender:(NSString*)strLivePeerID {
    NSLog(@"OnRTCCloseVideoRender:%@",strLivePeerID);
    for (int i=0; i<self.remoteArray.count; i++) {
        NSDictionary *dict = [self.remoteArray objectAtIndex:i];
        if ([[dict.allKeys firstObject] isEqualToString:strLivePeerID]) {
            UIView *videoView = [dict objectForKey:strLivePeerID];
            [videoView removeFromSuperview];
            [self.remoteArray removeObjectAtIndex:i];
            [self layout:i];
            break;
        }
    }
}

// 普通消息
- (void)OnRTCUserMessage:(NSString*)nsCustomId withCustomName:(NSString*)nsCustomName withContent:(NSString*)nsContent {
    
}
// 弹幕
- (void)OnRTCUserBarrage:(NSString*)nsCustomId withCustomName:(NSString*)nsCustomName withContent:(NSString*)nsContent {
    
}
// 在线人数
- (void)OnRTCMemberListWillUpdate:(int)nTotalMember {
    
}
// 人员信息
- (void)OnRTCMember:(NSString*)nsCustomId withUserData:(NSString*)nsUserData {
    
}

- (void)OnRTCMemberListUpdateDone {
    
}


#pragma mark - button events

- (void)pullButtonEvent:(UIButton*)sender {
    sender.selected = !sender.selected;
    // 开始拉流
    use_cap_ = false;
    [self.guestKit ApplyRTCLine:@"Hello"];
    self.handupButton.hidden = YES;
}
- (void)closeButtonEvent:(UIButton*)sender {
    if (self.guestKit != nil) {
        [self.guestKit clear];
        self.guestKit = nil;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
    });
    
}
- (void)cButtonEvent:(UIButton*)sender {
    if (self.guestKit) {
        [self.guestKit HangupRTCLine];
        use_cap_ = NO;
        self.handupButton.hidden = NO;
        for (int i=0;i<self.remoteArray.count;i++) {
            NSDictionary *dict = [self.remoteArray objectAtIndex:i];
            if ([[dict.allKeys firstObject] isEqualToString:@"MEVIDEOVIEW"]) {
                UIView *videoView = [dict objectForKey:@"MEVIDEOVIEW"];
                [videoView removeFromSuperview];
                [self.remoteArray removeObjectAtIndex:i];
                [self layout:i];
                break;
            }
        }
    }
}

- (void)layout:(int)index {
    switch (index) {
        case 0:
            for (int i=0; i<self.remoteArray.count; i++) {
                NSDictionary *dict = [self.remoteArray objectAtIndex:i];
                UIView *videoView = [dict.allValues firstObject];
                videoView.frame = CGRectMake(videoView.frame.origin.x, CGRectGetHeight(self.view.frame)-(i+1)*videoView.frame.size.height, videoView.frame.size.width, videoView.frame.size.height);
            }
            break;
        case 1:
            if (self.remoteArray.count==2) {
                NSDictionary *dict = [self.remoteArray objectAtIndex:1];
                UIView *videoView = [dict.allValues firstObject];
                videoView.frame = CGRectMake(videoView.frame.origin.x, CGRectGetHeight(self.view.frame)-(2)*videoView.frame.size.height, videoView.frame.size.width, videoView.frame.size.height);
            }
            break;
        case 2:
            
            break;
            
        default:
            break;
    }
}

#pragma mark - get
- (UIView*)mainView {
    if (!_mainView) {
        _mainView = [[UIView alloc] init];
        _mainView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
    }
    return _mainView;
}

- (UIView*)getVideoViewWithStrID:(NSString*)publishID {
    NSInteger num = self.remoteArray.count;
    CGFloat videoHeight = CGRectGetHeight(self.view.frame)/4;
    CGFloat videoWidth = videoHeight*3/4;
    
    UIView *pullView;
    switch (num) {
        case 0:
            pullView = [[UIView alloc] init];
            pullView.frame = CGRectMake(CGRectGetWidth(self.view.frame)-videoWidth, 3*videoHeight, videoWidth, videoHeight);
            pullView.layer.borderColor = [UIColor grayColor].CGColor;
            pullView.layer.borderWidth = .5;
            break;
        case 1:
            pullView = [[UIView alloc] init];
            pullView.frame = CGRectMake(CGRectGetWidth(self.view.frame)-videoWidth, 2*videoHeight, videoWidth, videoHeight);
            pullView.layer.borderColor = [UIColor grayColor].CGColor;
            pullView.layer.borderWidth = .5;
            break;
        case 2:
            pullView = [[UIView alloc] init];
            pullView.frame = CGRectMake(CGRectGetWidth(self.view.frame)-videoWidth, videoHeight, videoWidth, videoHeight);
            pullView.layer.borderColor = [UIColor grayColor].CGColor;
            pullView.layer.borderWidth = .5;
            break;
            
        default:
            break;
    }
    
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:pullView,publishID, nil];
    [self.remoteArray addObject:dict];
    return pullView;
}



- (UIButton*)closeButton {
    if(!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:[UIImage imageNamed:@"close_preview"] forState:UIControlStateNormal];
        [_closeButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
        _closeButton.frame = CGRectMake(CGRectGetMaxX(self.view.frame)-60, 20,40,40);
    }
    return _closeButton;
}
- (UIButton*)handupButton {
    if (!_handupButton) {
        _handupButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_handupButton setImage:[UIImage imageNamed:@"btn_hands_normal"] forState:UIControlStateNormal];
        [_handupButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_handupButton addTarget:self action:@selector(pullButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
        _handupButton.frame = CGRectMake(CGRectGetMinX(self.closeButton.frame)-60, 20, 40,40);
    }
    return _handupButton;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end