//
//  ViewController.m
//  healthTest
//
//  Created by mosquito on 2017/6/2.
//  Copyright © 2017年 mosquito. All rights reserved.
//

#import "ViewController.h"
#import "HealthKitManager.h"
#import "AnalyzeJson.h"

#define WeakSelf __weak typeof(self) weakSelf = self;

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *stepCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *stepMileLabel;
@property (weak, nonatomic) IBOutlet UILabel *sleepLabel;

@property (strong, nonatomic) NSArray *stepArray;
@property (strong, nonatomic) NSArray *sleepArray;
@property (strong, nonatomic) NSMutableArray<HKObject *> *sampleArray;
@property (strong, nonatomic) NSMutableArray<HKObject *> *sleepSampleArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _stepArray = [[NSMutableArray alloc]init];
    _sleepArray = [[NSMutableArray alloc]init];

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
    self.sampleArray = [self stepCorrelationWithStepNum];
    [[HealthKitManager sharedInstance] authorizeHealthKit:^(BOOL success, NSError *error) {
        if (success) {
            [self.healthStore saveObjects:self.sampleArray withCompletion:^(BOOL success, NSError * _Nullable error) {
                if (success) {
                    NSLog(@"步数插入成功");
                } else {
                    NSLog(@"The error was: %@.", error);
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
    self.sleepSampleArray = [self sleepCorrelationWithSleepNum];
    [[HealthKitManager sharedInstance] authorizeHealthKit:^(BOOL success, NSError *error) {
        if (success) {
            [_healthStore saveObjects:self.sleepSampleArray withCompletion:^(BOOL success, NSError * _Nullable error) {
                if (success) {
                    NSLog(@"睡眠记录插入成功");
                } else {
                    NSLog(@"睡眠记录插入失败 %@", error);
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
                    NSLog(@"睡眠记录删除失败 %@", error);
                }
            }];
        }];
    }];
}

//插入的睡眠数据分析
- (NSMutableArray<HKObject *> *)sleepCorrelationWithSleepNum {
    self.sleepArray = [AnalyzeJson analyzeSleepData];
    HKCategoryType *categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    HKDevice *device = [[HKDevice alloc] initWithName:@"ww" manufacturer:@"apple" model:@"iphone" hardwareVersion:@"1.0.0" firmwareVersion:@"1.0.0" softwareVersion:@"1.0.0" localIdentifier:@"ww" UDIDeviceIdentifier:@"we"];
    NSMutableArray<HKObject *> *countArray = [[NSMutableArray alloc] init];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    for (int i=0; i<[self.sleepArray count]; i++) {
        NSString *timeString = [NSString stringWithFormat:@"%@", _sleepArray[i][@"dateTime"]];
        NSString *startString = [timeString stringByReplacingOccurrencesOfString:@"T" withString:@" "];
        NSString *dateString = [startString stringByReplacingOccurrencesOfString:@".000" withString:@""];
        NSDate *startDate = [dateFormatter dateFromString:dateString];
        double interval = [_sleepArray[i][@"seconds"] doubleValue];
        NSDate *endDate = [startDate dateByAddingTimeInterval:interval];
        NSString *level = _sleepArray[i][@"level"];
        NSInteger value;
        if ([level isEqualToString:@"awake"] || [level isEqualToString:@"wake"]) {
            value = 2;
        } else if ([level isEqualToString:@"restless"] || [level isEqualToString:@"rem"]) {
            value = 0;
        } else {
            value = 1;
        }
        
        HKCategorySample *sleepSample = [HKCategorySample categorySampleWithType:categoryType value:value startDate:startDate endDate:endDate device:device metadata:nil];
        [countArray addObject:sleepSample];
    }
    return countArray;
}

//插入的步数分析
- (NSMutableArray<HKObject *> *)stepCorrelationWithStepNum {
    self.stepArray = [AnalyzeJson analyzeStepData];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSMutableArray<HKObject *> *countArray = [[NSMutableArray alloc] init];
    
    HKDevice *device = [[HKDevice alloc] initWithName:[[UIDevice currentDevice] name]
                                         manufacturer:@"Apple"
                                                model:[[UIDevice currentDevice] model]
                                      hardwareVersion:[[UIDevice currentDevice] model]
                                      firmwareVersion:[[UIDevice currentDevice] model]
                                      softwareVersion:[[UIDevice currentDevice] systemVersion]
                                      localIdentifier:[[NSLocale currentLocale] localeIdentifier]
                                  UDIDeviceIdentifier:[[NSLocale currentLocale] localeIdentifier]];
    
    for (int i=0; i<[self.stepArray count]; i++) {
        NSDate *date = [dateFormatter dateFromString:_stepArray[i][@"dateTime"]];
        NSDate *beginDate = date;
        NSDate *endDate = date;
        
        double stepCount = [_stepArray[i][@"value"] doubleValue];
        HKQuantity *stepQuantityConsumed = [HKQuantity quantityWithUnit:[HKUnit countUnit] doubleValue:stepCount];
        HKQuantityType *stepConsumedType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        HKQuantitySample *stepConsumedSample = [HKQuantitySample quantitySampleWithType:stepConsumedType
                                                                               quantity:stepQuantityConsumed
                                                                              startDate:beginDate
                                                                                endDate:endDate
                                                                                 device:device
                                                                               metadata:nil];
        [countArray addObject:stepConsumedSample];
    }
    return countArray;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -- get
- (HKHealthStore *)healthStore {
    if (_healthStore == nil) {
        _healthStore = [[HKHealthStore alloc] init];
    }
    return _healthStore;
}

@end
