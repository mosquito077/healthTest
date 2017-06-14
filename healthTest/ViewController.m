//
//  ViewController.m
//  healthTest
//
//  Created by mosquito on 2017/6/2.
//  Copyright © 2017年 mosquito. All rights reserved.
//

#import "ViewController.h"
#import "HealthKitManager.h"
#import "AnalyzeData.h"

#define WeakSelf __weak typeof(self) weakSelf = self;

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *stepCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *stepMileLabel;
@property (weak, nonatomic) IBOutlet UILabel *sleepLabel;

@property (strong, nonatomic) NSMutableArray<HKObject *> *sampleArray;
@property (strong, nonatomic) NSMutableArray<HKObject *> *sleepSampleArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.healthStore = [[HKHealthStore alloc] init];
}

#pragma mark -- methods
//获取步数
- (IBAction)stepCountButtonTapped:(id)sender {
    [[HealthKitManager sharedInstance] authorizeHealthKit:^(BOOL success, NSError *error) {
        if (success) {
            [[HealthKitManager sharedInstance] getStepCount:^(NSString *stepValue, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _stepCountLabel.text = [NSString stringWithFormat:@"%@", stepValue];
                });
            }];
        } else {
            NSLog(@"error = %@", error.description);
        }
    }];
}

//获取公里数
- (IBAction)stepMileButtonTapped:(id)sender {
    [[HealthKitManager sharedInstance] authorizeHealthKit:^(BOOL success, NSError *error) {
        if (success) {
            [[HealthKitManager sharedInstance] getStepMile:^(NSString *mileValue, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _stepMileLabel.text = [NSString stringWithFormat:@"%@", mileValue];
                });
            }];
        } else {
            NSLog(@"error = %@", error.description);
        }
    }];
}

//插入步数
- (IBAction)insertStepCount:(id)sender {
    self.sampleArray = [AnalyzeData stepCorrelationWithStepNum];
    [[HealthKitManager sharedInstance] authorizeHealthKit:^(BOOL success, NSError *error) {
        if (success) {
            [self.healthStore saveObjects:self.sampleArray withCompletion:^(BOOL success, NSError * _Nullable error) {
                if (success) {
                    NSLog(@"步数插入成功");
                } else {
                    NSLog(@"error = %@", error.description);
                    return ;
                }
            }];
        }
    }];
}

//读取睡眠信息
- (IBAction)checkSleepData:(id)sender {
    [[HealthKitManager sharedInstance] authorizeHealthKit:^(BOOL success, NSError *error) {
        if (success) {
            [[HealthKitManager sharedInstance] getSleepStatistics:^(NSString *sleepValue, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _sleepLabel.text = [NSString stringWithFormat:@"睡眠:%@小时", sleepValue];
                });
            }];
        }
    }];
}

//插入睡眠数据
- (IBAction)alterSleepData:(id)sender {
    self.sleepSampleArray = [AnalyzeData sleepCorrelationWithSleepNum];
    [[HealthKitManager sharedInstance] authorizeHealthKit:^(BOOL success, NSError *error) {
        if (success) {
            [self.healthStore saveObjects:self.sleepSampleArray withCompletion:^(BOOL success, NSError * _Nullable error) {
                if (success) {
                    NSLog(@"睡眠记录插入成功");
                } else {
                    NSLog(@"error = %@", error.description);
                }
            }];
        }
    }];
}

//删除睡眠数据
- (IBAction)deleteSleepDataAction:(id)sender {
    [[HealthKitManager sharedInstance] authorizeHealthKit:^(BOOL success, NSError *error) {
        [[HealthKitManager sharedInstance] deleteSleepStatistics:^(NSArray *sleepData, NSError *error) {
            [self.healthStore deleteObjects:sleepData withCompletion:^(BOOL success, NSError * _Nullable error) {
                if (success) {
                    NSLog(@"睡眠记录删除成功");
                } else {
                    NSLog(@"error = %@", error.description);
                }
            }];
        }];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
