//
//  SGIGifImage.m
//  HmtUITest
//
//  Created by shajie on 1/15/17.
//  Copyright © 2017 shajie. All rights reserved.
//

#import "SGIGifImage.h"
#import <objc/runtime.h>

@interface SGIGifImage ()
{
    SGIGifImageDecoder * _gifDecoder;
    BOOL _handleGifBySelf;
}

- (instancetype)initWithGifDecoder:(id)decoder scale:(CGFloat)scale;

@end

@interface YYImage (SGIGifImageHook)

- (instancetype)initWithDataBySGIGifHook:(NSData *)data scale:(CGFloat)scale;
- (instancetype)initWithContentsOfFileBySGIGifHook:(NSString *)path;

@end


@implementation YYImage (SGIGifImageHook)

- (instancetype)initWithContentsOfFileBySGIGifHook:(NSString *)path
{
    if (!path.length) return nil;
    
    BOOL callOriginal = YES;
    if ([self isMemberOfClass:[YYImage class]]) {
        SGIGifImageDecoder * decoder = [SGIGifImageDecoder decoderWithPath:path];
        if (decoder) {
            YYImage * a = [[SGIGifImage alloc] initWithGifDecoder:decoder scale:1.0f];
            if (a) {
                self = a;
                callOriginal = NO;
            }
        }
        // v5.1.0 屏蔽libjpeg解码
        /*
        SGIJpegImageDecoder *jpegDecoder = [SGIJpegImageDecoder decoderWithPath:path];
        if (jpegDecoder) {
            YYImage *a = [[SGIGifImage alloc] initWithGifDecoder:jpegDecoder scale:1.0];
            if (a) {
                self = a;
                callOriginal = NO;
            }
        }
         */
    }

    if (callOriginal) self = [self initWithContentsOfFileBySGIGifHook:path];
    return self;
}

- (instancetype)initWithDataBySGIGifHook:(NSData *)data scale:(CGFloat)scale
{
    BOOL callOriginal = YES;
    if ([self isMemberOfClass:[YYImage class]])
    {
        // YYImageDetectType 执行效率高，对于 YYImage 通过 initWithData: 初始化做这个判断没问题
        YYImageType type = YYImageDetectType((__bridge CFDataRef)data);
        if (type == YYImageTypeGIF) {
            SGIGifImageDecoder * decoder = [SGIGifImageDecoder decoderWithData:data];
            if (decoder) {
                YYImage * a = [[SGIGifImage alloc] initWithGifDecoder:decoder scale:scale];
                if (a) {
                    self = a;
                    callOriginal = NO;
                }
            }
        }
        // v5.1.0 屏蔽libjpeg解码
        /*
        else if (type == YYImageTypeJPEG) {
            SGIJpegImageDecoder *decoder = [SGIJpegImageDecoder decoderWithData:data];
            if (decoder) {
                YYImage * a = [[SGIGifImage alloc] initWithGifDecoder:decoder scale:scale];
                if (a) {
                    self = a;
                    callOriginal = NO;
                }
            }
        }
         */
    }
    
    // 调用 YYImage 原来的 initWithData: 方法
    if (callOriginal) self = [self initWithDataBySGIGifHook:data scale:scale];
    return self;
}

@end



@implementation SGIGifImage

@synthesize gifImageDecoder = _gifDecoder;

#ifndef FORREVIEW
+ (void)load
{
    // TODO:异常处理，比如没有取到 YYImage 类，没有取到 method 等等
    Method ori_Method =  class_getInstanceMethod([YYImage class], @selector(initWithData:scale:));
    Method my_Method = class_getInstanceMethod([YYImage class], @selector(initWithDataBySGIGifHook:scale:));
    const char *oriTypeDescription = (char *)method_getTypeEncoding(ori_Method);
    const char *myTypeDescription = (char *)method_getTypeEncoding(my_Method);
    IMP originalIMP = method_getImplementation(ori_Method);
    IMP myIMP = method_getImplementation(my_Method);
    class_replaceMethod([YYImage class], @selector(initWithData:scale:), myIMP, oriTypeDescription);
    class_replaceMethod([YYImage class], @selector(initWithDataBySGIGifHook:scale:), originalIMP, myTypeDescription);
    
    Method ori_Method2 =  class_getInstanceMethod([YYImage class], @selector(initWithContentsOfFile:));
    Method my_Method2 = class_getInstanceMethod([YYImage class], @selector(initWithContentsOfFileBySGIGifHook:));
    const char *oriTypeDescription2 = (char *)method_getTypeEncoding(ori_Method2);
    const char *myTypeDescription2 = (char *)method_getTypeEncoding(my_Method2);
    IMP originalIMP2 = method_getImplementation(ori_Method2);
    IMP myIMP2 = method_getImplementation(my_Method2);
    class_replaceMethod([YYImage class], @selector(initWithContentsOfFile:), myIMP2, oriTypeDescription2);
    class_replaceMethod([YYImage class], @selector(initWithContentsOfFileBySGIGifHook:), originalIMP2, myTypeDescription2);
}
#endif

- (instancetype)initWithData:(NSData *)data scale:(CGFloat)scale {
    if (!data.length) return nil;
    
    BOOL callSuper = YES;
    YYImageType type = YYImageDetectType((__bridge CFDataRef)data);
    if (type == YYImageTypeGIF) {
        
        SGIGifImageDecoder * decoder = [SGIGifImageDecoder decoderWithData:data];
        if (decoder) {
            self = [self initWithGifDecoder:decoder scale:scale];
            if (self) callSuper = NO;
        }
    }
    // v5.1.0 屏蔽libjpeg解码
    /*
    if (type == YYImageTypeJPEG) {
        SGIJpegImageDecoder * decoder = [SGIJpegImageDecoder decoderWithData:data];
        if (decoder) {
            self = [self initWithGifDecoder:decoder scale:scale];
            if (self) callSuper = NO;
        }
    }
     */
    
    if (callSuper) {
        // 判断一下 methods swizzling 是否成功，调用原方法名 or hook 方法名
        if ([super respondsToSelector:@selector(initWithDataBySGIGifHook:scale:)])
            self = [super initWithDataBySGIGifHook:data scale:scale];
        else
            self = [super initWithData:data scale:scale];
    }
    
    return self;
}

- (instancetype)initWithContentsOfFile:(NSString *)path {
    if (!path.length) return nil;
    
    BOOL callSuper = YES;
    SGIGifImageDecoder * decoder = [SGIGifImageDecoder decoderWithPath:path];
    if (decoder) {
        self = [self initWithGifDecoder:decoder scale:1.0f];
        if (self) callSuper = NO;
    }
    // v5.1.0 屏蔽libjpeg解码
    /*
    SGIJpegImageDecoder *jpegDecoder = [SGIJpegImageDecoder decoderWithPath:path];
    if (jpegDecoder) {
        self = [self initWithGifDecoder:jpegDecoder scale:1.0f];
        if (self) callSuper = NO;
    }
     */
    if (callSuper) {
        // 判断一下 methods swizzling 是否成功，调用原方法名 or hook 方法名
        if ([super respondsToSelector:@selector(initWithContentsOfFileBySGIGifHook:)])
            self = [super initWithContentsOfFileBySGIGifHook:path];
        else
            self = [super initWithContentsOfFile:path];
    }

    return self;
}

- (instancetype)initWithGifDecoder:(id)decoder scale:(CGFloat)scale {
    if ([decoder isKindOfClass:[SGIGifImageDecoder class]]) {
        UIImage * firstImage = [decoder imageFrameAtIndex:0];
        if (!firstImage) return nil;
        
        self = [self initWithCGImage:firstImage.CGImage scale:scale orientation:firstImage.imageOrientation];
        if (!self) return nil;
        
        _gifDecoder = decoder;
        _handleGifBySelf = YES;
        self.yy_isDecodedForDisplay = YES;
        return self;
    }
    // v5.1.0 屏蔽libjpeg解码
    /*
    else if ([decoder isKindOfClass:[SGIJpegImageDecoder class]]) {
        UIImage * firstImage = [decoder imageFrameAtIndex:0];
        if (!firstImage) return nil;
        
        self = [self initWithCGImage:firstImage.CGImage scale:scale orientation:firstImage.imageOrientation];
        if (!self) return nil;
        
        _jpegDecoder = decoder;
        _handleJpegBySelf = YES;
        self.yy_isDecodedForDisplay = YES;
        return self;
    }
     */
    return nil;
}

//- (instancetype)yy_imageByDecoded
//{
//    if (_handleGifBySelf)
//    {
//        return self;
//    }
//    return [super yy_imageByDecoded];
//}

///
// 重载了 YYImage 的 YYAnimatedImage 协议，
// 如果是 Gif 图片，使用自己的
// 如果不是 Gif 图片，使用 YYImage 的
///
#pragma mark - protocol YYAnimatedImage

- (NSUInteger)animatedImageFrameCount {
    if (_handleGifBySelf) {
        return _gifDecoder.frameCount;
    } else {
        return [super animatedImageFrameCount];
    }
}

- (NSUInteger)animatedImageLoopCount {
    // 0 means infinity
    if (_handleGifBySelf) {
        return _gifDecoder.loopCount;
    } else {
        return [super animatedImageLoopCount];
    }
}

- (NSUInteger)animatedImageBytesPerFrame {
    if (_handleGifBySelf) {
        return _gifDecoder.imageBytesPerFrame;
    } else {
        return [super animatedImageLoopCount];
    }
}

- (UIImage *)animatedImageFrameAtIndex:(NSUInteger)index {
    if (_handleGifBySelf) {
        UIImage * image = [_gifDecoder imageFrameAtIndex:index];
        image.yy_isDecodedForDisplay = YES;
        return image;
    }
    return [super animatedImageFrameAtIndex:index];
}

- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index {
    if (_handleGifBySelf) {
        NSTimeInterval duration = [_gifDecoder frameDurationAtIndex:index];
        
        /*
         http://opensource.apple.com/source/WebCore/WebCore-7600.1.25/platform/graphics/cg/ImageSourceCG.cpp
         Many annoying ads specify a 0 duration to make an image flash as quickly as
         possible. We follow Safari and Firefox's behavior and use a duration of 100 ms
         for any frames that specify a duration of <= 10 ms.
         See <rdar://problem/7689300> and <http://webkit.org/b/36082> for more information.
         
         See also: http://nullsleep.tumblr.com/post/16524517190/animated-gif-minimum-frame-delay-browser.
         */
        //    NSLog(@"----- %zd duration: %.3f ", index, duration);
        if (duration < 0.011f) return 0.100f;
        return duration;
    }

    return [super animatedImageDurationAtIndex:index];
}

@end
