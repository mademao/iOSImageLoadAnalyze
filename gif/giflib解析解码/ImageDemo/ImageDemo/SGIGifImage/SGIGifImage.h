//
//  SGIGifImage.h
//  HmtUITest
//
//  Created by shajie on 1/15/17.
//  Copyright © 2017 shajie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YYImage.h"
#import "SGIGifImageDecoder.h"


/************************************************************************
 * SGIGifImage 介绍
 * 1. 实现原理
 *      SGIGifImage 基于 YYImage 和 giflib 两个开源库实现，
 *      通过 Objective-C Method Swizzling 替换了 YYImage 两个重要的初始化方法，
 *      对于 Gif 图片，优先使用 SGIGifImageDecoder 进行解码，SGIGifImageDecoder 封装了
 *      giflib，并模仿 YYAnimateImage 协议实现了动态展示 Gif 需要的若干接口。
 *      对于非 Gif 图片，仍然使用 YYImage 原有实现。
 * 2. 使用方法
 *      YYImage 常见的使用场景包括
 *      a. YYImage 的 imageWithName，imageWithContentsOfFile，imageWithData 等方法直接生成 YYImage 实例
 *      b. UIImageView + YYWebImage 的 yy_setImageWithURL 系列方法
 *      SGIGifImage 对以上两种方式对上层调用保持透明化，上层仍然按照原来的方式调用即可
 * 3. 性能评估
 *      a. 内存节省主要来自解码过程，通过系统 ImageIO 解码至少需要占用一帧 bitmap 大小的内存值
 *          通过 giflib 进行解码，通过 mmap 申请的解码 buffer 不算到苹果 mem_used 公式里
 *************************************************************************/
@interface SGIGifImage : YYImage

@property (nonatomic, strong, readonly) SGIGifImageDecoder *gifImageDecoder;

@end
