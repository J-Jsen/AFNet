//
//  UIImage+image.m
//  AFNet
//
//  Created by Suger on 2017/6/21.
//  Copyright © 2017年 Suger. All rights reserved.
//

#import "UIImage+image.h"

@implementation UIImage (image)
//创建纯色的图片
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size
{
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
///创建纯色的圆形图片
+ (UIImage *)imageWithColor:(UIColor *)color radius:(CGFloat)radius{
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(radius * 2, radius * 2), NO, [UIScreen mainScreen].scale);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //画大圆并填充颜
    CGContextSetFillColorWithColor(context, color.CGColor);//填充颜色
    CGContextAddArc(context, radius, radius, radius, 0, 2 * M_PI, 1);
    CGContextDrawPath(context, kCGPathFill);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
