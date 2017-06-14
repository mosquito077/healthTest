//
//  HealthKitManager.h
//  healthTest
//
//  Created by mosquito on 2017/6/14.
//  Copyright © 2017年 mosquito. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HealthKitManager : NSObject

+ (instancetype)sharedInstance;

//检查是否支持获取健康数据
- (void)authorizeHealthKit:(void(^)(BOOL success, NSError *error))completion;

//获取步数
- (void)getStepCount:(void(^)(NSString *stepValue, NSError *error))completion;

//获取公里数
- (void)getStepMile:(void(^)(NSString *mileValue, NSError *error))completion;

//获取睡眠数据
- (void)getSleepStatistics:(void(^)(NSString *sleepValue, NSError *error))completion;

//删除睡眠数据
- (void)deleteSleepStatistics:(void(^)(NSArray *sleepData, NSError *error))completion;

@end
