//
//  YYImageDecoder+LimitSize.m
//  BaseKeyboard
//
//  Created by lina on 2019/3/7.
//  Copyright © 2019 Sogou.Inc. All rights reserved.
//

#import "YYImageDecoder+LimitSize.h"
#import <objc/runtime.h>

NSString *const kImageDecodeLimitedSize = @"kImageDecodeLimitedSize";

static NSValue *limitedSizeValue = nil;

@implementation YYImageDecoder (LimitSize)

+ (void)setLimitedSizeValue:(NSValue *)value
{
    if (value == nil) {
        return;
    }
    
    limitedSizeValue = value;
}

+ (NSValue *)defaultLimitedSizeValue
{
    CGSize size = CGSizeMake(700, 700); // default size: 700*700
    return [NSValue valueWithCGSize:size];
}

- (NSValue *)limitedSizeValue {
    if (limitedSizeValue == nil) {
        [YYImageDecoder setLimitedSizeValue:[YYImageDecoder defaultLimitedSizeValue]];
    }
    return limitedSizeValue;
}

- (NSNumber *)resizeRatioValue {
    return objc_getAssociatedObject(self, @selector(resizeRatioValue));
}

- (void)setResizeRatioValue:(NSNumber *)value {
    objc_setAssociatedObject(self, @selector(resizeRatioValue), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSValue *)displaySizeValue {
    return objc_getAssociatedObject(self, @selector(displaySizeValue));
}

- (void)setDisplaySizeValue:(NSValue *)value {
    objc_setAssociatedObject(self, @selector(displaySizeValue), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
