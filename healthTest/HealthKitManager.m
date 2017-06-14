//
//  HealthKitManager.m
//  healthTest
//
//  Created by mosquito on 2017/6/14.
//  Copyright © 2017年 mosquito. All rights reserved.
//

#import "HealthKitManager.h"
#import <HealthKit/HealthKit.h>

@interface HealthKitManager()

@property (strong, nonatomic) HKHealthStore *healthStore;

@end

@implementation HealthKitManager

#pragma mark -- health单例
+ (instancetype)sharedInstance {
    static HealthKitManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HealthKitManager alloc] init];
    });
    return instance;
}

#pragma mark -- 检查是否支持获取健康数据
- (void)authorizeHealthKit:(void (^)(BOOL success, NSError *error))completion {
    if (![HKHealthStore isHealthDataAvailable]) {
        NSError *error = [NSError errorWithDomain:@"不支持健康数据" code:2 userInfo:[NSDictionary dictionaryWithObject:@"HealthKit is not available in th is Device"                                                                      forKey:NSLocalizedDescriptionKey]];
        if (completion != nil) {
            completion(NO, error);
        }
        return;
    } else {
        if (self.healthStore == nil) {
            self.healthStore = [[HKHealthStore alloc] init];
        }
        //组装需要读写的数据类型
        NSSet *writeDataType = [self dataTypesToWrite];
        NSSet *readDataType = [self dataTypesToRead];
        [self.healthStore requestAuthorizationToShareTypes:writeDataType readTypes:readDataType completion:^(BOOL success, NSError *error) {
            if (completion != nil) {
                NSLog(@"error->%@", error.localizedDescription);
                completion (YES, error);
            }
        }];
    }
}

#pragma mark -- 获取步数
- (void)getStepCount:(void(^)(NSString *stepValue, NSError *error))completion {
    HKQuantityType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:[NSDate dateWithTimeIntervalSinceNow:-(24 * 60 * 60)] endDate:[NSDate date] options:HKQueryOptionNone];
    HKStatisticsQuery *query = [[HKStatisticsQuery alloc]initWithQuantityType:stepType quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery * _Nonnull query,HKStatistics * _Nullable result,NSError * _Nullable error) {
        if (error) {
            completion(0, error);
        } else {
            HKUnit *unit = [HKUnit countUnit];
            double healthData = [result.sumQuantity doubleValueForUnit:unit];
            completion([NSString stringWithFormat:@"%ld",(long)healthData],error);
        }
    }];
    [self.healthStore executeQuery:query];
    
}

#pragma mark -- 获取公里数
- (void)getStepMile:(void(^)(NSString *mileValue, NSError *error))completion {
    HKQuantityType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:[NSDate dateWithTimeIntervalSinceNow:-(24 * 60 * 60)] endDate:[NSDate date] options:HKQueryOptionNone];
    HKStatisticsQuery *query = [[HKStatisticsQuery alloc]initWithQuantityType:stepType quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery * _Nonnull query,HKStatistics * _Nullable result,NSError * _Nullable error) {
        if (error) {
            completion(0, error);
        } else {
            HKUnit *unit = [HKUnit mileUnit];
            double healthData = [result.sumQuantity doubleValueForUnit:unit];
            completion([NSString stringWithFormat:@"%ld",(long)healthData],error);
        }
    }];
    [self.healthStore executeQuery:query];
}

#pragma mark -- 获取睡眠数据
- (void)getSleepStatistics:(void(^)(NSString *sleepValue, NSError *error))completion {
    HKSampleType *sampleType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    NSPredicate *predicate = [HKSampleQuery predicateForSamplesWithStartDate:[[NSDate date] dateByAddingTimeInterval:-(24*60*60)] endDate:[NSDate date] options:HKQueryOptionNone];
    
    HKSampleQuery *sleepSample = [[HKSampleQuery alloc]initWithSampleType:sampleType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:@[sortDescriptor] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        
        /* 判断睡眠分析来源-用户手动添加&apple healthKit
         for (HKSample *model in results) {
         NSDictionary *dict = (NSDictionary *)model.metadata;
         NSInteger wasUserEntered = [dict[@"HKWasUserEntered"]integerValue];
         }*/
        
        if (error) {
            NSLog(@"%@", error.domain);
        } else{
            NSLog(@"resultCount = %ld result = %@",results.count,results);
            NSInteger totleSleep = 0;
            for (HKCategorySample *sample in results) {        //0：卧床时间 1：睡眠时间 2：清醒状态
                NSLog(@"%@ %ld",sample, sample.value);
                if (sample.value == 1) {
                    NSTimeInterval i = [sample.endDate timeIntervalSinceDate:sample.startDate];
                    totleSleep += i;
                }
            }
            NSLog(@"睡眠分析：%.2f",totleSleep/3600.0);
            completion([NSString stringWithFormat:@"%.2f",totleSleep/3600.0],error);
        }
    }];
    [self.healthStore executeQuery:sleepSample];
}

#pragma mark -- 删除睡眠数据
- (void)deleteSleepStatistics:(void(^)(NSArray *sleepData, NSError *error))completion {
    HKSampleType *sampleType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    NSPredicate *datePredicate = [HKSampleQuery predicateForSamplesWithStartDate:[[NSDate date] dateByAddingTimeInterval:-(34*60*60)] endDate:[[NSDate date] dateByAddingTimeInterval:-(32*60*60)] options:HKQueryOptionNone];
    NSPredicate *devicePredicate = [HKQuery predicateForObjectsWithDeviceProperty:HKDevicePropertyKeyName allowedValues:[[NSSet alloc] initWithObjects:@"ww", nil]];
    NSPredicate *queryPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:datePredicate, devicePredicate,nil]];
    
    HKSampleQuery *sleepSample = [[HKSampleQuery alloc]initWithSampleType:sampleType predicate:queryPredicate limit:HKObjectQueryNoLimit sortDescriptors:@[sortDescriptor] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error.domain);
        } else {
            completion(results, error);
        }
    }];
    [self.healthStore executeQuery:sleepSample];
}

#pragma mark -- 写权限
- (NSSet *)dataTypesToWrite {
    //步数
    HKQuantityType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    //公里数
    HKQuantityType *mileType= [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    //睡眠分析
    HKObjectType *sleepType = [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    return [NSSet setWithObjects:stepType, sleepType, mileType, nil];
}

#pragma mark -- 读权限
- (NSSet *)dataTypesToRead {
    //步数
    HKQuantityType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    //公里数
    HKQuantityType *mileType= [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    //睡眠分析
    HKObjectType *sleepType = [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    return [NSSet setWithObjects:stepType, sleepType, mileType, nil];
}

#pragma mark -- get
- (HKHealthStore *)healthStore {
    if (_healthStore == nil) {
        _healthStore = [[HKHealthStore alloc] init];
    }
    return _healthStore;
}

@end
