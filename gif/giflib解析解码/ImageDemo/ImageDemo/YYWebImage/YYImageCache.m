//
//  YYImageCache.m
//  YYWebImage <https://github.com/ibireme/YYWebImage>
//
//  Created by ibireme on 15/2/15.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "YYImageCache.h"
#import "YYImage.h"
#import "UIImage+YYWebImage.h"

#if __has_include(<YYImage/YYImage.h>)
#import <YYImage/YYImage.h>
#else
#import "YYImage.h"
#endif

#if __has_include(<YYCache/YYCache.h>)
#import <YYCache/YYCache.h>
#else
#import "YYCache.h"
#endif


#define YYIMAGECACHE_SG_LIMIT_MEMORYCACHE 1

#ifdef YYIMAGECACHE_SG_LIMIT_MEMORYCACHE
#import <mach/mach.h>
#import <os/proc.h>
#endif


static inline dispatch_queue_t YYImageCacheIOQueue() {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}

static inline dispatch_queue_t YYImageCacheDecodeQueue() {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
}


@interface YYImageCache ()
- (NSUInteger)imageCost:(UIImage *)image;
- (UIImage *)imageFromData:(NSData *)data;
@end


@implementation YYImageCache

- (NSUInteger)imageCost:(UIImage *)image {
    CGImageRef cgImage = image.CGImage;
    if (!cgImage) return 1;
    CGFloat height = CGImageGetHeight(cgImage);
    size_t bytesPerRow = CGImageGetBytesPerRow(cgImage);
    NSUInteger cost = bytesPerRow * height;
    if (cost == 0) cost = 1;
    return cost;
}

- (UIImage *)imageFromData:(NSData *)data {
    NSData *scaleData = [YYDiskCache getExtendedDataFromObject:data];
    CGFloat scale = 0;
    if (scaleData) {
        scale = ((NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:scaleData]).doubleValue;
    }
    if (scale <= 0) scale = [UIScreen mainScreen].scale;
    UIImage *image;
    if (_allowAnimatedImage) {
        image = [[YYImage alloc] initWithData:data scale:scale];
        if (_decodeForDisplay) image = [image yy_imageByDecoded];
    } else {
        YYImageDecoder *decoder = [YYImageDecoder decoderWithData:data scale:scale];
        image = [decoder frameAtIndex:0 decodeForDisplay:_decodeForDisplay].image;
    }
    return image;
}

#pragma mark Public

+ (instancetype)sharedCache {
    static YYImageCache *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                                   NSUserDomainMask, YES) firstObject];
        cachePath = [cachePath stringByAppendingPathComponent:@"com.ibireme.yykit"];
        cachePath = [cachePath stringByAppendingPathComponent:@"images"];
        cache = [[self alloc] initWithPath:cachePath];
    });
    return cache;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"YYImageCache init error" reason:@"YYImageCache must be initialized with a path. Use 'initWithPath:' instead." userInfo:nil];
    return [self initWithPath:@""];
}

#ifdef YYIMAGECACHE_SG_LIMIT_MEMORYCACHE

+ (CGFloat)availableSizeOfMemory {
    if (@available(iOS 13.0, *)) {
        return os_proc_available_memory() / 1024.0 / 1024.0;
    }
    return [self limitSizeOfMemory] - [self usedSizeOfMemory];
}

+ (float)usedSizeOfMemory {
    task_vm_info_data_t taskInfo;
    mach_msg_type_number_t infoCount = TASK_VM_INFO_COUNT;
    kern_return_t kernReturn = task_info(mach_task_self(), TASK_VM_INFO_PURGEABLE, (task_info_t)&taskInfo, &infoCount);

    if (kernReturn != KERN_SUCCESS) {
        return 0.0f;
    }
    return ((taskInfo.internal + taskInfo.compressed - taskInfo.purgeable_volatile_pmap) / (1024.0 * 1024.0));
}

+ (float)limitSizeOfMemory {
    CGFloat systemVersion = UIDevice.currentDevice.systemVersion.floatValue;
    CGFloat width = UIScreen.mainScreen.bounds.size.width;
    width = CGRectGetWidth(UIScreen.mainScreen.bounds) < CGRectGetHeight(UIScreen.mainScreen.bounds) ? CGRectGetWidth(UIScreen.mainScreen.bounds) : CGRectGetHeight(UIScreen.mainScreen.bounds);
    CGFloat scale = UIScreen.mainScreen.scale;
    if (systemVersion < 9.0) {
        if (width < 375) {
            return 40.0f;
        }
        return 48.0f;
    } else {
        if (width < 375) {
            return 40.0f;
        } else {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                return scale > 2 ? 53.0f : 48.0f;
            }
            return scale > 2 ? 66.0f : 53.0f;   // iPhone Xr scale = 2
        }
    }
}

+ (BOOL)isAppExtension {
    static BOOL isAppExtension = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = NSClassFromString(@"UIApplication");
        if(!cls || ![cls respondsToSelector:@selector(sharedApplication)]) isAppExtension = YES;
        if ([[[NSBundle mainBundle] bundlePath] hasSuffix:@".appex"]) isAppExtension = YES;
    });
    return isAppExtension;
}
#endif

- (instancetype)initWithPath:(NSString *)path {
    YYMemoryCache *memoryCache = [YYMemoryCache new];
    memoryCache.shouldRemoveAllObjectsOnMemoryWarning = YES;
    memoryCache.shouldRemoveAllObjectsWhenEnteringBackground = YES;
    memoryCache.countLimit = NSUIntegerMax;
    memoryCache.costLimit = NSUIntegerMax;
    memoryCache.ageLimit = 12 * 60 * 60;
    
    YYDiskCache *diskCache = [[YYDiskCache alloc] initWithPath:path];
    diskCache.customArchiveBlock = ^(id object) { return (NSData *)object; };
    diskCache.customUnarchiveBlock = ^(NSData *data) { return (id)data; };
    
#ifdef YYIMAGECACHE_SG_LIMIT_MEMORYCACHE
    if ([YYImageCache isAppExtension]) {
        //  内存缓存
        memoryCache.countLimit = 200;   //  200条
        memoryCache.costLimit = 25 * 1024 * 1024;   //  25M
        memoryCache.didReceiveMemoryWarningBlock = ^(YYMemoryCache * _Nonnull cache) {
            CGFloat availableMemory = ([YYImageCache availableSizeOfMemory]) / 2;
            if (availableMemory > 0) {
                cache.countLimit = ((NSUInteger)availableMemory) * 10;
                cache.costLimit = (NSUInteger)(availableMemory * 1024 * 1024);
            } else {
                cache.countLimit = cache.costLimit = 0;
            }
        };
        
        //  磁盘缓存
        diskCache.ageLimit = 60 * 60 * 24 * 30; //30天
    }
#endif
    if (!memoryCache || !diskCache) return nil;
    
    self = [super init];
    _memoryCache = memoryCache;
    _diskCache = diskCache;
    _allowAnimatedImage = YES;
    _decodeForDisplay = YES;
    return self;
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key {
    [self setImage:image imageData:nil forKey:key withType:YYImageCacheTypeAll];
}

- (void)setImage:(UIImage *)image imageData:(NSData *)imageData forKey:(NSString *)key withType:(YYImageCacheType)type {
    if (!key || (image == nil && imageData.length == 0)) return;
    
    __weak typeof(self) _self = self;
    if (type & YYImageCacheTypeMemory) { // add to memory cache
        if (image) {
            if (image.yy_isDecodedForDisplay) {
                [_memoryCache setObject:image forKey:key withCost:[_self imageCost:image]];
            } else {
                dispatch_async(YYImageCacheDecodeQueue(), ^{
                    __strong typeof(_self) self = _self;
                    if (!self) return;
                    [self.memoryCache setObject:[image yy_imageByDecoded] forKey:key withCost:[self imageCost:image]];
                });
            }
        } else if (imageData) {
            dispatch_async(YYImageCacheDecodeQueue(), ^{
                __strong typeof(_self) self = _self;
                if (!self) return;
                UIImage *newImage = [self imageFromData:imageData];
                [self.memoryCache setObject:newImage forKey:key withCost:[self imageCost:newImage]];
            });
        }
    }
    if (type & YYImageCacheTypeDisk) { // add to disk cache
        if (imageData) {
            if (image) {
                [YYDiskCache setExtendedData:[NSKeyedArchiver archivedDataWithRootObject:@(image.scale)] toObject:imageData];
            }
            [_diskCache setObject:imageData forKey:key];
        } else if (image) {
            dispatch_async(YYImageCacheIOQueue(), ^{
                __strong typeof(_self) self = _self;
                if (!self) return;
                NSData *data = [image yy_imageDataRepresentation];
                [YYDiskCache setExtendedData:[NSKeyedArchiver archivedDataWithRootObject:@(image.scale)] toObject:data];
                [self.diskCache setObject:data forKey:key];
            });
        }
    }
}

- (void)removeImageForKey:(NSString *)key {
    [self removeImageForKey:key withType:YYImageCacheTypeAll];
}

- (void)removeImageForKey:(NSString *)key withType:(YYImageCacheType)type {
    if (type & YYImageCacheTypeMemory) [_memoryCache removeObjectForKey:key];
    if (type & YYImageCacheTypeDisk) [_diskCache removeObjectForKey:key];
}

- (BOOL)containsImageForKey:(NSString *)key {
    return [self containsImageForKey:key withType:YYImageCacheTypeAll];
}

- (BOOL)containsImageForKey:(NSString *)key withType:(YYImageCacheType)type {
    if (type & YYImageCacheTypeMemory) {
        if ([_memoryCache containsObjectForKey:key]) return YES;
    }
    if (type & YYImageCacheTypeDisk) {
        if ([_diskCache containsObjectForKey:key]) return YES;
    }
    return NO;
}

- (UIImage *)getImageForKey:(NSString *)key {
    return [self getImageForKey:key withType:YYImageCacheTypeAll];
}

- (UIImage *)getImageForKey:(NSString *)key withType:(YYImageCacheType)type {
    if (!key) return nil;
    if (type & YYImageCacheTypeMemory) {
        UIImage *image = [_memoryCache objectForKey:key];
        if (image) return image;
    }
    if (type & YYImageCacheTypeDisk) {
        NSData *data = (id)[_diskCache objectForKey:key];
        UIImage *image = [self imageFromData:data];
        if (image && (type & YYImageCacheTypeMemory)) {
            [_memoryCache setObject:image forKey:key withCost:[self imageCost:image]];
        }
        return image;
    }
    return nil;
}

- (void)getImageForKey:(NSString *)key withType:(YYImageCacheType)type withBlock:(void (^)(UIImage *image, YYImageCacheType type))block {
    if (!block) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = nil;
        
        if (type & YYImageCacheTypeMemory) {
            image = [_memoryCache objectForKey:key];
            if (image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block(image, YYImageCacheTypeMemory);
                });
                return;
            }
        }
        
        if (type & YYImageCacheTypeDisk) {
            NSData *data = (id)[_diskCache objectForKey:key];
            image = [self imageFromData:data];
            if (image) {
                [_memoryCache setObject:image forKey:key];
                dispatch_async(dispatch_get_main_queue(), ^{
                    block(image, YYImageCacheTypeDisk);
                });
                return;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            block(nil, YYImageCacheTypeNone);
        });
    });
}

- (NSData *)getImageDataForKey:(NSString *)key {
    return (id)[_diskCache objectForKey:key];
}

- (void)getImageDataForKey:(NSString *)key withBlock:(void (^)(NSData *imageData))block {
    if (!block) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = (id)[_diskCache objectForKey:key];
        dispatch_async(dispatch_get_main_queue(), ^{
            block(data);
        });
    });
}

@end
