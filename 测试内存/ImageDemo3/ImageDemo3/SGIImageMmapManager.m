//
//  SGIImageMmapManager.m
//  BaseKeyboard
//
//  Created by lina on 26/11/2017.
//  Copyright © 2017 Sogou.Inc. All rights reserved.
//

#import "SGIImageMmapManager.h"
#import <sys/mman.h>

// 通用方法，可以放到 utilities 中
size_t SGIByteAlign(size_t width, size_t alignment) {
    return ((width + (alignment - 1)) / alignment) * alignment;
}

// 块的大小应该是跟CPU cache line有关，ARMv7是32byte，A9是64byte，在A9下CoreAnimation应该是按64byte作为一块数据去读取和渲染，让图像数据对齐64byte就可以避免CoreAnimation再拷贝一份数据进行修补。
size_t SGIByteAlignForCoreAnimation(size_t width) {
    return SGIByteAlign(width, 64);
}


@implementation SGIImageMmapManager
#pragma mark - Helper Methods
+ (NSString *)tempMmapFilePath {
    NSString * cachePath =
    [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"com.sogou.gifimage"];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 每个进程生存期内只执行一次
        [[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
    });
    
    BOOL isDirectory = YES;
    BOOL succeed =
    [[NSFileManager defaultManager] fileExistsAtPath:cachePath
                                         isDirectory:&isDirectory];
    
    if (!succeed || !isDirectory) {
        succeed =
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
        if (!succeed) cachePath = nil;
    }
    
    return cachePath;
}

+ (void)cleanMmapFile:(NSString *)fileName
               buffer:(void *)buffer
                 size:(NSUInteger)size {
    if (buffer) {
        munmap(buffer, size);
        buffer = NULL;
    }
    
    if (fileName.length) {
        NSString * path = [[self tempMmapFilePath] stringByAppendingPathComponent:fileName];
        
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}

+ (void *)createMmapFile:(NSString *)fileName
                    size:(NSUInteger)size {
    NSString * path =
    [[self tempMmapFilePath] stringByAppendingPathComponent:fileName];
    
    //Create a new file is faster memset() when reboot.
    NSError * error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    }
    
    
    char * buffer = NULL;
    int fd = open(path.UTF8String, O_CREAT|O_RDWR, S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH);
    if (fd != -1) {
        int ret = ftruncate(fd, size);
        if(ret != -1)
        {
            buffer = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
            if (buffer == MAP_FAILED)
                buffer = NULL;
        }
        close(fd);
    }
    return buffer;
}

+ (size_t)openImageFileByMmap:(NSString *)path destBuffer:(void**)destBuffer {
    void * buffer = NULL;
    size_t size = -1;
    int fd = open([path fileSystemRepresentation], O_RDONLY, S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH);
    if (fd != -1) {
        size = (size_t)lseek(fd, 0, SEEK_END);
        buffer = mmap(NULL, size, PROT_READ, MAP_FILE | MAP_SHARED, fd, 0);
        if (buffer == MAP_FAILED)
            buffer = NULL;
        close(fd);
    }
    
    *destBuffer = buffer;
    return size;
}

@end
