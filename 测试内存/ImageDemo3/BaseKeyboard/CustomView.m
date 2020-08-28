//
//  CustomView.m
//  BaseKeyboard
//
//  Created by mademao on 2020/7/21.
//  Copyright © 2020 mademao. All rights reserved.
//

#import "CustomView.h"
#import <ImageIO/ImageIO.h>
#import "SGIImageMmapManager.h"
#import "TYStatistics.h"

//#define TEST_PNG_UIKitAnalysis_CoreAnimationDecode
//#define TEST_PNG_ImageIOAnalysis_CoreAnimationDecode
//#define TEST_PNG_ImageIOAnalysis_CoreGraphicsDecode
//#define TEST_PNG_ImageIOAnalysis_CoreGraphicsDecode_BitmapContext
//#define TEST_MMAP
//#define TEST_PNG_ImageIOAnalysis_Downsampling
//#define TEST_GIF_UIKitAnalysis_CoreAnimationDecode
//#define TEST_GIF_ImageIOAnalysis_CoreAnimationDecode
//#define TEST_GIF_ImageIOAnalysis_CoreGraphicsDecode
#define TEST_GIF_ImageIOAnalysis_CoreGraphicsDecode_BitmapContext
#define TEST_JPG_ImageIOAnalysis_CoreAnimationDecode
#define TEST_JPG_ImageIOAnalysis_CoreGraphicsDecode

//iPhone5s:48MB iPhone Xs Max 66MB

CGColorSpaceRef YYCGColorSpaceGetDeviceRGB() {
    static CGColorSpaceRef space;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        space = CGColorSpaceCreateDeviceRGB();
    });
    return space;
}

#if defined(TEST_PNG_UIKitAnalysis_CoreAnimationDecode)

/*
 png大小8.94MB，PNG图片解析需要内存13.41MB
 
 CoreaAnimation直接调用PNGReadPlugin解码，只有ImageIO_PNG_Data产生
 iPhone5s:进行3次时，发生崩溃，有低内存崩溃日志；iPhone Xs Max:进行4次时，发生崩溃，有低内存崩溃日志
 VM:ImageIO_PNG_Data    13.73MB     ImageIO     ImageIO_Malloc
 
 结论：ImageIO_PNG_Data计算在消耗内
 */

@interface CustomView ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) NSMutableArray<UIImage *> *imageArray;
@property (nonatomic, strong) NSData *data;

@end

@implementation CustomView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor redColor];
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.imageView];
        
        self.label = [[UILabel alloc] initWithFrame:self.bounds];
        self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.textColor = [UIColor greenColor];
        [self addSubview:self.label];
        
        NSString *fileString = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"png"];
        self.data = [NSData dataWithContentsOfFile:fileString];
    }
    return self;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UIImage *image = [UIImage imageWithData:self.data];
    
    [self.imageArray addObject:image];
    self.imageView.image = image;
    self.label.text = [NSString stringWithFormat:@"%@", @(self.imageArray.count)];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self touchesEnded:nil withEvent:nil];
    });
}

- (NSMutableArray<UIImage *> *)imageArray
{
    if (!_imageArray) {
        _imageArray = [NSMutableArray array];
    }
    return _imageArray;
}

@end

#elif defined(TEST_PNG_ImageIOAnalysis_CoreAnimationDecode)

/*
 png大小8.94MB，PNG图片解析需要内存13.41MB
 
 CoreaAnimation直接调用PNGReadPlugin解码，只有ImageIO_PNG_Data产生
 iPhone5s:进行3次时，发生崩溃，有低内存崩溃日志；iPhone Xs Max:进行4次时，发生崩溃，有低内存崩溃日志
 VM:ImageIO_PNG_Data    13.73MB     ImageIO     ImageIO_Malloc
 
 结论：ImageIO_PNG_Data计算在消耗内
 */

@interface CustomView ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) NSMutableArray<UIImage *> *imageArray;
@property (nonatomic, strong) NSData *data;

@end

@implementation CustomView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor redColor];
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.imageView];
        
        self.label = [[UILabel alloc] initWithFrame:self.bounds];
        self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.textColor = [UIColor greenColor];
        [self addSubview:self.label];
        
        NSString *fileString = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"png"];
        self.data = [NSData dataWithContentsOfFile:fileString];
    }
    return self;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)self.data, NULL);
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
    
    NSInteger width = 0, height = 0;
    CFTypeRef value = NULL;
    value = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
    if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &width);
    value = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
    if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &height);
    
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache:@(YES)});

    UIImage *image = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    CFRelease(properties);
    
    [self.imageArray addObject:image];
    self.imageView.image = image;
    self.label.text = [NSString stringWithFormat:@"%@", @(self.imageArray.count)];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self touchesEnded:nil withEvent:nil];
    });
}

- (NSMutableArray<UIImage *> *)imageArray
{
    if (!_imageArray) {
        _imageArray = [NSMutableArray array];
    }
    return _imageArray;
}

@end

#elif defined(TEST_PNG_ImageIOAnalysis_CoreGraphicsDecode)

/*
 png大小8.94MB，PNG图片解析需要内存13.41MB
 测试CoreGraphics解码是否占用内存
 
 CoreGraphics解码最后只有DataProvider产生
 iPhone5s:进行53次时，发生崩溃，Xcode内存显示稳定；iPhone Xs Max:进行320次时，发生崩溃，Xcode内存显示稳定
 
 结论：CoreGraphics解码png图片内存稳定，但需注意低版本手机上DataProvider通过mmap映射大小有限制
 */

@interface CustomView ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) NSMutableArray<UIImage *> *imageArray;
@property (nonatomic, strong) NSData *data;

@end

@implementation CustomView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor redColor];
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.imageView];
        
        self.label = [[UILabel alloc] initWithFrame:self.bounds];
        self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.textColor = [UIColor greenColor];
        [self addSubview:self.label];
        
        NSString *fileString = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"png"];
        self.data = [NSData dataWithContentsOfFile:fileString];
    }
    return self;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)self.data, NULL);
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
    
    NSInteger width = 0, height = 0;
    CFTypeRef value = NULL;
    value = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
    if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &width);
    value = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
    if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &height);
    
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache:@(YES)});

    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef) & kCGBitmapAlphaInfoMask;
    BOOL hasAlpha = NO;
    if (alphaInfo == kCGImageAlphaPremultipliedLast ||
        alphaInfo == kCGImageAlphaPremultipliedFirst ||
        alphaInfo == kCGImageAlphaLast ||
        alphaInfo == kCGImageAlphaFirst) {
        hasAlpha = YES;
    }
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, YYCGColorSpaceGetDeviceRGB(), bitmapInfo);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGImageRef newImage = CGBitmapContextCreateImage(context);

    UIImage *image = [UIImage imageWithCGImage:newImage];

    CGContextRelease(context);
    CGImageRelease(newImage);
    
    CGImageRelease(imageRef);
    CFRelease(properties);
    CFRelease(imageSource);
    
    [self.imageArray addObject:image];
    self.imageView.image = image;
    self.label.text = [NSString stringWithFormat:@"%@", @(self.imageArray.count)];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self touchesEnded:nil withEvent:nil];
    });
}

- (NSMutableArray<UIImage *> *)imageArray
{
    if (!_imageArray) {
        _imageArray = [NSMutableArray array];
    }
    return _imageArray;
}

@end

#elif defined(TEST_PNG_ImageIOAnalysis_CoreGraphicsDecode_BitmapContext)

/*
 png大小8.94MB，PNG图片解析需要内存13.41MB
 测试CoreGraphics解码是否占用内存
 
 CoreGraphics解码最后只有DataProvider产生
 iPhone5s:进行27次时，发生崩溃，Xcode内存显示稳定；iPhone Xs Max:进行163次时，发生崩溃，Xcode内存显示稳定
 
 结论：CoreGraphics解码png图片内存稳定，但需注意低版本手机上DataProvider通过mmap映射大小有限制
 */

@interface CustomView ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) NSMutableArray<UIImage *> *imageArray;
@property (nonatomic, strong) NSData *data;

@end

@implementation CustomView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor redColor];
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.imageView];
        
        self.label = [[UILabel alloc] initWithFrame:self.bounds];
        self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.textColor = [UIColor greenColor];
        [self addSubview:self.label];
        
        NSString *fileString = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"png"];
        self.data = [NSData dataWithContentsOfFile:fileString];
    }
    return self;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)self.data, NULL);
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
    
    NSInteger width = 0, height = 0;
    CFTypeRef value = NULL;
    value = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
    if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &width);
    value = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
    if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &height);
    
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache:@(YES)});

    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef) & kCGBitmapAlphaInfoMask;
    BOOL hasAlpha = NO;
    if (alphaInfo == kCGImageAlphaPremultipliedLast ||
        alphaInfo == kCGImageAlphaPremultipliedFirst ||
        alphaInfo == kCGImageAlphaLast ||
        alphaInfo == kCGImageAlphaFirst) {
        hasAlpha = YES;
    }
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, YYCGColorSpaceGetDeviceRGB(), bitmapInfo);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGImageRef newImage = CGBitmapContextCreateImage(context);

    UIImage *image = [UIImage imageWithCGImage:newImage];

//    CGContextRelease(context);
    CGImageRelease(newImage);
    
    CGImageRelease(imageRef);
    CFRelease(properties);
    CFRelease(imageSource);
    
    [self.imageArray addObject:image];
    self.imageView.image = image;
    self.label.text = [NSString stringWithFormat:@"%@", @(self.imageArray.count)];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self touchesEnded:nil withEvent:nil];
    });
}

- (NSMutableArray<UIImage *> *)imageArray
{
    if (!_imageArray) {
        _imageArray = [NSMutableArray array];
    }
    return _imageArray;
}

@end


#elif defined(TEST_MMAP)

/*
 测试mmap是否有系统内存大小限制
 1.iOS13以下 iPhone5s:
 进行到97次时，发生崩溃，并有进程崩溃日志产生，内容说明内核错误：KERN_INVALID_ADDRESS
 
 结论：mmap有内存大小限制
 
 2.iOS13以上 iPhone Xs Max：
 进行到320次时，发生崩溃，并有进程崩溃日志产生，内容说明内核错误：KERN_INVALID_ADDRESS
 
 结论：mmap有内存大小限制
*/

@interface CustomView ()

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, assign) NSInteger count;

@end

@implementation CustomView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor redColor];
        
        self.label = [[UILabel alloc] initWithFrame:self.bounds];
        self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.textColor = [UIColor greenColor];
        [self addSubview:self.label];
    }
    return self;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    int size = 20 * 1024.0 * 1024.0;
    void *memory = [SGIImageMmapManager createMmapFile:[NSString stringWithFormat:@"/%@", @(self.count)] size:size];
    memset(memory, 0, size);
    self.count++;
    
    self.label.text = [NSString stringWithFormat:@"%@", @(self.count)];
    NSLog(@"---%@", @(self.count));
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self touchesEnded:nil withEvent:nil];
    });
}

@end


#elif defined(TEST_PNG_ImageIOAnalysis_Downsampling)

/*
 下采样内部是使用CoreGraphics进行重绘解码的
 但比主动调用CoreGraphics来说，在触发ImageIO解码时，是直接解码为目标尺寸，所以解码时内存消耗较小
*/
@interface CustomView ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) NSMutableArray<UIImage *> *imageArray;
@property (nonatomic, strong) NSData *data;

@end

@implementation CustomView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor redColor];
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.imageView];
        
        self.label = [[UILabel alloc] initWithFrame:self.bounds];
        self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.textColor = [UIColor greenColor];
        [self addSubview:self.label];
        
        NSString *fileString = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"png"];
        self.data = [NSData dataWithContentsOfFile:fileString];
    }
    return self;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)self.data, NULL);
    
    NSDictionary *options = @{(id)kCGImageSourceShouldCacheImmediately : @(YES),
                              (id)kCGImageSourceCreateThumbnailWithTransform : @(YES),
                              (id)kCGImageSourceCreateThumbnailFromImageIfAbsent : @(YES),
                              (id)kCGImageSourceThumbnailMaxPixelSize : @(1000)
    };
    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (CFDictionaryRef)options);

    UIImage *image = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    CFRelease(imageSource);
    
    [self.imageArray addObject:image];
    self.imageView.image = image;
    self.label.text = [NSString stringWithFormat:@"%@", @(self.imageArray.count)];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self touchesEnded:nil withEvent:nil];
    });
}

- (NSMutableArray<UIImage *> *)imageArray
{
    if (!_imageArray) {
        _imageArray = [NSMutableArray array];
    }
    return _imageArray;
}

@end


#elif defined(TEST_GIF_UIKitAnalysis_CoreAnimationDecode)

/*
gif大小1.31MB，gif图片解析需要内存5.25MB
 测试ImageIO_GIF_Data、GIFBufferInfo和ColorIndex是否被计算入系统内存大小
 1.iOS13以下 iPhone5s:
 最后保留：
 VM:ImageIO_GIF_Data    5.25MB  ImageIO     ImageIO_Malloc
 Malloc 5.25MB          5.25MB  ImageIO     GlobalGIFInfo::getBufferInfo(unsigned int, bool)
 临时使用：
 Malloc 1.31MB          1.31MB  ImageIO     GIFReadPlugin::doCopyImageBlockSet(GlobalGIFInfo*, unsigned char*, unsigned long, GIFBufferInfo*, bool*)
 
 在第5次时发生低内存崩溃
 结论：解码中会有3类内存
 （1）解码后数据：ImageIO_GIF_Data 计算在消耗内
 （2）上一帧保存数据：GIFBufferInfo 计算在消耗内
 （3）像素下标数据：临时使用，malloc，计算在消耗内
 
 2.iOS13以上 iPhone Xs Max：
 数据及结论同上，会在第6次时发生低内存崩溃，崩溃在GIFReadPlugin::CreateFrameBufferAtIndex(CGRect const&, unsigned long, IIOImageReadSession*, GlobalGIFInfo*, ReadPluginData const&, GIFPluginData const&)，此步会生成像素下标数据
*/

@interface CustomView ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) NSMutableArray<UIImage *> *imageArray;
@property (nonatomic, strong) NSData *data;

@end

@implementation CustomView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor redColor];
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.imageView];
        
        self.label = [[UILabel alloc] initWithFrame:self.bounds];
        self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.textColor = [UIColor greenColor];
        [self addSubview:self.label];
        
        NSString *fileString = [[NSBundle mainBundle] pathForResource:@"midgif" ofType:@"gif"];
        self.data = [NSData dataWithContentsOfFile:fileString];
    }
    return self;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UIImage *image = [UIImage imageWithData:self.data];
    
    [self.imageArray addObject:image];
    self.imageView.image = image;
    self.label.text = [NSString stringWithFormat:@"%@", @(self.imageArray.count)];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self touchesEnded:nil withEvent:nil];
    });
}

- (NSMutableArray<UIImage *> *)imageArray
{
    if (!_imageArray) {
        _imageArray = [NSMutableArray array];
    }
    return _imageArray;
}

@end

#elif defined(TEST_GIF_ImageIOAnalysis_CoreAnimationDecode)

/*
gif大小1.31MB，gif图片解析需要内存5.25MB
 测试ImageIO_GIF_Data、GIFBufferInfo和ColorIndex是否被计算入系统内存大小
 1.iOS13以下 iPhone5s:
 最后保留：
 VM:ImageIO_GIF_Data    5.25MB  ImageIO     ImageIO_Malloc
 Malloc 5.25MB          5.25MB  ImageIO     GlobalGIFInfo::getBufferInfo(unsigned int, bool)
 临时使用：
 Malloc 1.31MB          1.31MB  ImageIO     GIFReadPlugin::doCopyImageBlockSet(GlobalGIFInfo*, unsigned char*, unsigned long, GIFBufferInfo*, bool*)
 
 在第5次时发生低内存崩溃
 结论：解码中会有3类内存
 （1）解码后数据：ImageIO_GIF_Data 计算在消耗内
 （2）上一帧保存数据：GIFBufferInfo 计算在消耗内
 （3）像素下标数据：临时使用，malloc，计算在消耗内
 
 2.iOS13以上 iPhone Xs Max：
 数据及结论同上，会在第6次时发生低内存崩溃，崩溃在GIFReadPlugin::CreateFrameBufferAtIndex(CGRect const&, unsigned long, IIOImageReadSession*, GlobalGIFInfo*, ReadPluginData const&, GIFPluginData const&)，此步会生成像素下标数据
*/

@interface CustomView ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) NSMutableArray<UIImage *> *imageArray;
@property (nonatomic, strong) NSData *data;

@end

@implementation CustomView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor redColor];
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.imageView];
        
        self.label = [[UILabel alloc] initWithFrame:self.bounds];
        self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.textColor = [UIColor greenColor];
        [self addSubview:self.label];
        
        NSString *fileString = [[NSBundle mainBundle] pathForResource:@"midgif" ofType:@"gif"];
        self.data = [NSData dataWithContentsOfFile:fileString];
    }
    return self;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)self.data, NULL);
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
    
    NSInteger width = 0, height = 0;
    CFTypeRef value = NULL;
    value = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
    if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &width);
    value = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
    if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &height);
    
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache:@(YES)});

    UIImage *image = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    CFRelease(properties);
    
    [self.imageArray addObject:image];
    self.imageView.image = image;
    self.label.text = [NSString stringWithFormat:@"%@", @(self.imageArray.count)];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self touchesEnded:nil withEvent:nil];
    });
}

- (NSMutableArray<UIImage *> *)imageArray
{
    if (!_imageArray) {
        _imageArray = [NSMutableArray array];
    }
    return _imageArray;
}

@end
 
#elif defined(TEST_GIF_ImageIOAnalysis_CoreGraphicsDecode)

/*
gif大小1.31MB，gif图片解析需要内存5.25MB
 测试ProviderData是否被计算入系统内存大小
 1.iOS13以下 iPhone5s:
 最后保留：
 VM:CG raster data      5.25MB  CoreGraphics        CGDataProviderCreateWithCopyOfData
 临时使用：
 上一个测试中所用到的内存
 (1)VM:CG image         5.25MB  CoreGraphics        CGBitmapAllocateData
 (2)CGSImageHandle      5.25MB  CoreGraphics        create_image_data_handle
 
 在第213次时发生崩溃，有低内存崩溃日志，但日志中进程所占内存保持在10M左右，发生崩溃时间是在ProviderData共计1G左右
 结论：解码中除上一个测试所用到的内存，还有1类内存
 （1）绘制解码后数据：ProviderData 不计算在消耗内，但可能受系统限制，下一步进行验证
 （2）画布内存：BitmapAllocateData 暂不清楚是否计算在消耗内，下一步进行验证
 
 2.iOS13以上 iPhone Xs Max：
 最后保留：
    同iOS13以下
 临时使用：
    同iOS13以下
 
 测试了1000次未发生崩溃，Xcode显示内存稳定
 结论：同iOS13以下
*/

@interface CustomView ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) NSMutableArray<UIImage *> *imageArray;
@property (nonatomic, assign) CGImageSourceRef imageSource;

@end

@implementation CustomView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor redColor];
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.imageView];
        
        self.label = [[UILabel alloc] initWithFrame:self.bounds];
        self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.textColor = [UIColor greenColor];
        [self addSubview:self.label];
        
        NSString *fileString = [[NSBundle mainBundle] pathForResource:@"midgif" ofType:@"gif"];
        NSData *data = [NSData dataWithContentsOfFile:fileString];
        self.imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    }
    return self;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSInteger index = self.imageArray.count % 20;
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(self.imageSource, index, NULL);
    
    NSInteger width = 0, height = 0;
    CFTypeRef value = NULL;
    value = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
    if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &width);
    value = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
    if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &height);
    
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(self.imageSource, index, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache:@(YES)});

    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef) & kCGBitmapAlphaInfoMask;
    BOOL hasAlpha = NO;
    if (alphaInfo == kCGImageAlphaPremultipliedLast ||
        alphaInfo == kCGImageAlphaPremultipliedFirst ||
        alphaInfo == kCGImageAlphaLast ||
        alphaInfo == kCGImageAlphaFirst) {
        hasAlpha = YES;
    }
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, YYCGColorSpaceGetDeviceRGB(), bitmapInfo);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGImageRef newImage = CGBitmapContextCreateImage(context);

    UIImage *image = [UIImage imageWithCGImage:newImage];

    CGContextRelease(context);
    CGImageRelease(newImage);
    
    CGImageRelease(imageRef);
    CFRelease(properties);
    
    [self.imageArray addObject:image];
    self.imageView.image = image;
    self.label.text = [NSString stringWithFormat:@"%@", @(self.imageArray.count)];
    NSLog(@"---%@", @(self.imageArray.count));
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self touchesEnded:nil withEvent:nil];
    });
}

- (NSMutableArray<UIImage *> *)imageArray
{
    if (!_imageArray) {
        _imageArray = [NSMutableArray array];
    }
    return _imageArray;
}

@end


#elif defined(TEST_GIF_ImageIOAnalysis_CoreGraphicsDecode_BitmapContext)

/*
gif大小1.31MB，gif图片解析需要内存5.25MB
 测试CGBitmapAllocateData是否计算在消耗内
 1.iOS13以下 iPhone5s:
 进行到216次时，发生崩溃，Xcode显示内存稳定
 
 结论：CGBitmapAllocateData不计算在消耗内，同时由216次发生崩溃可进一步验证，mmap大小受到系统内存限制
 
 2.iOS13以上 iPhone Xs Max：
 进行到1294次时，发生崩溃，Xcode显示内存稳定
 
 结论：CGBitmapAllocateData不计算在消耗内，同时由1294次发生崩溃可进一步验证，mmap大小受到系统内存限制
*/

@interface CustomView ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, assign) CGImageSourceRef imageSource;
@property (nonatomic, assign) NSInteger count;

@end

@implementation CustomView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor redColor];
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.imageView];
        
        self.label = [[UILabel alloc] initWithFrame:self.bounds];
        self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.textColor = [UIColor greenColor];
        [self addSubview:self.label];
        
        NSString *fileString = [[NSBundle mainBundle] pathForResource:@"midgif" ofType:@"gif"];
        NSData *data = [NSData dataWithContentsOfFile:fileString];
        self.imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    }
    return self;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSInteger index = self.count % 20;
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(self.imageSource, index, NULL);
    
    NSInteger width = 0, height = 0;
    CFTypeRef value = NULL;
    value = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
    if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &width);
    value = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
    if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &height);
    
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(self.imageSource, index, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache:@(YES)});

    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef) & kCGBitmapAlphaInfoMask;
    BOOL hasAlpha = NO;
    if (alphaInfo == kCGImageAlphaPremultipliedLast ||
        alphaInfo == kCGImageAlphaPremultipliedFirst ||
        alphaInfo == kCGImageAlphaLast ||
        alphaInfo == kCGImageAlphaFirst) {
        hasAlpha = YES;
    }
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, YYCGColorSpaceGetDeviceRGB(), bitmapInfo);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGImageRef newImage = CGBitmapContextCreateImage(context);

    UIImage *image = [UIImage imageWithCGImage:newImage];

    //无CGContextRelease(context);
    CGImageRelease(newImage);
    
    CGImageRelease(imageRef);
    CFRelease(properties);
    
    self.imageView.image = image;
    self.count++;
    self.label.text = [NSString stringWithFormat:@"%@", @(self.count)];
    NSLog(@"---%@", @(self.count));
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self touchesEnded:nil withEvent:nil];
    });
}

@end

#elif defined(TEST_JPG_ImageIOAnalysis_CoreAnimationDecode)

/*
 jpg大小924KB
 
 iPhone5s iOS11: 每次解码会生成1个ImageIO_jpeg_Data(ImageIO_AppleJPEG_Data iOS12)、1个Malloc 912.00KB和1个Malloc 128.00KB
 进行3次时，发生崩溃，有低内存崩溃日志
 VM:ImageIO_jpeg_Data   14.06MB     ImageIO     AppleJPEGReadPlugin::copyImageBlockSet(InfoRec*, CGImageProvider*, CGRect, CGSize, __CFDictionary const*)
 Malloc 912.00KB        912.00KB    AppleJPEG   mmap_multiscan
 Malloc 128.00KB        128.00KB    AppleJPEG   aj_decode_init
 
 iPhone Xs Max iOS13:每次解码会生成1个IOSurface、1个Malloc 912.00KB和1个Malloc 128.00KB
 进行9次时，发生崩溃，有低内存崩溃日志
 VM:IOSurface       5.28MB      ImageIO     AppleJPEGReadPlugin::copyIOSurfaceCallback_sw(InfoRec*, CGImageProvider*, __CFDictionary const*)
 Malloc 912.00KB    912.00KB    AppleJPEG   mmap_multiscan
 Malloc 128.00KB    128.00KB    AppleJPEG   aj_decode_init
 
 
 结论：以上所有内存均被计算在内
 */

@interface CustomView ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) NSMutableArray<UIImage *> *imageArray;
@property (nonatomic, strong) NSData *data;

@end

@implementation CustomView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor redColor];
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.imageView];
        
        self.label = [[UILabel alloc] initWithFrame:self.bounds];
        self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.textColor = [UIColor greenColor];
        [self addSubview:self.label];
        
        NSString *fileString = [[NSBundle mainBundle] pathForResource:@"2" ofType:@"jpeg"];
        self.data = [NSData dataWithContentsOfFile:fileString];
    }
    return self;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)self.data, NULL);
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
    
    NSInteger width = 0, height = 0;
    CFTypeRef value = NULL;
    value = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
    if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &width);
    value = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
    if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &height);
    
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache:@(YES)});

    UIImage *image = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    CFRelease(properties);
    
    [self.imageArray addObject:image];
    self.imageView.image = image;
    self.label.text = [NSString stringWithFormat:@"%@", @(self.imageArray.count)];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self touchesEnded:nil withEvent:nil];
    });
}

- (NSMutableArray<UIImage *> *)imageArray
{
    if (!_imageArray) {
        _imageArray = [NSMutableArray array];
    }
    return _imageArray;
}

@end

#elif defined(TEST_JPG_ImageIOAnalysis_CoreGraphicsDecode)

/*
 jpg大小924KB，jpg图片解析需要内存14.06MB
 测试CoreGraphics解码是否占用内存
 
 CoreGraphics解码最后只有DataProvider产生
 iPhone5s:进行57次时，发生崩溃，Xcode内存显示稳定；iPhone Xs Max:进行300次时，未发生崩溃，Xcode内存显示稳定
 
 结论：CoreGraphics解码jpg图片内存稳定，但需注意低版本手机上DataProvider通过mmap映射大小有限制
 */

@interface CustomView ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) NSMutableArray<UIImage *> *imageArray;
@property (nonatomic, strong) NSData *data;

@end

@implementation CustomView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor redColor];
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.imageView];
        
        self.label = [[UILabel alloc] initWithFrame:self.bounds];
        self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.textColor = [UIColor greenColor];
        [self addSubview:self.label];
        
        NSString *fileString = [[NSBundle mainBundle] pathForResource:@"2" ofType:@"jpeg"];
        self.data = [NSData dataWithContentsOfFile:fileString];
    }
    return self;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)self.data, NULL);
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
    
    NSInteger width = 0, height = 0;
    CFTypeRef value = NULL;
    value = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
    if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &width);
    value = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
    if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &height);
    
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache:@(YES)});

    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef) & kCGBitmapAlphaInfoMask;
    BOOL hasAlpha = NO;
    if (alphaInfo == kCGImageAlphaPremultipliedLast ||
        alphaInfo == kCGImageAlphaPremultipliedFirst ||
        alphaInfo == kCGImageAlphaLast ||
        alphaInfo == kCGImageAlphaFirst) {
        hasAlpha = YES;
    }
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, YYCGColorSpaceGetDeviceRGB(), bitmapInfo);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGImageRef newImage = CGBitmapContextCreateImage(context);

    UIImage *image = [UIImage imageWithCGImage:newImage];

    CGContextRelease(context);
    CGImageRelease(newImage);
    
    CGImageRelease(imageRef);
    CFRelease(properties);
    CFRelease(imageSource);
    
    [self.imageArray addObject:image];
    self.imageView.image = image;
    self.label.text = [NSString stringWithFormat:@"%@", @(self.imageArray.count)];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self touchesEnded:nil withEvent:nil];
    });
}

- (NSMutableArray<UIImage *> *)imageArray
{
    if (!_imageArray) {
        _imageArray = [NSMutableArray array];
    }
    return _imageArray;
}

@end

#endif
