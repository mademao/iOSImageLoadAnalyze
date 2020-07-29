//
//  NSObject+Hook.m
//  ImageDemo3
//
//  Created by mademao on 2020/7/16.
//  Copyright © 2020 mademao. All rights reserved.
//

#import "NSObject+Hook.h"
#import "fishhook.h"
#import <UIKit/UIKit.h>



@implementation NSObject (Hook)

+ (void)load
{
//    rebind_symbols((struct rebinding[1]){
//        {
//            "mmap",
//            sg_mmap,
//            (void *)&orig_mmap
//        }
//    }, 1);
}

@end
