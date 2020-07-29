//
//  SGIImageMmapManager.h
//  BaseKeyboard
//
//  Created by lina on 26/11/2017.
//  Copyright © 2017 Sogou.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

size_t SGIByteAlign(size_t width, size_t alignment);
size_t SGIByteAlignForCoreAnimation(size_t width);

@interface SGIImageMmapManager : NSObject

+ (NSString *)tempMmapFilePath;
+ (void)cleanMmapFile:(NSString *)fileName
               buffer:(void *)buffer
                 size:(NSUInteger)size;
+ (void *)createMmapFile:(NSString *)fileName
                    size:(NSUInteger)size;
+ (size_t)openImageFileByMmap:(NSString *)path
                   destBuffer:(void**)destBuffer;

@end
