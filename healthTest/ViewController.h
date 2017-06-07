//
//  ViewController.h
//  healthTest
//
//  Created by mosquito on 2017/6/2.
//  Copyright © 2017年 mosquito. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HealthKit/HealthKit.h>

@interface ViewController : UIViewController

@property (nonatomic) HKHealthStore *healthStore;

@end

