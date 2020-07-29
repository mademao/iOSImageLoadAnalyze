//
//  TYStatistics.h
//  TYActions
//
//  Created by ydhz on 2017/9/18.
//  Copyright © 2017年 ydhz. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef struct SGSystemMemoryInfo {
    float residentSize;
    float usedSize;
    float internalPeak;
} SGSystemMemoryInfo;

@interface TYStatistics : NSObject
+ (float)residentSizeOfMemory;
+ (float)usedSizeOfMemory;
+ (float)realFootprint;
+ (float)internalPeakOfMemory;
+ (NSString *)stringOfResidentMemorySize;
+ (NSString *)systemMemoryState;
+ (float)systemCpuUsage;
@end
