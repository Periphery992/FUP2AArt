//
//  FUARFilterController.m
//  FUP2A
//
//  Created by L on 2018/8/10.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUARFilterController.h"
#import "FUOpenGLView.h"
#import "FUCamera.h"
#import "FUManager.h"


@interface FUARFilterController ()<
FUCameraDelegate,
FUARFilterViewDelegate
>
{
	BOOL frontCamera ;
	BOOL avatarChanged;
}
@property (nonatomic, strong) FUCamera *camera ;
@property (weak, nonatomic) IBOutlet FUOpenGLView *renderView;


@property (weak, nonatomic) IBOutlet UIButton *photoBtn;
@property (nonatomic, strong) FUAvatar *commonAvatar;    //  记录进入人体追踪之前的avatar，当从追踪界面返回时，继续渲染这个 avatar
@property (nonatomic, strong) FUAvatar *currentAvatar;    // 当前选择的AR追踪 Avatar

@end

@implementation FUARFilterController

- (BOOL)prefersStatusBarHidden{
	return YES;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
	self.currentAvatar = avatar ;
	self.commonAvatar = avatar;
	[self.filterView selectedModeWith:self.currentAvatar];
	[[FUManager shareInstance] setMaxFaceNum:1];
//	[[FUManager shareInstance] reloadRenderAvatarInARModeInSameController:avatar];
	
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClick:)];
	[self.renderView addGestureRecognizer:tapGesture];
	
	CGAffineTransform trans0 = CGAffineTransformMakeScale(0.68, 0.68) ;
	CGAffineTransform trans1 = CGAffineTransformMakeTranslation(0, -80) ;
	self.photoBtn.transform = CGAffineTransformConcat(trans0, trans1) ;
	self.filterView.delegate = self ;
	// 添加进入和退出后台的监听
	[self addObserver];
}
-(void)setIsShow:(BOOL)isShow{
	_isShow = isShow;
	if (isShow) {
		// 1.即将进入AR滤镜，加载处理头发的道具
		[[FUManager shareInstance] bindHairMask];
		// 2.解绑定身体、上衣、裤子、鞋子资源，只保留头部的一些素材
	    [[FUManager shareInstance] reloadRenderAvatarInARModeInSameController:self.currentAvatar];
	    // 3.设置AR滤镜的controller句柄为arItems[0]
		[[FUManager shareInstance] enterARMode];
		// 4.去除背景道具
		[[FUManager shareInstance] reloadBackGroundAndBindToController:nil];
		// 5.向nama设置enter_ar_mode为1，进入AR滤镜模式
		[self.currentAvatar enterARMode];
		[self.camera startCapture];
	}else{
	    // 离开AR滤镜，删除处理头发的道具
	    [[FUManager shareInstance] destoryHairMask];
		[self.camera stopCapture];
		[self.currentAvatar quitARMode];
		NSString *filterName = @"noitem";
		[self ARFilterViewDidSelectedARFilter:filterName];
	}
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
}
- (IBAction)onCameraChange:(id)sender {
	fuOnCameraChange();
	self.camera.shouldMirror = !self.camera.shouldMirror ;
	[self.camera changeCameraInputDeviceisFront:!self.camera.isFrontCamera];
	
}
- (IBAction)backAction:(id)sender {
	// 离开AR滤镜，删除处理头发的道具
	[[FUManager shareInstance] destoryHairMask];
	[self.camera stopCapture];
	[self.currentAvatar quitARMode];
	[[FUManager shareInstance] reloadRenderAvatarInSameController:self.commonAvatar];
	[self.commonAvatar  loadStandbyAnimation];
	
	
	[self.commonAvatar resetScaleToSmallBody];
	[self.navigationController popViewControllerAnimated:NO];
	NSString *filterName = @"noitem";
	[self ARFilterViewDidSelectedARFilter:filterName];
}





/**
 FUCameraDelegate的代理方法，用来输出相机CMSampleBufferRef 对象
 
 @param sampleBuffer sampleBuffer相机输出的buffer
 */
-(void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
	
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) ;
	int h = (int)CVPixelBufferGetHeight(pixelBuffer);
	int w = (int)CVPixelBufferGetWidth(pixelBuffer);
	if (self.camera.isFrontCamera) {
		CVPixelBufferRef mirrored_pixel = [[FUManager shareInstance] dealTheFrontCameraPixelBuffer:pixelBuffer];
		[[FUManager shareInstance] renderARFilterItemWithBuffer:mirrored_pixel];
		
		[self.renderView displayPixelBuffer:mirrored_pixel withLandmarks:nil count:0 Mirr:NO];
		CVPixelBufferRelease(mirrored_pixel);
	}else{
		[[FURenderer shareRenderer] setInputCameraMatrix:0 flip_y:0 rotate_mode:0];
		[[FUManager shareInstance] renderARFilterItemWithBuffer:pixelBuffer];
		[self.renderView displayPixelBuffer:pixelBuffer withLandmarks:nil count:0 Mirr:NO];
	}
}

#pragma mark ---- FUARFilterViewDelegate
-(void)ARFilterViewDidSelectedAvatar:(FUAvatar *)avatar {
	avatarChanged = YES;
	[self.currentAvatar quitTrackBodyMode];
	[[FUManager shareInstance] reloadRenderAvatarInARModeInSameController:avatar];
	self.currentAvatar = avatar;
}

// 点击滤镜
- (void)ARFilterViewDidSelectedARFilter:(NSString *)filterName {
	NSString *filterPath = [[NSBundle mainBundle] pathForResource:filterName ofType:@"bundle"];
	[[FUManager shareInstance] reloadARFilterWithPath:filterPath];
}

- (void)ARFilterViewDidShowTopView:(BOOL)show {
	if (show) {
		
		CGAffineTransform trans0 = CGAffineTransformMakeScale(0.68, 0.68) ;
		CGAffineTransform trans1 = CGAffineTransformMakeTranslation(0, -80) ;
		[UIView animateWithDuration:0.35 animations:^{
			self.photoBtn.transform = CGAffineTransformConcat(trans0, trans1) ;
		}];
	}else {
		[UIView animateWithDuration:0.35 animations:^{
			self.photoBtn.transform = CGAffineTransformIdentity;
		}];
	}
}

- (IBAction)takePhoto:(UIButton *)sender {
	[self.camera takePhoto:YES];
	fuOnCameraChange();
}

- (void)tapClick:(UITapGestureRecognizer *)gesture {
	
}

-(FUCamera *)camera {
	if (!_camera) {
		_camera = [[FUCamera alloc] init];
		_camera.delegate = self ;
		_camera.shouldMirror = NO ;
		[_camera changeCameraInputDeviceisFront:YES];
		frontCamera = YES ;
	}
	return _camera ;
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
	self.filterView.superview.hidden = !self.filterView.superview.hidden;
	[self ARFilterViewDidShowTopView:!self.filterView.superview.hidden];
}


#pragma mark --- Observer

- (void)addObserver{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}


- (void)willResignActive    {
	
	if (self.navigationController.visibleViewController == self) {
		[self.camera stopCapture];

	}
}

- (void)willEnterForeground {
	
	if (self.navigationController.visibleViewController == self) {
		[self.camera startCapture];
	}
}

- (void)didBecomeActive {
	
	if (self.navigationController.visibleViewController == self) {
		[self.camera startCapture];
	}
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}
-(void)dealloc{
	NSLog(@"FUARFilterController-----------销毁了");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
