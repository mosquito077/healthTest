//
//  Tools.h
//  healthTest
//
//  Created by mosquito on 2017/6/10.
//  Copyright © 2017年 mosquito. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Tools : NSObject

#pragma mark - HUD Wait
+ (void)showWaitAlert;

+ (void)showWaitAlertInView:(UIView *)view;

+ (void)showWaitAlertWithMessage:(NSString *)message;

+ (void)showWaitAlertWithMessage:(NSString *)message
                          inView:(UIView *)view;

+ (void)hiddenWaitAlert;

+ (void)hiddenWaitAlertInView:(UIView *)view;

#pragma mark - HUD Toast
+ (void)showToastWithMessage:(NSString *)message;

+ (void)showToastWithMessage:(NSString *)message
                  afterDelay:(NSTimeInterval)delay;

+ (void)showToastWithMessage:(NSString *)message
                      inView:(UIView *)view;

+ (void)showToastWithMessage:(NSString *)message
                      inView:(UIView *)view
                  afterDelay:(NSTimeInterval)delay;

@end
