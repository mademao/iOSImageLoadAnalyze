//
//  ViewController.m
//  ImageDemo
//
//  Created by mademao on 2020/7/15.
//  Copyright © 2020 mademao. All rights reserved.
//

#import "ViewController.h"
#import "YYWebImage.h"
#import "YYAnimatedImageView.h"

@interface ViewController ()

@property (nonatomic, strong) YYAnimatedImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageView = [[YYAnimatedImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:self.imageView];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSString *fileString = [[NSBundle mainBundle] pathForResource:@"biggif" ofType:@"gif"];
    NSData *data = [NSData dataWithContentsOfFile:fileString];
    YYImage *image = [YYImage imageWithData:data];
    self.imageView.image = image;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.imageView.image = nil;
    });
}


@end
