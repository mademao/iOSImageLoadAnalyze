//
//  ViewController.m
//  ImageDemo3
//
//  Created by mademao on 2020/7/16.
//  Copyright © 2020 mademao. All rights reserved.
//

#import "ViewController.h"
#import <ImageIO/ImageIO.h>
#import "TYStatistics.h"

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
@property (nonatomic, strong) NSMutableArray<UIImageView *> *imageViewArray;
@property (nonatomic, strong) NSMutableArray<UIImage *> *imageArray;
@property (nonatomic, assign) CGImageSourceRef imageSource;
//@property (nonatomic, strong) NSData *data;

@end

@implementation ViewController
/*
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGFloat length = floor([UIScreen mainScreen].bounds.size.width / 5.0);
    CGFloat x = 0, y = 0;
    for (int i = 0; i < 50; i++) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, length, length)];
        imageView.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
        [self.view addSubview:imageView];
        [self.imageViewArray addObject:imageView];
        if (i % 5 == 0 && i != 0) {
            x = 0;
            y += length;
        } else {
            x += length;
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"png" ofType:@"txt"];
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
        for (int i = 0; i < 50; i++) {
            UIImageView *imageView = [self.imageViewArray objectAtIndex:i];
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:jsonArray[i]]];
            imageView.image = [UIImage imageWithData:data];
        }
    });
}
*/


- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
//    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
    
    NSString *fileString = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"png"];
//    NSString *fileString = @"/Users/mademao/Desktop/1.png";
    NSData *data = [NSData dataWithContentsOfFile:fileString];
//    NSString *fileString = [[NSBundle mainBundle] pathForResource:@"2" ofType:@"jpeg"];
//    NSData *data = [NSData dataWithContentsOfFile:fileString];
//    NSData *data = [NSData dataWithContentsOfFile:@"/Users/mademao/Desktop/1.png"];
//    NSData *data = [NSData dataWithContentsOfFile:@"/Users/mademao/Desktop/2.jpeg"];
//    NSData *data = [NSData dataWithContentsOfFile:@"/Users/mademao/Desktop/biggif.gif"];
    
    self.imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
//    self.data = data;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
//    NSLog(@"%@", @([TYStatistics usedSizeOfMemory]));
    NSInteger index = 0;
 
//    if (index == 1) {
//        CFRelease(self.imageSource);
//        self.imageSource = nil;
////        self.imageView.image = nil;
////        [self.imageArray removeAllObjects];
////        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//////            [self.imageArray addObject:self.imageView.image];
////            [self.imageArray removeLastObject];
////            self.imageView.image = nil;
////        });
////        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
////            self.imageView.image = [self.imageArray objectAtIndex:0];
////            [self.imageArray removeAllObjects];
////        });
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            NSLog(@"%@", @([TYStatistics usedSizeOfMemory]));
//        });
//        return;
//    }
    
//    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)self.data, NULL);
    
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
    
//    NSLog(@"1  %@ %@", @(self.imageArray.count), @([TYStatistics usedSizeOfMemory]));

    CGContextRelease(context);
    CGImageRelease(newImage);

//    UIImage *image = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    CFRelease(properties);
    
    CFRelease(self.imageSource);
    self.imageSource = nil;
    
    [self.imageArray addObject:image];
    self.imageView.image = image;
    
    NSLog(@"2  %@ %@", @(self.imageArray.count), @([TYStatistics usedSizeOfMemory]));
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self touchesEnded:nil withEvent:nil];
        [self.imageArray removeAllObjects];
        self.imageView.image = nil;
//        self.data = nil;
    });
}


- (NSMutableArray<UIImageView *> *)imageViewArray
{
    if (!_imageViewArray) {
        _imageViewArray = [NSMutableArray array];
    }
    return _imageViewArray;
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
