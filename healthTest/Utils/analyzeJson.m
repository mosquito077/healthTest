//
//  AnalyzeJson.m
//  healthTest
//
//  Created by mosquito on 2017/6/14.
//  Copyright © 2017年 mosquito. All rights reserved.
//

#import "AnalyzeJson.h"

@implementation AnalyzeJson

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
