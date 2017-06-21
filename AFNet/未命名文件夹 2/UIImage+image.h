//
//  UIImage+image.h
//  AFNet
//
//  Created by Suger on 2017/6/21.
//  Copyright © 2017年 Suger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (image)
/**
 ///创建纯色的图片


 @param color 颜色
 @param size 大小
 @return 图片对象
 */
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;
/**
 ///创建纯色的圆形图片
 

 @param color 颜色
 @param radius 半径
 @return 圆形图片
 */
+ (UIImage *)imageWithColor:(UIColor *)color radius:(CGFloat)radius;

@end
