//
//  ViewController.m
//  healthTest
//
//  Created by mosquito on 2017/6/2.
//  Copyright © 2017年 mosquito. All rights reserved.
//

#import "ViewController.h"
#define WeakSelf __weak typeof(self) weakSelf = self;

typedef NS_ENUM(NSInteger, LHealthType) {
    LHealthTypeFootType = 0,
    LHealthTypeFootMile
};

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *stepCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *stepMileLabel;
@property (weak, nonatomic) IBOutlet UITextView *sleepMessageTV;


@property (strong, nonatomic) NSMutableArray *stepArray;
@property (strong, nonatomic) NSMutableArray<HKObject *> *sampleArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self isHealthDataAvailable];
    [self initStepArray];

}

- (void)initStepArray {
    _stepArray = [[NSMutableArray alloc]init];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"stepList.json" ofType:nil];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *dictArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    for (NSDictionary *dic in dictArray[@"data"]) {
        [_stepArray addObject:dic];
    }
}

#pragma mark - 获取健康权限
- (void)isHealthDataAvailable{
    if ([HKHealthStore isHealthDataAvailable]) {
        
        HKQuantityType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        HKObjectType *sleepType = [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
        NSSet *dataTypes = [NSSet setWithObjects:stepType, sleepType, nil];
        
        [self.healthStore requestAuthorizationToShareTypes:dataTypes readTypes:dataTypes completion:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"你不允许包来访问这些读/写数据类型。error === %@", error);
                return;
            }
        }];
    }
}

#pragma mark -- methods
- (IBAction)stepCountButtonTapped:(id)sender {
    [self getTodayHealthDataWithHealthType:LHealthTypeFootType];
}


- (IBAction)stepMileButtonTapped:(id)sender {
    [self getTodayHealthDataWithHealthType:LHealthTypeFootMile];
}


- (IBAction)insertStepCount:(id)sender {
    [self addstepWithStepNum];
}

//读取睡眠信息  limit 只显示三个HKSample
- (IBAction)checkSleepData:(id)sender {
    WeakSelf;
    HKSampleType *sampleType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    
    HKSampleQuery *sleepSample = [[HKSampleQuery alloc]initWithSampleType:sampleType predicate:nil limit:3 sortDescriptors:@[sortDescriptor] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        
        /* 判断睡眠分析来源-用户手动添加&apple healthKit
        NSMutableArray *resultArr = [[NSMutableArray alloc] init];
        for (HKSample *model in results) {
            NSDictionary *dict = (NSDictionary *)model.metadata;
            NSInteger wasUserEntered = [dict[@"HKWasUserEntered"]integerValue];
            if(wasUserEntered == 1) {      //user add
                
            } else {                       //apple healthkit
                [resultArr addObject:model];
            }
        }*/
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        for (HKCategorySample *sample in results) {
            NSString *beginDateStr = [dateFormatter stringFromDate:sample.startDate];
            NSString *endDateStr = [dateFormatter stringFromDate:sample.endDate];
            NSLog(@"%ld %@ %@", (long)sample.value, beginDateStr, endDateStr);
        }
        NSLog(@"resultCount = %ld resultArr = %@",results.count, results);
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.sleepMessageTV setText:[NSString stringWithFormat:@"%@", results]];
        });
    }];
    [self.healthStore executeQuery:sleepSample];
    
}

// 写入睡眠信息 插入一条数据
- (IBAction)alterSleepData:(id)sender {
    /*
     value:
     HKCategoryValueSleepAnalysisInBed = 0 卧床休息
     HKCategoryValueSleepAnalysisAsleep = 1 睡眠时间
     HKCategoryValueSleepAnalysisAwake = 2  清醒状态
     */
    WeakSelf;
    HKCategoryType *mySleep = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    NSDate *startDate = [[NSDate date] dateByAddingTimeInterval:-2*60*60];
    NSDate *endDate = [NSDate date];
    HKCategorySample *sleep = [HKCategorySample categorySampleWithType:mySleep value:HKCategoryValueSleepAnalysisInBed startDate:startDate endDate:endDate];
    
    [self.healthStore saveObject:sleep withCompletion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.sleepMessageTV setText:[NSString stringWithFormat:@"插入类型%ld 开始时间%@ 结束时间%@", HKCategoryValueSleepAnalysisInBed, startDate, endDate]];
            });
            NSLog(@"alter sleepData success");
        }
        else {
            NSLog(@"error === %@",error);
        }
    }];
}

- (void)addstepWithStepNum {
    
    self.sampleArray = [self stepCorrelationWithStepNum];
    [self.healthStore saveObjects:self.sampleArray withCompletion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSLog(@"添加成功");
        } else {
            NSLog(@"The error was: %@.", error);
            return ;
        }
    }];
    
}

- (NSMutableArray<HKObject *> *)stepCorrelationWithStepNum {
    
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

- (void)getTodayHealthDataWithHealthType:(LHealthType)healthType {
    __block double healthData;
    __block HKQuantityType *type;
    switch (healthType) {
        case 0:
            type = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
            break;
        case 1:
            type = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
            break;
            
        default:
            break;
    }
    WeakSelf;
    NSSet *readType = [NSSet setWithObject:type];
    [self.healthStore requestAuthorizationToShareTypes:nil readTypes:readType completion:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            NSLog(@"没有获取授权");
        } else {
            // beginDate & endDate 为nil，取全部数据
            NSDate *beginDate = nil;
            NSDate *endDate = nil;
            NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:beginDate endDate:endDate options:HKQueryOptionNone];
            HKStatisticsQuery *query = [[HKStatisticsQuery alloc]initWithQuantityType:type quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery * _Nonnull query,HKStatistics * _Nullable result,NSError * _Nullable error) {
                if (result) {
                    HKUnit *unit = [HKUnit countUnit];
                    if (healthType == LHealthTypeFootType) {
                        unit = [HKUnit countUnit];
                    } else {
                        unit = [HKUnit mileUnit];
                        }
                    healthData = [result.sumQuantity doubleValueForUnit:unit];
                    }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (healthType == LHealthTypeFootType) {
                        [weakSelf showStepCount:healthData];
                        } else {
                            [weakSelf showStepMile:healthData];
                        }
                    });
            }];
            [self.healthStore executeQuery:query];
        }
    }];
}


- (void)showStepCount:(double)healthData {
    NSString *stepCountStr = [NSString stringWithFormat:@"%f", healthData];
    self.stepCountLabel.text = stepCountStr;
}

- (void)showStepMile:(double)healthData {
    NSString *stepMileStr = [NSString stringWithFormat:@"%f", healthData];
    self.stepMileLabel.text = stepMileStr;
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
