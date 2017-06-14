//
//  AnalyzeJson.m
//  healthTest
//
//  Created by mosquito on 2017/6/14.
//  Copyright © 2017年 mosquito. All rights reserved.
//

#import "AnalyzeData.h"

@implementation AnalyzeData

//插入步数分析
+ (NSMutableArray<HKObject *> *)stepCorrelationWithStepNum {
    NSArray *stepArray = [self analyzeStepData];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSMutableArray<HKObject *> *stepNumArray = [[NSMutableArray alloc] init];
    
    HKDevice *device = [[HKDevice alloc] initWithName:[[UIDevice currentDevice] name]
                                         manufacturer:@"Apple"
                                                model:[[UIDevice currentDevice] model]
                                      hardwareVersion:[[UIDevice currentDevice] model]
                                      firmwareVersion:[[UIDevice currentDevice] model]
                                      softwareVersion:[[UIDevice currentDevice] systemVersion]
                                      localIdentifier:[[NSLocale currentLocale] localeIdentifier]
                                  UDIDeviceIdentifier:[[NSLocale currentLocale] localeIdentifier]];
    
    for (int i=0; i<[stepArray count]; i++) {
        NSDate *date = [dateFormatter dateFromString:stepArray[i][@"dateTime"]];
        NSDate *beginDate = date;
        NSDate *endDate = date;
        
        double stepCount = [stepArray[i][@"value"] doubleValue];
        HKQuantity *stepQuantityConsumed = [HKQuantity quantityWithUnit:[HKUnit countUnit] doubleValue:stepCount];
        HKQuantityType *stepConsumedType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        HKQuantitySample *stepConsumedSample = [HKQuantitySample quantitySampleWithType:stepConsumedType
                                                                               quantity:stepQuantityConsumed
                                                                              startDate:beginDate
                                                                                endDate:endDate
                                                                                 device:device
                                                                               metadata:nil];
        [stepNumArray addObject:stepConsumedSample];
    }
    return stepNumArray;
}

//插入睡眠数据分析
+ (NSMutableArray<HKObject *> *)sleepCorrelationWithSleepNum {
    NSArray *sleepArray = [self analyzeSleepData];
    HKCategoryType *categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    HKDevice *device = [[HKDevice alloc] initWithName:@"ww" manufacturer:@"apple" model:@"iphone" hardwareVersion:@"1.0.0" firmwareVersion:@"1.0.0" softwareVersion:@"1.0.0" localIdentifier:@"ww" UDIDeviceIdentifier:@"we"];
    
    NSMutableArray<HKObject *> *sleepNumArray = [[NSMutableArray alloc] init];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    for (int i=0; i<[sleepArray count]; i++) {
        NSString *timeString = [NSString stringWithFormat:@"%@", sleepArray[i][@"dateTime"]];
        NSString *startString = [timeString stringByReplacingOccurrencesOfString:@"T" withString:@" "];
        NSString *dateString = [startString stringByReplacingOccurrencesOfString:@".000" withString:@""];
        NSDate *startDate = [dateFormatter dateFromString:dateString];
        double interval = [sleepArray[i][@"seconds"] doubleValue];
        NSDate *endDate = [startDate dateByAddingTimeInterval:interval];
        NSString *level = sleepArray[i][@"level"];
        NSInteger value;
        if ([level isEqualToString:@"awake"] || [level isEqualToString:@"wake"]) {
            value = 2;
        } else if ([level isEqualToString:@"restless"] || [level isEqualToString:@"rem"]) {
            value = 0;
        } else {
            value = 1;
        }
        
        HKCategorySample *sleepSample = [HKCategorySample categorySampleWithType:categoryType value:value startDate:startDate endDate:endDate device:device metadata:nil];
        [sleepNumArray addObject:sleepSample];
    }
    return sleepNumArray;

}

#pragma mark -- 解析JSON文件
+ (NSArray *)analyzeStepData {
    NSMutableArray *stepArray = [[NSMutableArray alloc] init];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"stepList.json" ofType:nil];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *dictArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    for (NSDictionary *dic in dictArray[@"data"]) {
        [stepArray addObject:dic];
    }
    return stepArray;
}

+ (NSArray *)analyzeSleepData {
    NSMutableArray *sleepArray = [[NSMutableArray alloc] init];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"sleepdata.json" ofType:nil];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *dictArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    for (NSDictionary *dic in dictArray[@"sleep"]) {
        NSArray *dataArray = dic[@"levels"][@"data"];
        for (NSDictionary *dataDic in dataArray) {
            [sleepArray addObject:dataDic];
        }
    }
    return sleepArray;
}

@end
