//
//  FUFigureDecorationCollection.m
//  FUFigureView
//
//  Created by L on 2019/4/10.
//  Copyright © 2019 L. All rights reserved.
//

#import "FUFigureDecorationCollection.h"
#import "UIColor+FU.h"

@interface FUFigureDecorationCollection ()<UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) NSMutableDictionary *selectedDic ;
@end

@implementation FUFigureDecorationCollection

- (void)awakeFromNib {
	[super awakeFromNib];
	[self registerNib:[UINib nibWithNibName:@"FUFigureDecorationCell" bundle:nil] forCellWithReuseIdentifier:@"FUFigureDecorationCell"];
	
	self.dataSource = self ;
	self.delegate = self ;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FUAvatarEditedDoNotMethod:) name:FUAvatarEditedDoNot object:nil];
	
}

-(void)setCurrentType:(FUFigureDecorationCollectionType)currentType {
	_currentType = currentType ;
	[self reloadData];
	
	[self scrollCurrentToCenterWithAnimation:NO];
}

- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation {
	if ([self.selectedDic.allKeys containsObject:@(self.currentType)]) {
		NSInteger selectedIndex = [[self.selectedDic objectForKey:@(self.currentType)] integerValue];
		if (selectedIndex >= 0) {
			[self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:animation];
		}
	}
}

- (void)loadDecorationData {
	
	self.selectedDic = [NSMutableDictionary dictionaryWithCapacity:1];
	
	NSMutableArray *dataArray = [NSMutableArray arrayWithCapacity:1];
	NSMutableArray *selectedArray = [NSMutableArray arrayWithCapacity:1];
	
	NSArray *propertiesName = @[@"hairArray", @"faceArray", @"eyesArray", @"mouthArray", @"noseArray", @"beardArray", @"eyeBrowArray", @"eyeLashArray", @"hatArray", @"clothesArray",@"upperArray",@"lowerArray", @"shoesArray",@"decorationsArray"];
	for (NSString *name  in propertiesName) {
		NSArray *array = [self valueForKey:name];
		if (array) {
			[dataArray addObject:array];
			NSString *propertyName = [name substringToIndex:name.length - 5];
			NSString *item = [self valueForKey:propertyName];
			if (!item) {
				item = array[0] ;
			}
			NSMutableString * itemMutableString = [NSMutableString stringWithString:item];
			if ([itemMutableString containsString:@".bundle"]) {
				item = [itemMutableString stringByReplacingOccurrencesOfString:@".bundle" withString:@""];
			}
			[selectedArray addObject:item];
			NSLog(@"propertyName--------%@-----item--------%@",propertyName,item);
		}
	}
	
 	for (int i = 0 ; i < dataArray.count; i ++) {
		NSArray *array = [dataArray objectAtIndex:i] ;
		NSString *name = [selectedArray objectAtIndex:i];
		
		NSInteger index = -1 ;
		if ([array containsObject:name]) {
			index = [array indexOfObject:name];
		}
		
		[self.selectedDic setObject:@(index) forKey:@(i)];
		NSLog(@"index----：%d-----:i-----%d----name-----%@",index,i,name);
		if (self.currentType == (FUFigureDecorationCollectionType)i) {
			[self reloadData];
		}
	}
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return [self getCurrentDataArray].count ;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	FUFigureDecorationCell *cell = (FUFigureDecorationCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureDecorationCell" forIndexPath:indexPath];
	NSArray * subViews = cell.subviews;
	for (UIView * subV in subViews) {
		if ([subV isKindOfClass:[UILabel class]] ) {
			[subV removeFromSuperview];
		}
	}
	NSArray *dataArray = [self getCurrentDataArray];
	NSString *name = dataArray[indexPath.row] ;
	UIImage * image = [UIImage imageNamed:name];
	cell.imageView.image = image;
	
	NSInteger selectedIndex = [[self.selectedDic objectForKey:@(self.currentType)] integerValue] ;
	cell.layer.borderWidth = selectedIndex == indexPath.row ? 2.0 : 0.0 ;
	cell.layer.borderColor = selectedIndex == indexPath.row ? [UIColor colorWithHexColorString:@"4C96FF"].CGColor : [UIColor clearColor].CGColor ;
	
	return cell ;
}

-(void)recoverCollectionViewUI{
	[self setValue:nil forKey:@"face"];
	[self setValue:nil forKey:@"eyes"];
	[self setValue:nil forKey:@"mouth"];
	[self setValue:nil forKey:@"nose"];
	
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	
	NSInteger selectedIndex = [[self.selectedDic objectForKey:@(self.currentType)] integerValue] ;
	
	if (selectedIndex == indexPath.row
		&& indexPath.row != 0
		&& (self.currentType == 0 || self.currentType > 4)) {
		
		return ;
	}
	
	// 如果上衣、裤子则是不可以不选择的
	if (indexPath.row == 0 && (self.currentType == FUFigureDecorationCollectionTypeUpper || self.currentType == FUFigureDecorationCollectionTypeLower)) {
		return;
	}
    
    if (indexPath.row == 0 && self.currentType == FUFigureDecorationCollectionTypeClothes)
    {
        int oldClothIndex = [self.selectedDic[@(FUFigureDecorationCollectionTypeClothes)] intValue];
        if (oldClothIndex != 0) {
            // 如果之前穿的是套装，则选择默认的上衣+裤子
            self.lower = @"kuzi_chushi";
            [self.selectedDic setObject:@(1) forKey:@(FUFigureDecorationCollectionTypeLower)];
            
            self.clothes = @"clothes-noitem";
            [self.selectedDic setObject:@(0) forKey:@(FUFigureDecorationCollectionTypeClothes)];
            
            self.upper = @"shangyi_chushi";
            [self.selectedDic setObject:@(1) forKey:@(FUFigureDecorationCollectionTypeUpper)];
            
            if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedUpperItem:lowerItem:)]) {
                [self.mDelegate decorationCollectionDidSelectedUpperItem:self.upper  lowerItem:self.lower];
            }
            [self reloadData];
            [self scrollCurrentToCenterWithAnimation:YES];
            
            return;
        }
    }
    
	if (indexPath.row > 0) {
		switch (self.currentType) {
			case FUFigureDecorationCollectionTypeClothes:
				[self.selectedDic setObject:@(0) forKey:@(FUFigureDecorationCollectionTypeUpper)];
				[self.selectedDic setObject:@(0) forKey:@(FUFigureDecorationCollectionTypeLower)];
				self.upper = @"upper-noitem";
				self.lower = @"lower-noitem";
				
				break;
			case FUFigureDecorationCollectionTypeUpper:{
                int oldClothIndex = [self.selectedDic[@(FUFigureDecorationCollectionTypeClothes)] intValue];
                if (oldClothIndex > 0) {
                    // 如果之前穿的是套装，则选择默认的上衣+裤子
                    self.lower = @"kuzi_chushi";
                    [self.selectedDic setObject:@(1) forKey:@(FUFigureDecorationCollectionTypeLower)];
                    
                    self.clothes = @"clothes-noitem";
                    [self.selectedDic setObject:@(0) forKey:@(FUFigureDecorationCollectionTypeClothes)];
                    
                    self.upper = self.upperArray[indexPath.row];
                    [self.selectedDic setObject:@(indexPath.row) forKey:@(FUFigureDecorationCollectionTypeUpper)];
                    
                    if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedUpperItem:lowerItem:)]) {
                        [self.mDelegate decorationCollectionDidSelectedUpperItem:self.upper  lowerItem:self.lower];
                    }
                    [self reloadData];
                    [self scrollCurrentToCenterWithAnimation:YES];
                    
                    return;
                }
            }
			case FUFigureDecorationCollectionTypeLower:{
				int oldClothIndex = [self.selectedDic[@(FUFigureDecorationCollectionTypeClothes)] intValue];
				if (oldClothIndex > 0) {
                    // 如果之前穿的是套装，则选择默认的上衣+裤子
                    self.lower = self.lowerArray[indexPath.row];
                    [self.selectedDic setObject:@(indexPath.row) forKey:@(FUFigureDecorationCollectionTypeLower)];
                    
                    self.clothes = @"clothes-noitem";
                    [self.selectedDic setObject:@(0) forKey:@(FUFigureDecorationCollectionTypeClothes)];
                    
                    self.upper = @"shangyi_chushi";
                    [self.selectedDic setObject:@(1) forKey:@(FUFigureDecorationCollectionTypeUpper)];
                    
					if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedUpperItem:lowerItem:)]) {
                        [self.mDelegate decorationCollectionDidSelectedUpperItem:self.upper  lowerItem:self.lower];
					}
                    [self reloadData];
                    [self scrollCurrentToCenterWithAnimation:YES];
                    
                    return;
				}
			}
				break;
			default:
				break;
		}
	}
	[self.selectedDic setObject:@(indexPath.row) forKey:@(self.currentType)];
	[self reloadData];
	
	NSString *itemName = [[self getCurrentDataArray] objectAtIndex:indexPath.row];
	if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
		[self.mDelegate decorationCollectionDidSelectedItem:itemName index:indexPath.row decorationType:self.currentType];
	}
	
	[self scrollCurrentToCenterWithAnimation:YES];
}

- (NSArray *)getCurrentDataArray {
	
	NSArray *array ;
	switch (_currentType) {
		case FUFigureDecorationCollectionTypeHair:
			array = self.hairArray  ;
			break;
		case FUFigureDecorationCollectionTypeFace:
			array = self.faceArray  ;
			break;
		case FUFigureDecorationCollectionTypeEyes:
			array = self.eyesArray  ;
			break;
		case FUFigureDecorationCollectionTypeMouth:
			array = self.mouthArray  ;
			break;
		case FUFigureDecorationCollectionTypeNose:
			array = self.noseArray  ;
			break;
		case FUFigureDecorationCollectionTypeBeard:
			array = self.beardArray  ;
			break;
		case FUFigureDecorationCollectionTypeEyeBrow:
			array = self.eyeBrowArray  ;
			break;
		case FUFigureDecorationCollectionTypeEyeLash:
			array = self.eyeLashArray  ;
			break;
		case FUFigureDecorationCollectionTypeHat:
			array = self.hatArray  ;
			break;
		case FUFigureDecorationCollectionTypeClothes:
			array = self.clothesArray  ;
			break;
		case FUFigureDecorationCollectionTypeUpper:
			array = self.upperArray  ;
			break;
		case FUFigureDecorationCollectionTypeLower:
			array = self.lowerArray  ;
			break;
			
		case FUFigureDecorationCollectionTypeShoes:
			array = self.shoesArray  ;
			break;
		case FUFigureDecorationCollectionTypeDecorations:
			array = self.decorationsArray  ;
			break;
	}
	return array ;
}
// ==============================================根据指定名称滚动到相应图标==================================
-(void)FUAvatarEditedDoNotMethod:(NSNotification *)not{
	FUAvatarEditedDoModel * model = [not object];
	switch (model.type) {
		case Hair:
		{
			//	[self scrollToTheHair:model.obj];
			NSString * hairName = model.obj;
			hairName = [hairName stringByDeletingPathExtension];   // 如果有.bundle的后缀，则删除
			int index = [self.hairArray indexOfObject:hairName];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeHair)];
			if (self.currentType == FUFigureDecorationCollectionTypeHair){
				[self reloadData];
			}
			
			if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
				[self.mDelegate decorationCollectionDidSelectedItem:hairName index:index decorationType:FUFigureDecorationCollectionTypeHair];
			}
		}
			break;
		case Face:
		{
			//	[self scrollToTheHair:model.obj];
			NSString * faceName = model.obj;
			NSLog(@"faceName------%@",faceName);
			if ([faceName isEqual:[NSNull null]]) {
				faceName = @"捏脸";
			}
			int index = [self.faceArray indexOfObject:faceName];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeFace)];
			if (self.currentType == FUFigureDecorationCollectionTypeFace){
				[self reloadData];
			}
			if (![faceName isEqual:[NSNull null]]  && ![faceName isEqualToString:@"捏脸"]) {
				
				if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
					[self.mDelegate decorationCollectionDidSelectedItem:faceName index:index decorationType:FUFigureDecorationCollectionTypeFace];
				}
			}
		}
			break;
		case Eyes:
		{
			//	[self scrollToTheHair:model.obj];
			NSString * eyesName = model.obj;
			NSLog(@"eyesName------%@",eyesName);
			if ([eyesName isEqual:[NSNull null]]) {
				eyesName = @"捏脸";
			}
			int index = [self.eyesArray indexOfObject:eyesName];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeEyes)];
			if (self.currentType == FUFigureDecorationCollectionTypeEyes){
				[self reloadData];
			}
			if (![eyesName isEqual:[NSNull null]] && ![eyesName isEqualToString:@"捏脸"]) {
				if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
					[self.mDelegate decorationCollectionDidSelectedItem:eyesName index:index decorationType:FUFigureDecorationCollectionTypeEyes];
				}
			}
		}
			break;
		case Mouth:
		{
			//	[self scrollToTheHair:model.obj];
			NSString * mouthName = model.obj;
			NSLog(@"mouthName------%@",mouthName);
			if ([mouthName isEqual:[NSNull null]]) {
				mouthName = @"捏脸";
			}
			int index = [self.mouthArray indexOfObject:mouthName];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeMouth)];
			if (self.currentType == FUFigureDecorationCollectionTypeMouth){
				[self reloadData];
			}
			if (![mouthName isEqual:[NSNull null]]  && ![mouthName isEqualToString:@"捏脸"]) {
				if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
					[self.mDelegate decorationCollectionDidSelectedItem:mouthName index:index decorationType:FUFigureDecorationCollectionTypeMouth];
				}
			}
		}
			break;
			
		case Nose:
		{
			//	[self scrollToTheHair:model.obj];
			NSString * noseName = model.obj;
			NSLog(@"noseName------%@",noseName);
			if ([noseName isEqual:[NSNull null]]) {
				noseName = @"捏脸";
			}
			int index = [self.noseArray indexOfObject:noseName];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeNose)];
			if (self.currentType == FUFigureDecorationCollectionTypeNose){
				[self reloadData];
			}
			if (![noseName isEqual:[NSNull null]]  && ![noseName isEqualToString:@"捏脸"]) {
				if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
					[self.mDelegate decorationCollectionDidSelectedItem:noseName index:index decorationType:FUFigureDecorationCollectionTypeNose];
				}
			}
		}
			break;
			
		case Beard:
		{
			//	[self scrollToTheHair:model.obj];
			NSString * beardName = model.obj;
			NSLog(@"beardName------%@",beardName);
			if ([beardName isEqual:[NSNull null]]) {
				beardName = @"beard0";
			}
			int index = [self.beardArray indexOfObject:beardName];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeBeard)];
			if (self.currentType == FUFigureDecorationCollectionTypeBeard){
				[self reloadData];
			}
			if (![beardName isEqual:[NSNull null]]) {
				if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
					[self.mDelegate decorationCollectionDidSelectedItem:beardName index:index decorationType:FUFigureDecorationCollectionTypeBeard];
				}
			}
		}
			break;
		case Hat:
		{
			//	[self scrollToTheHair:model.obj];
			NSString * hatName = model.obj;
			NSLog(@"hatName------%@",hatName);
			if ([hatName isEqual:[NSNull null]]) {
				hatName = @"hat-noitem";
			}
			int index = [self.hatArray indexOfObject:hatName];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeHat)];
			if (self.currentType == FUFigureDecorationCollectionTypeHat){
				[self reloadData];
			}
			if (![hatName isEqual:[NSNull null]]) {
				if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
					[self.mDelegate decorationCollectionDidSelectedItem:hatName index:index decorationType:FUFigureDecorationCollectionTypeHat];
				}
			}
		}
			break;
		case Clothes:
		{
			NSString * clothesName = model.obj;
			if ([clothesName isEqual:[NSNull null]]) {
				clothesName = @"clothes-noitem";
			}
			NSLog(@"clothesName------%@",clothesName);
			int index = [self.clothesArray indexOfObject:clothesName];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeClothes)];
            

            [self.selectedDic setObject:@(0) forKey:@(FUFigureDecorationCollectionTypeLower)];
            [self.selectedDic setObject:@(0) forKey:@(FUFigureDecorationCollectionTypeUpper)];
    
			if (self.currentType == FUFigureDecorationCollectionTypeLower||self.currentType == FUFigureDecorationCollectionTypeUpper||self.currentType == FUFigureDecorationCollectionTypeClothes){
				[self reloadData];
			}
			if (![clothesName isEqual:[NSNull null]]) {
				if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
					[self.mDelegate decorationCollectionDidSelectedItem:clothesName index:index decorationType:FUFigureDecorationCollectionTypeClothes];
				}
			}
		}
			break;
		case Upper:
		{
			NSString * upperName = model.obj;
			if ([upperName isEqual:[NSNull null]]) {
				upperName = @"upper-noitem";
			}
			upperName = [upperName stringByDeletingPathExtension];   // 如果有.bundle的后缀，则删除
			NSLog(@"upperName------%@",upperName);
			int index = [self.upperArray indexOfObject:upperName];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeUpper)];
            [self.selectedDic setObject:@(0) forKey:@(FUFigureDecorationCollectionTypeClothes)];
			if (self.currentType == FUFigureDecorationCollectionTypeLower||self.currentType == FUFigureDecorationCollectionTypeUpper||self.currentType == FUFigureDecorationCollectionTypeClothes){
				[self reloadData];
			}
			if (![upperName isEqual:[NSNull null]]) {
				if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
					[self.mDelegate decorationCollectionDidSelectedItem:upperName index:index decorationType:FUFigureDecorationCollectionTypeUpper];
				}
			}
		}
			break;
		case Lower:
		{
			//	[self scrollToTheHair:model.obj];
			NSString * lowerName = model.obj;
			if ([lowerName isEqual:[NSNull null]]) {
				lowerName = @"lower-noitem";
			}
			lowerName = [lowerName stringByDeletingPathExtension];   // 如果有.bundle的后缀，则删除
			NSLog(@"lowerName------%@",lowerName);
			int index = [self.lowerArray indexOfObject:lowerName];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeLower)];
            [self.selectedDic setObject:@(0) forKey:@(FUFigureDecorationCollectionTypeClothes)];
			if (self.currentType == FUFigureDecorationCollectionTypeLower||self.currentType == FUFigureDecorationCollectionTypeUpper||self.currentType == FUFigureDecorationCollectionTypeClothes){
				[self reloadData];
			}
			if (![lowerName isEqual:[NSNull null]]) {
				if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
					[self.mDelegate decorationCollectionDidSelectedItem:lowerName index:index decorationType:FUFigureDecorationCollectionTypeLower];
				}
			}
		}
			break;
		case Shoes:
		{
			//	[self scrollToTheHair:model.obj];
			NSString * shoesName = model.obj;
			if ([shoesName isEqual:[NSNull null]]) {
				shoesName = @"shoes-noitem";
			}
			shoesName = [shoesName stringByDeletingPathExtension];   // 如果有.bundle的后缀，则删除
			NSLog(@"shoesName------%@",shoesName);
			int index = [self.shoesArray indexOfObject:shoesName];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeShoes)];
			if (self.currentType == FUFigureDecorationCollectionTypeShoes){
				[self reloadData];
			}
			if (![shoesName isEqual:[NSNull null]]) {
				if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
					[self.mDelegate decorationCollectionDidSelectedItem:shoesName index:index decorationType:FUFigureDecorationCollectionTypeShoes];
				}
			}
		}
			break;
		case Decorations:
		{
			//	[self scrollToTheHair:model.obj];
			NSString * decorationsName = model.obj;
			if ([decorationsName isEqual:[NSNull null]]) {
				decorationsName = @"decorations-noitem";
			}
			decorationsName = [decorationsName stringByDeletingPathExtension];   // 如果有.bundle的后缀，则删除
			NSLog(@"decorationsName------%@",decorationsName);
			int index = [self.decorationsArray indexOfObject:decorationsName];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeDecorations)];
			if (self.currentType == FUFigureDecorationCollectionTypeDecorations){
				[self reloadData];
			}
			if (![decorationsName isEqual:[NSNull null]]) {
				if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
					[self.mDelegate decorationCollectionDidSelectedItem:decorationsName index:index decorationType:FUFigureDecorationCollectionTypeDecorations];
				}
			}
		}
			break;
        case UpperAndlower:
            {
                //    [self scrollToTheHair:model.obj];
                NSString * lowerName = [model.obj valueForKey:@"lower"];
                if ([lowerName isEqual:[NSNull null]]) {
                    lowerName = @"lower-noitem";
                }
                lowerName = [lowerName stringByDeletingPathExtension];   // 如果有.bundle的后缀，则删除
                NSLog(@"lowerName------%@",lowerName);
                
                NSInteger indexLower = [self.lowerArray indexOfObject:lowerName];
                [self.selectedDic setObject:@(indexLower) forKey:@(FUFigureDecorationCollectionTypeLower)];
                
                
                NSString * upperName = [model.obj valueForKey:@"upper"];
                if ([upperName isEqual:[NSNull null]]) {
                    upperName = @"upper-noitem";
                }
                upperName = [upperName stringByDeletingPathExtension];   // 如果有.bundle的后缀，则删除
                NSLog(@"upperName------%@",upperName);
                NSInteger indexUpper = [self.upperArray indexOfObject:upperName];
                [self.selectedDic setObject:@(indexUpper) forKey:@(FUFigureDecorationCollectionTypeUpper)];
                
                [self.selectedDic setObject:@(0) forKey:@(FUFigureDecorationCollectionTypeClothes)];
                
                if (self.currentType == FUFigureDecorationCollectionTypeLower||self.currentType == FUFigureDecorationCollectionTypeUpper||self.currentType == FUFigureDecorationCollectionTypeClothes){
                    [self reloadData];
                }
        
                if (![lowerName isEqual:[NSNull null]]) {
                    if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedUpperItem:lowerItem:)]) {
                        [self.mDelegate decorationCollectionDidSelectedUpperItem:upperName lowerItem:lowerName];
                    }
                }
            }
                break;
			
		default:
			break;
	}
}
-(void)scrollToTheHair:(NSString*)hair{
	NSUInteger index = [self.hairArray indexOfObject:hair];
	[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeHair)];
	[self reloadData];
}
-(void)dealloc{
	NSLog(@"FUFigureDecorationCollection销毁了----------");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

@implementation FUFigureDecorationCell
- (void)awakeFromNib {
	[super awakeFromNib];
	self.layer.masksToBounds = YES ;
	self.layer.cornerRadius = 8.0 ;
}
@end
