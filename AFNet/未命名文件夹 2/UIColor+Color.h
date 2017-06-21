//
//  UIColor+Color.h
//  AFNet
//
//  Created by Suger on 2017/6/21.
//  Copyright © 2017年 Suger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Color)
+ (UIColor *)colorWithHex:(NSInteger)hexValue;
+ (UIColor *)colorWithHex:(NSInteger)hexValue alpha:(CGFloat)alpha;
+ (UIColor *)colorWithHex:(NSInteger)hexValue addBlack:(CGFloat)black;

@end
