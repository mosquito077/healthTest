//
//  AnalyzeJson.h
//  healthTest
//
//  Created by mosquito on 2017/6/14.
//  Copyright © 2017年 mosquito. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <HealthKit/HealthKit.h>

@interface AnalyzeData : NSObject

+ (NSMutableArray<HKObject *> *)stepCorrelationWithStepNum;
+ (NSMutableArray<HKObject *> *)sleepCorrelationWithSleepNum;

@end
