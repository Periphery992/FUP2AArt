//
//  FUHomeBarView.m
//  FUP2A
//
//  Created by L on 2018/10/24.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUHomeBarView.h"
#import "FUHomeBarBtn.h"
#import "UIColor+FU.h"
#import "FUManager.h"
#import "FUTool.h"

@interface FUHomeBarView ()<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,UIGestureRecognizerDelegate>
{
    NSInteger selectedIndex ;
    
    CGFloat preScale; // 捏合比例
}
@property (weak, nonatomic) IBOutlet FUHomeBarBtn *modeBtn;
@property (weak, nonatomic) IBOutlet FUHomeBarBtn *editBtn;
@property (weak, nonatomic) IBOutlet FUHomeBarBtn *arBtn;

@property (weak, nonatomic) IBOutlet UICollectionView *modeCollection;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@end

@implementation FUHomeBarView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    UIPinchGestureRecognizer *pinchGesture2 = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomAvatar:)];
    [self addGestureRecognizer:pinchGesture2];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClick:)];
    [self addGestureRecognizer:tapGesture];
    tapGesture.delegate = self ;
    [pinchGesture2 requireGestureRecognizerToFail:tapGesture];
    
    self.modeCollection.dataSource = self ;
    self.modeCollection.delegate = self ;
    
    selectedIndex = 2 ;
    [self.modeCollection reloadData];
    
    CGFloat height = [[FUTool getPlatformType] isEqualToString:@"iPhone X"] ? self.frame.size.height + 34 : self.frame.size.height;
    self.modeCollection.transform = CGAffineTransformMakeTranslation(0, height) ;
    self.modeCollection.hidden = YES ;
}

// Avatar 缩放
- (void)zoomAvatar:(UIPinchGestureRecognizer *)gesture {
    float curScale = gesture.scale;
    
    if (curScale < 1.0) {
        curScale = - fabsf(1 / curScale - 1);
    }else   {
        curScale -= 1;
    }
    
    float ds = curScale - preScale;
    preScale = curScale;
    
    if ([self.delegate respondsToSelector:@selector(homeBarViewReceiveZoom:)]) {
        [self.delegate homeBarViewReceiveZoom:ds];
    }
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        preScale = 0.0;
    }
}

// 页面点击效果
- (void)tapClick:(UITapGestureRecognizer *)gesture {
    [self hidHomeBarTopView];
    if ([self.delegate respondsToSelector:@selector(homeBarViewDidHiddenTopView)]) {
        [self.delegate homeBarViewDidHiddenTopView];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isDescendantOfView:self.modeCollection]) {
        return NO ;
    }
    return YES ;
}

// 模型
- (IBAction)modeBtnSelectAction:(FUHomeBarBtn *)sender {
    sender.selected = !sender.selected ;
    
    [self showModeCollection:sender.isSelected];
}

- (void)showModeCollection:(BOOL)show {
    if (show) {
        if ([self.delegate respondsToSelector:@selector(homeBarViewShouldShowTopView:)]) {
            [self.delegate homeBarViewShouldShowTopView:YES];
        }
        self.modeCollection.hidden = NO ;
        self.bottomView.hidden = YES ;
        [UIView animateWithDuration:0.35 animations:^{
            self.modeCollection.transform = CGAffineTransformIdentity ;
        }completion:^(BOOL finished) {
            if (!self.modeBtn.isSelected) {
                self.modeBtn.selected = YES ;
            }
        }];
    }else {
        
        if ([self.delegate respondsToSelector:@selector(homeBarViewShouldShowTopView:)]) {
            [self.delegate homeBarViewShouldShowTopView:NO];
        }
        CGFloat height = [[FUTool getPlatformType] isEqualToString:@"iPhone X"] ? self.frame.size.height + 34 : self.frame.size.height;
        [UIView animateWithDuration:0.35 animations:^{
            self.modeCollection.transform = CGAffineTransformMakeTranslation(0, height) ;
        } completion:^(BOOL finished) {
            self.modeCollection.hidden = YES ;
            self.bottomView.hidden = NO ;
            if (self.modeBtn.isSelected) {
                self.modeBtn.selected = NO ;
            }
        }];
    }
}

// 形象/ AR 滤镜
- (IBAction)editBtnSelectAction:(FUHomeBarBtn *)sender {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(homeBarSelectedActionWithAR:)]) {
        [self.delegate homeBarSelectedActionWithAR:sender == self.arBtn];
    }
}

// 隐藏上半部
- (void)hidHomeBarTopView {
    [self showModeCollection:NO];
}

// 刷新模型页
- (void)reloadModeData {
    
    selectedIndex = [[FUManager shareInstance].avatars indexOfObject:[FUManager shareInstance].currentAvatar] + 2;
    [self.modeCollection reloadData];
}
#pragma mark ---   UICollectionViewDataSource && UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [FUManager shareInstance].avatars.count + 2;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FUHomeBarCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FUHomeBarCell" forIndexPath:indexPath];
    
    
    UIImage *image ;
    switch (indexPath.row) {
        case 0:{
            image = [UIImage imageNamed:@"homeBar-add"];
        }
            break;
        case 1:{
            image = [UIImage imageNamed:@"homeBar-delete"];
        }
            break ;
        default:{
            FUAvatar *avatar = [FUManager shareInstance].avatars[indexPath.row - 2];
            image = [UIImage imageWithContentsOfFile:avatar.imagePath];
        }
            break;
    }
    cell.imageView.image = image ;
    cell.showBorder = selectedIndex == indexPath.row ;
    
    return cell ;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.row) {
        case 0:{
            if (self.delegate && [self.delegate respondsToSelector:@selector(homeBarViewShouldCreateAvatar)]) {
                [self.delegate homeBarViewShouldCreateAvatar];
            }
        }
            break;
        case 1:{
            if (self.delegate && [self.delegate respondsToSelector:@selector(homeBarViewShouldDeleteAvatar)]) {
                [self.delegate homeBarViewShouldDeleteAvatar];
            }
        }
            break;
            
        default:{
            
            if (indexPath.row == selectedIndex) {
                return ;
            }
            selectedIndex = indexPath.row ;
            [collectionView reloadData];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                FUAvatar *avatar = [FUManager shareInstance].avatars[indexPath.row - 2];
                if (self.delegate && [self.delegate respondsToSelector:@selector(homeBarViewDidSelectedAvatar:)]) {
                    [self.delegate homeBarViewDidSelectedAvatar:avatar];
                }
                //            });
            });
        }
            break;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.row) {
        case 0:{
            FUHomeBarCell *cell = (FUHomeBarCell *)[collectionView cellForItemAtIndexPath:indexPath];
            cell.imageView.image = [UIImage imageNamed:@"homeBar-add-pressed"];
        }
            break;
        case 1:{
            FUHomeBarCell *cell = (FUHomeBarCell *)[collectionView cellForItemAtIndexPath:indexPath];
            cell.imageView.image = [UIImage imageNamed:@"homeBar-delete-pressed"];
        }
            
        default:
            break;
    }
}
- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.row) {
        case 0:{
            FUHomeBarCell *cell = (FUHomeBarCell *)[collectionView cellForItemAtIndexPath:indexPath];
            cell.imageView.image = [UIImage imageNamed:@"homeBar-add"];
        }
            break;
        case 1:{
            FUHomeBarCell *cell = (FUHomeBarCell *)[collectionView cellForItemAtIndexPath:indexPath];
            cell.imageView.image = [UIImage imageNamed:@"homeBar-delete"];
        }
            
        default:
            break;
    }
}
@end

@implementation FUHomeBarCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.masksToBounds = YES ;
    self.layer.cornerRadius = 8.0 ;
    self.imageView.layer.masksToBounds = YES ;
    self.imageView.layer.cornerRadius = 8.0 ;
    self.showBorder = NO ;
}

-(void)setShowBorder:(BOOL)showBorder {
    _showBorder = showBorder ;
    if (showBorder) {
        self.layer.borderColor = [UIColor colorWithHexColorString:@"4C96FF"].CGColor;
        self.layer.borderWidth = 2.0 ;
        self.imageView.layer.borderColor = [UIColor whiteColor].CGColor;
        self.imageView.layer.borderWidth = 2.0 ;
    }else {
        self.layer.borderColor = [UIColor clearColor].CGColor;
        self.layer.borderWidth = 0.0 ;
        self.imageView.layer.borderColor = [UIColor clearColor].CGColor;
        self.imageView.layer.borderWidth = 0.0 ;
    }
}

@end
