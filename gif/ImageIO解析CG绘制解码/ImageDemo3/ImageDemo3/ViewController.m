//
//  ViewController.m
//  ImageDemo3
//
//  Created by mademao on 2020/7/16.
//  Copyright © 2020 mademao. All rights reserved.
//

#import "ViewController.h"
#import <ImageIO/ImageIO.h>

CGColorSpaceRef YYCGColorSpaceGetDeviceRGB() {
    static CGColorSpaceRef space;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        space = CGColorSpaceCreateDeviceRGB();
    });
    return space;
}

@interface ViewController ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) NSMutableArray<UIImage *> *imageArray;
@property (nonatomic, assign) CGImageSourceRef imageSource;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
//    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
    
    NSString *fileString = [[NSBundle mainBundle] pathForResource:@"biggif" ofType:@"gif"];
    NSData *data = [NSData dataWithContentsOfFile:fileString];
//    NSString *fileString = [[NSBundle mainBundle] pathForResource:@"2" ofType:@"jpeg"];
//    NSData *data = [NSData dataWithContentsOfFile:fileString];
//    NSData *data = [NSData dataWithContentsOfFile:@"/Users/mademao/Desktop/1.png"];
//    NSData *data = [NSData dataWithContentsOfFile:@"/Users/mademao/Desktop/2.jpeg"];
//    NSData *data = [NSData dataWithContentsOfFile:@"/Users/mademao/Desktop/biggif.gif"];
    
    self.imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSInteger index = self.imageArray.count;
 
    if (index == 2) {
        CFRelease(self.imageSource);
        self.imageSource = nil;
        self.imageView.image = nil;
        [self.imageArray removeAllObjects];
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
////            [self.imageArray addObject:self.imageView.image];
//            [self.imageArray removeLastObject];
//            self.imageView.image = nil;
//        });
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            self.imageView.image = [self.imageArray objectAtIndex:0];
//            [self.imageArray removeAllObjects];
//        });
        return;
    }
    
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

//    UIImage *image = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    CFRelease(properties);
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.imageArray addObject:image];
        self.imageView.image = image;
    });
}

- (NSMutableArray<UIImage *> *)imageArray
{
    if (!_imageArray) {
        _imageArray = [NSMutableArray array];
    }
    return _imageArray;
}

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)radius {
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height) cornerRadius:radius];
    [bezierPath fill];
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}


@end
