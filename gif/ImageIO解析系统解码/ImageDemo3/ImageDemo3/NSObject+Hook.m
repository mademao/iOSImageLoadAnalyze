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

void (*orig_copyImageBlockSet)(void *infoRec, void *provider, CGRect rect, CGSize size, void * dict);
void sg_copyImageBlockSet(void *infoRec, void *provider, CGRect rect, CGSize size, void * dict);

void sg_copyImageBlockSet(void *infoRec, void *provider, CGRect rect, CGSize size, void * dict)
{
    orig_copyImageBlockSet(infoRec, provider, rect, size, dict);
}

@implementation NSObject (Hook)

+ (void)load
{
//    rcd_rebind_symbols((struct rcd_rebinding[1]){
//    {
//      "copyImageBlockSet",
//      (void *)sg_copyImageBlockSet,
//      (void **)&orig_copyImageBlockSet
//    }}, 1);
}

@end
