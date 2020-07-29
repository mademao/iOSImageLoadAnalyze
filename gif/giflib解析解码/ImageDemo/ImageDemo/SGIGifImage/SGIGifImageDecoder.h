//
//  SGIGifImageDecoder.h
//  HmtUITest
//
//  Created by shajie on 1/15/17.
//  Copyright © 2017 shajie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SGIGifImageDecoder : NSObject

@property (nonatomic) NSUInteger frameCount;
@property (nonatomic) NSUInteger loopCount;
@property (nonatomic) NSUInteger imageBytesPerFrame;


+ (SGIGifImageDecoder *)decoderWithPath:(NSString *)path;
+ (SGIGifImageDecoder *)decoderWithData:(NSData *)data;

///提供目前内部保存最新图片所在帧位置
- (NSInteger)lastDecodeImageIndex;

- (UIImage *)imageFrameAtIndex:(NSUInteger)index;

- (NSTimeInterval)frameDurationAtIndex:(NSUInteger)index;

- (NSData *)animatedImageData;

@end
