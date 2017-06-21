//
//  UIColor+Color.m
//  AFNet
//
//  Created by Suger on 2017/6/21.
//  Copyright © 2017年 Suger. All rights reserved.
//

#import "UIColor+Color.h"

@implementation UIColor (Color)
+ (UIColor *)colorWithHex:(NSInteger)hexValue {
    return [UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16)) / 255.0
                           green:((float)((hexValue & 0xFF00) >> 8)) / 255.0
                            blue:((float)(hexValue & 0xFF))/255.0
                           alpha:1];
}

+ (UIColor *)colorWithHex:(NSInteger)hexValue addBlack:(CGFloat)black {
    return [UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16) * (1 - black)) / 255.0
                           green:((float)((hexValue & 0xFF00) >> 8) * (1 - black)) / 255.0
                            blue:((float)(hexValue & 0xFF) * (1 - black))/255.0
                           alpha:1];
}

+ (UIColor *)colorWithHex:(NSInteger)hexValue alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16)) / 255.0
                           green:((float)((hexValue & 0xFF00) >> 8)) / 255.0
                            blue:((float)(hexValue & 0xFF))/255.0
                           alpha:alpha];
}

@end
