//
//  ZXSDefine.h
//  AFNet
//
//  Created by Suger on 2017/6/21.
//  Copyright © 2017年 Suger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZXSDefine : NSObject

// 项目打包上线都不会打印日志，因此可放心。
#ifdef DEBUG
#define ZXSLog(s, ... ) NSLog( @"[%@ in line %d] ===============>%@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define ZXSLog(s, ... )
#endif
//屏幕宽高
#define SCREEN_W              [UIScreen mainScreen].bounds.size.width
#define SCREEN_H              [UIScreen mainScreen].bounds.size.height
//基于苹果6来计算当前设备的宽高
#define WIDTH_6(FLOAT)        (SCREEN_W * FLOAT) / 375
#define HEIGHT_6(FLOAT)       (SCREEN_H * FLOAT) / 667
//color  三原色
#define COLOR(R , G , B)      [UIColor colorWithRed:R / 255.0f \
                                              green:G / 255.0f \
                                               blue:B / 255.0f \
                                              alpha:1]
//判断字符串是否为空
#define kStringIsNil(str)     ([str isKindOfClass:[NSNull class]] || str == nil || [str length] < 1 ? YES : NO )
//判断数组是否为空
#define kArrayIsNil(array)    (array == nil || [array isKindOfClass:[NSNull class]] || array.count == 0)
//判断字典是否为空
#define kDictIsNil(dic)       (dic == nil || [dic isKindOfClass:[NSNull class]] || dic.allKeys == 0)
//判断是否为空对象
#define kObjectIsNil(_object) (_object == nil \
|| [_object isKindOfClass:[NSNull class]] \
|| ([_object respondsToSelector:@selector(length)] && [(NSData *)_object length] == 0) \
|| ([_object respondsToSelector:@selector(count)] && [(NSArray *)_object count] == 0))

//app的版本号
#define kAppVersion           [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]
//手机型号
#define iPhone4S              ([UIScreen mainScreen].bounds.size.height == 480)
#define iPhone5S              ([UIScreen mainScreen].bounds.size.height == 568)
#define iPhone6S              ([UIScreen mainScreen].bounds.size.height == 667)
#define iPhone6pS             ([UIScreen mainScreen].bounds.size.height == 736)
//block 内部使用__weak
#define WeakSelf    __weak typeof(self) weakSelf = self;

//Model声明属性
#define STRING_PROPERTY(Str)        @property (nonatomic , copy) NSString * Str;
#define INTEGER_PROPERTY(Integer)   @property (nonatomic , assign) NSInteger Integer;
#define ARRAY_PROPERTY(MUTABLEARR)  @property (nonatomic , strong) NSMutableArray * MUTABLEARR;
#define DIC_PROPERTY(Dic)           @property (nonatomic ,strong) NSMutableDictionary * Dic;






@end
