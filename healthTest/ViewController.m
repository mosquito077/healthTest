//
//  ViewController.m
//  healthTest
//
//  Created by mosquito on 2017/6/2.
//  Copyright © 2017年 mosquito. All rights reserved.
//

#import "ViewController.h"

typedef NS_ENUM(NSInteger, LHealthType) {
    LHealthTypeFootType = 0,
    LHealthTypeFootMile
};

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *stepCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *stepMileLabel;

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
        NSSet *writeDataTypes = [self dataTypesToWrite];
        NSSet *readDataTypes = [self dataTypesToRead];
        [self.healthStore requestAuthorizationToShareTypes:writeDataTypes readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"你不允许包来访问这些读/写数据类型。error === %@", error);
                return;
            }
        }];
    }
}

#pragma mark - 设置写入权限
- (NSSet *)dataTypesToWrite {
    HKQuantityType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    return [NSSet setWithObjects:stepType, nil];
}

#pragma mark - 设置读取权限
- (NSSet *)dataTypesToRead {
    HKQuantityType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    return [NSSet setWithObjects:stepType, nil];
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
    __weak typeof(self) weakSelf = self;
    NSSet *readType = [NSSet setWithObject:type];
    [self.healthStore requestAuthorizationToShareTypes:nil readTypes:readType completion:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            NSLog(@"没有获取授权");
        } else {
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
