//
//  YYImageDecoder+LimitSize.h
//  BaseKeyboard
//
//  Created by lina on 2019/3/7.
//  Copyright © 2019 Sogou.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYImage.h"

@interface YYImageDecoder (LimitSize)
@property (nonatomic, strong) NSNumber *resizeRatioValue;
@property (nonatomic, strong) NSValue *displaySizeValue;
@property (nonatomic, strong, readonly) NSValue *limitedSizeValue;

+ (void)setLimitedSizeValue:(NSValue *)value;
+ (NSValue *)defaultLimitedSizeValue;

@end
