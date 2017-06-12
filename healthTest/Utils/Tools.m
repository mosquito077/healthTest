//
//  Tools.m
//  healthTest
//
//  Created by mosquito on 2017/6/10.
//  Copyright © 2017年 mosquito. All rights reserved.
//

#import "Tools.h"
#import <MBProgressHUD/MBProgressHUD.h>

#define kAlertAutoDelayTimeInterval     1.0

@implementation Tools
+ (void)hideAllHUDsForView:(UIView *)view animated:(BOOL)animated {
    for (UIView *subView in view.subviews) {
        if ([subView isKindOfClass:[MBProgressHUD class]]) {
            MBProgressHUD *hud = (MBProgressHUD *)subView;
            
            hud.removeFromSuperViewOnHide = YES;
            [hud hideAnimated:animated];
        }
    }
}

#pragma mark - HUD Wait
+ (void)showWaitAlert {
    [self showWaitAlertInView:[[UIApplication sharedApplication] keyWindow]];
}

+ (void)showWaitAlertInView:(UIView *)view {
    [self showWaitAlertWithMessage:nil
                            inView:view];
}

+ (void)showWaitAlertWithMessage:(NSString *)message {
    [self showWaitAlertWithMessage:message
                            inView:[[UIApplication sharedApplication] keyWindow]];
}

+ (void)showWaitAlertWithMessage:(NSString *)message
                          inView:(UIView *)view {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideAllHUDsForView:view animated:NO];
        
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:view];
        hud.bezelView.color = [UIColor blackColor];
        hud.contentColor = [UIColor whiteColor];
        
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.label.font = [UIFont systemFontOfSize:12.0f];
        hud.detailsLabel.text = message;
        hud.offset = CGPointMake(hud.offset.x, -100.0f);
        hud.removeFromSuperViewOnHide = YES;
        hud.userInteractionEnabled = YES;
        
        [view addSubview:hud];
        [hud showAnimated:YES];
    });
}

+ (void)hiddenWaitAlert {
    [self hiddenWaitAlertInView:[[UIApplication sharedApplication] keyWindow]];
}

+ (void)hiddenWaitAlertInView:(UIView *)view {
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:view animated:YES];
    });
}

#pragma mark - HUD Toast
+ (void)showToastWithMessage:(NSString *)message {
    [self showToastWithMessage:message
                    afterDelay:kAlertAutoDelayTimeInterval];
}

+ (void)showToastWithMessage:(NSString *)message
                  afterDelay:(NSTimeInterval)delay {
    [self showToastWithMessage:message
                        inView:[[UIApplication sharedApplication] keyWindow]
                    afterDelay:delay];
}

+ (void)showToastWithMessage:(NSString *)message
                      inView:(UIView *)view {
    [self showToastWithMessage:message
                        inView:view
                    afterDelay:kAlertAutoDelayTimeInterval];
}

+ (void)showToastWithMessage:(NSString *)message
                      inView:(UIView *)view
                  afterDelay:(NSTimeInterval)delay {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideAllHUDsForView:view animated:NO];
        
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:view];
        hud.bezelView.color = [UIColor blackColor];
        hud.contentColor = [UIColor whiteColor];
        
        hud.mode = MBProgressHUDModeText;
        hud.detailsLabel.text = message;
        hud.detailsLabel.font = hud.label.font;
        hud.offset = CGPointMake(hud.offset.x, -100.0f);
        hud.removeFromSuperViewOnHide = YES;
        hud.alpha = 0.75;
        hud.userInteractionEnabled = NO;
        
        [view addSubview:hud];
        [hud showAnimated:YES];
        
        [hud hideAnimated:YES afterDelay:delay];
    });
}

@end
