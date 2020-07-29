//
//  ViewController.m
//  ImageDemo3
//
//  Created by mademao on 2020/7/16.
//  Copyright © 2020 mademao. All rights reserved.
//

#import "ViewController.h"
#import <ImageIO/ImageIO.h>

@interface ViewController ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) NSMutableArray<UIImage *> *imageArray;
@property (nonatomic, assign) CGImageSourceRef imageSource;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:self.imageView];
    
    NSData *data = [NSData dataWithContentsOfFile:@"/Users/mademao/Desktop/biggif.gif"];
    
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
//            self.imageView.image = [self.imageArray objectAtIndex:0];
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
    
    
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    
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


@end
