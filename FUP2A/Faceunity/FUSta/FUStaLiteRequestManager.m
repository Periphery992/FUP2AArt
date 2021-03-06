//
//  FUStaLiteRequestManager.m
//  FUStaLiteDemo
//
//  Created by Lechech on 2019/10/10.
//  Copyright © 2019 ly-Mac. All rights reserved.
//

#import "FUStaLiteRequestManager.h"
#import <FUStaLite/FUStaLite.h>
#import "authpack.h"
#import <AFNetworking.h>
static NSString *const  url                  = @"http://xxx/xxx/xxx/xxx";//请联系Faceunity使用TTS功能


@interface FUStaLiteRequestManager ()

@property (nonatomic,strong) FUStaLite *fusta_lite;

@end

@implementation FUStaLiteRequestManager


+ (instancetype)shareManager{
    static FUStaLiteRequestManager *_shareManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareManager = [[FUStaLiteRequestManager alloc] init];
    });
    
    return _shareManager;
}

- (instancetype)init {
    
    if (self = [super init]) {
        //Stalite初始化,全局仅一次
        NSData *authData = [NSData dataWithBytes:g_auth_package length:sizeof(g_auth_package)];
        NSData * ttaData = [[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"fustalite_tta.bin" ofType:nil]];
        self.fusta_lite = [FUStaLite staLiteWithTtaData:ttaData authData:authData];
    }
    return self;
}


- (void)process:(NSString*)text
      voiceName:(NSString*)name
    voiceFormat:(NSString*)format
    voiceVolume:(NSString*)volume
     voiceSpeed:(NSString*)speed
voiceSamplerate:(NSString*)samplerate
         result:(FUStaLiteHandler)result {
    
    if (!text) {
        NSLog(@"text can't be empty");
        return;
    }
    
    if (!name ) {
        NSLog(@"name can't be empty");
        return;
    }
    
    if (!format) {
        NSLog(@"format can't be empty");
        return;
    }

    //body
    NSMutableDictionary *bodyDic = [[NSMutableDictionary alloc] init];
    
    //request param
    [bodyDic setValue:text forKey:@"word"];
    [bodyDic setValue:name forKey:@"voice"];
    [bodyDic setValue:@"chinese" forKey:@"language"];
    [bodyDic setValue:@"咪咕项目" forKey:@"identity"];
    [bodyDic setValue:@"base64" forKey:@"encode"];
    
    //optional param
    if (format) {
        [bodyDic setValue:format forKey:@"format"];
    }
    if (speed) {
        [bodyDic setValue:speed forKey:@"speed"];
    }
    if (volume) {
        [bodyDic setValue:volume forKey:@"volume"];
    }
    if (samplerate) {
        [bodyDic setValue:samplerate forKey:@"sample_rate"];
    }
    
    //request
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager POST:url parameters:bodyDic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            NSDictionary *resultDic = responseObject[@"data"];
            if ([resultDic isKindOfClass:NSDictionary.class]) {
                NSString *audioBase64 = resultDic[@"audio"];
                NSString *tts = resultDic[@"timestamp"];
                //音频源
                NSData *audioData = [[NSData alloc]initWithBase64EncodedString:audioBase64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
                
                //表情系数
                NSData *expressionData = nil;
                if (self.fusta_lite) {
                    self.fusta_lite.expOffsetTime = 0.25;//偏移
                    expressionData = [self.fusta_lite queryExpressionWith:tts ttsType:FUTTSTypeCharacter];
                }
                
                //表情时间间隔
                float timeStride = self.fusta_lite.timeStride;
                
                result(nil,audioData,expressionData,timeStride);
                return ;
            }
        }
        NSLog(@"⚠️⚠️⚠️error message:%@",responseObject[@"message"]);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"⚠️⚠️⚠️request filed");
        
    }];
    
}


@end
