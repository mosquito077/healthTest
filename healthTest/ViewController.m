//
//  ViewController.m
//  healthTest
//
//  Created by mosquito on 2017/6/2.
//  Copyright © 2017年 mosquito. All rights reserved.
//

#import "ViewController.h"
#import "Tools.h"

#define WeakSelf __weak typeof(self) weakSelf = self;

typedef NS_ENUM(NSInteger, LHealthType) {
    LHealthTypeFootType = 0,
    LHealthTypeFootMile
};

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *stepCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *stepMileLabel;

@property (strong, nonatomic) NSMutableArray *stepArray;
@property (strong, nonatomic) NSMutableArray *sleepArray;
@property (strong, nonatomic) NSMutableArray<HKObject *> *sampleArray;
@property (strong, nonatomic) NSMutableArray<HKObject *> *sleepSampleArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self isHealthDataAvailable];
    [self initStepArray];
    [self initSleepArray];

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

- (void)initSleepArray {
    _sleepArray = [[NSMutableArray alloc]init];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"sleepdata.json" ofType:nil];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *dictArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    for (NSDictionary *dic in dictArray[@"sleep"]) {
        NSArray *dataArray = dic[@"levels"][@"data"];
        for (NSDictionary *dataDic in dataArray) {
            [_sleepArray addObject:dataDic];
        }
    }
}

#pragma mark - 获取健康权限
- (void)isHealthDataAvailable {
    if ([HKHealthStore isHealthDataAvailable]) {
        HKQuantityType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        HKQuantityType *mileType= [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
        HKObjectType *sleepType = [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
        NSSet *dataTypes = [NSSet setWithObjects:stepType, sleepType, mileType, nil];
        
        [self.healthStore requestAuthorizationToShareTypes:dataTypes readTypes:dataTypes completion:^(BOOL success, NSError *error) {
            if (!success) {
                NSString *message = [NSString stringWithFormat:@"你不允许包来访问这些读/写数据类型。error === %@", error];
                [Tools showToastWithMessage:message];
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
    self.sampleArray = [self stepCorrelationWithStepNum];
    [self.healthStore saveObjects:self.sampleArray withCompletion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            [Tools showToastWithMessage:@"添加成功"];
        } else {
            [Tools showToastWithMessage:[NSString stringWithFormat:@"The error was: %@.", error]];
            return ;
        }
    }];
}

- (IBAction)deleteStepCount:(id)sender {
    HKQuantityType *stepConsumedTyep = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSPredicate *queryPredicate = [HKSampleQuery predicateForSamplesWithStartDate:[[NSDate date] dateByAddingTimeInterval:-(24*60*60)] endDate:[NSDate date] options:HKQueryOptionNone];
    
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:stepConsumedTyep predicate:queryPredicate limit:1000 sortDescriptors:nil resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        if (error) {
            NSLog(@"查找Sample错误：%@", error.description);
        } else {
            
            if (results) {
                for (HKSample *deleteSample in results) {
                    if (deleteSample) {
                        NSString *sourceValue = [deleteSample.metadata objectForKey:@"metaKey"];
                        NSLog(@"Source = %@", sourceValue);
                        if (sourceValue != nil && [sourceValue isEqualToString:@"metaKey"]) {
                            [self.healthStore deleteObject:deleteSample withCompletion:^(BOOL success, NSError * _Nullable error) {
                                if (success) {
                                    NSLog(@"成功删除对象");
                                } else {
                                    NSLog(@"删除对象失败");
                                }
                            }];
                        } else {
                            NSLog(@"并非ss数据不做删除");
                        }
                    }
                }
            }
        }
    }];
    [self.healthStore executeQuery:query];
}

//读取睡眠信息  limit 只显示三个HKSample
- (IBAction)checkSleepData:(id)sender {
    HKSampleType *sampleType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];
        
    HKSampleQuery *sleepSample = [[HKSampleQuery alloc]initWithSampleType:sampleType predicate:nil limit:8 sortDescriptors:@[sortDescriptor] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
            
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
            
        [Tools showToastWithMessage:@"获取睡眠记录成功"];
    }];
    [self.healthStore executeQuery:sleepSample];
}

// 写入睡眠信息 插入一条数据
- (IBAction)alterSleepData:(id)sender {
    HKCategoryType *categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    HKDevice *device1 = [[HKDevice alloc] initWithName:@"ww" manufacturer:@"中国制造商" model:@"智能机" hardwareVersion:@"1.0.0" firmwareVersion:@"1.0.0" softwareVersion:@"1.0.0" localIdentifier:@"lizaochengwen" UDIDeviceIdentifier:@"wennengshebei"];
    HKDevice *device2 = [[HKDevice alloc] initWithName:@"yy" manufacturer:@"中国制造商" model:@"智能机" hardwareVersion:@"1.0.0" firmwareVersion:@"1.0.0" softwareVersion:@"1.0.0" localIdentifier:@"lizaochengwen" UDIDeviceIdentifier:@"wennengshebei"];
    
    NSMutableArray *list= [[NSMutableArray alloc] init];
    for (float i = 1; i < 10; i++) {
        HKCategorySample *testObject = [HKCategorySample categorySampleWithType:categoryType value:0 startDate:[NSDate dateWithTimeIntervalSinceNow:-(3600*i)] endDate:[NSDate dateWithTimeIntervalSinceNow:-(3600*(i-1))] device:device1 metadata:nil];
        [list addObject:testObject];
    }
    
    for (float i = 1; i < 10; i++) {
        HKCategorySample *testObject = [HKCategorySample categorySampleWithType:categoryType value:1 startDate:[NSDate dateWithTimeIntervalSinceNow:-(3600*i)] endDate:[NSDate dateWithTimeIntervalSinceNow:-(3600*(i-1))] device:device2 metadata:nil];
        [list addObject:testObject];
    }
    
    [_healthStore saveObjects:list withCompletion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            [Tools showToastWithMessage:@"睡眠记录插入成功"];
        } else {
            [Tools showToastWithMessage:[NSString stringWithFormat:@"睡眠记录插入失败 %@", error]];
        }
    }];
}

//删除睡眠数据
- (IBAction)deleteSleepDataAction:(id)sender {
    /*  删除device全部数据
    HKCategoryType *categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    NSPredicate *catePredicate = [HKQuery predicateForObjectsWithDeviceProperty:HKDevicePropertyKeyName allowedValues:[[NSSet alloc] initWithObjects:@"文能", nil]];
    [self.healthStore deleteObjectsOfType:categoryType predicate:catePredicate withCompletion:^(BOOL success, NSUInteger deletedObjectCount, NSError * _Nullable error) {
        if (success) {
            [Tools showToastWithMessage:@"睡眠记录删除成功"];
        } else {
            [Tools showToastWithMessage:[NSString stringWithFormat:@"睡眠记录删除失败 %@", error]];
        }
    }];
     */
    
    HKSampleType *sampleType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    
    HKSampleQuery *sleepSample = [[HKSampleQuery alloc]initWithSampleType:sampleType predicate:nil limit:HKObjectQueryNoLimit sortDescriptors:@[sortDescriptor] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *startString = @"2017-06-10 14:00:00";
        NSString *endString = @"2017-06-10 18:00:00";
        NSDate *startDate = [dateFormatter dateFromString:startString];
        NSDate *endDate = [dateFormatter dateFromString:endString];

        for (HKSample *sample in results) {
            if ([sample.startDate compare:startDate] == NSOrderedDescending
                && [sample.endDate compare:endDate] == NSOrderedAscending
                && [sample.device.name isEqualToString: @"ww"]) {
                [self.healthStore deleteObject:sample withCompletion:^(BOOL success, NSError * _Nullable error) {
                    if (success) {
                        NSLog(@"success");
                    } else {
                        NSLog(@"%@", error);
                        NSLog(@"error");
                    }
                }];
            }
        }
    }];
    [self.healthStore executeQuery:sleepSample];
}

- (NSMutableArray<HKObject *> *)sleepCorrelationWithSleepNum {
    HKCategoryType *categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
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
        
        HKCategorySample *sleepSample = [HKCategorySample categorySampleWithType:categoryType value:value startDate:startDate endDate:endDate];
        [countArray addObject:sleepSample];
    }
    return countArray;
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
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:[NSDate dateWithTimeIntervalSinceNow:-(24 * 60 * 60)] endDate:[NSDate date] options:HKQueryOptionNone];
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
