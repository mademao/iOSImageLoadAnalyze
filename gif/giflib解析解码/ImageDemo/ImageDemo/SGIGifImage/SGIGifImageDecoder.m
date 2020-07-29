//
//  SGIGifImageDecoder.m
//  HmtUITest
//
//  Created by shajie on 1/15/17.
//  Copyright © 2017 shajie. All rights reserved.
//

#import "SGIGifImageDecoder.h"
#import "GifDecode.h"
#import <pthread.h>
#import "SGIImageMmapManager.h"

@interface SGIGifImageDecoder ()
{
    pthread_mutex_t _lock; // recursive lock
    /// giflib 解码相关
    GifFileType * _gifFile;
    GifRowType _rowBuffer;
    GraphicsControlBlock _gcb;
    CGContextRef _context; // 用于绘制解码后 Bitmap 图像的 context
    PixelRGBA *_contextBuffer;  // 用于存放解码后 Bitmap 数据
    NSString * _contextBufferFile; // _contentBuffer 对应的 mmap 文件
    CGContextRef _contextFirst; // 用于绘制解码后 Bitmap 图像的 context
    PixelRGBA *_contextBufferFirst;  // 用于存放解码后 Bitmap 数据
    NSString * _contextBufferFirstFile; // _contentBuffer 对应的 mmap 文件

    size_t _contextBufferSize;

    long _dataHeadOffset; // 保存 Gif 第一帧图像数据的位置偏移
    NSUInteger _currentIndexToDecode; // 保存当前待解码的位置
    NSArray * _frameDurationArray;

    // 1. 如果是通过 NSData 初始化，创建一个 mmap 文件，将 NSData 复制一份
    // 2. 如果是通过 FilePath 初始化，直接以 mmap 方式加载文件内容
    void * _imageDataBuffer;
    size_t _imageDataBufferSize;
    NSString * _imageDataBufferFile; // _imageDataBuffer 对应的 mmap 文件，如果是通过 FilePath 初始化，此值为 nil
    long _currentDataOffset;
    UIImage * _lastDecodedImage;
}

@property (nonatomic) long currentDataOffset;

- (int)readImageData:(GifByteType *)buf byLength:(int)length;

@end


static int GifDataReadFunc (GifFileType * fileType, GifByteType * buf, int len)
{
    SGIGifImageDecoder * decoder = (__bridge SGIGifImageDecoder *)(fileType->UserData);
    return [decoder readImageData:buf byLength:len];
}


@implementation SGIGifImageDecoder

+ (SGIGifImageDecoder *)decoderWithPath:(NSString *)path
{
    return [[self alloc] initWithPath:path];
}

+ (SGIGifImageDecoder *)decoderWithData:(NSData *)data
{
    return [[self alloc] initWithData:data];
}

- (NSInteger)lastDecodeImageIndex
{
    if (_currentIndexToDecode > 0) {
        return _currentIndexToDecode - 1;
    } else if (_frameCount > 0) {
        return _frameCount - 1;
    } else {
        return 0;
    }
}

- (void)dealloc
{    
    if (_gifFile) DGifCloseFile(_gifFile, NULL);
    
    if (_rowBuffer) free(_rowBuffer);
    
    if (_context) CGContextRelease(_context);
    if (_contextFirst) CGContextRelease(_contextFirst);
    
    [SGIImageMmapManager cleanMmapFile:_contextBufferFile
                               buffer:_contextBuffer 
                                 size:_contextBufferSize];
    
    [SGIImageMmapManager cleanMmapFile:_contextBufferFirstFile
                               buffer:_contextBufferFirst
                                 size:_contextBufferSize];

    [SGIImageMmapManager cleanMmapFile:_imageDataBufferFile
                               buffer:_imageDataBuffer
                                 size:_imageDataBufferSize];
    
    pthread_mutex_destroy(&_lock);
}

- (SGIGifImageDecoder *)initWithPath:(NSString *)path
{
    self = [super init];
    if (self)
    {
        if (![self createGifDataFromFile:path]) return nil;
        if (![self prepareDecoding]) return nil;
    }
    return self;
}

- (SGIGifImageDecoder *)initWithData:(NSData *)data
{
    self = [super init];
    if (self)
    {
        if (![self createGifDataCopy:data]) return nil;
        if (![self prepareDecoding]) return nil;
    }
    return self;
}

- (BOOL)prepareDecoding
{
    int errorCode = 0;
    _gifFile = DGifOpen((__bridge void*)self, GifDataReadFunc, &errorCode);
    if (!_gifFile) return NO;
    _dataHeadOffset = _currentDataOffset;
    if (![self preloadGifImageData]) return NO;
    
    pthread_mutexattr_t attr;
    pthread_mutexattr_init (&attr);
    pthread_mutexattr_settype (&attr, PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init (&_lock, &attr);
    pthread_mutexattr_destroy (&attr);
    return YES;
}

- (void)resetGifDataOffset
{
    _currentDataOffset = _dataHeadOffset;
}

- (int)readImageData:(GifByteType *)buf
            byLength:(int)length
{
    int actualLength = MIN(length, (int)(_imageDataBufferSize - _currentDataOffset));
    memcpy(buf, _imageDataBuffer + _currentDataOffset, actualLength);
    _currentDataOffset += actualLength;
    return actualLength;
}

// 不对图片解码，只获取一些基本信息
- (BOOL)preloadGifImageData
{
    int loopCount = 0;
    int frameCount = 0;
    
    NSMutableArray * durationArray = [NSMutableArray array];
    int errorCode = 0;
    GifRecordType recordType;
    
    _gcb.DelayTime = 0;
    _gcb.TransparentColor = -1;
    _gcb.DisposalMode = DISPOSAL_UNSPECIFIED;
    
    _imageBytesPerFrame = (NSUInteger)SGIByteAlignForCoreAnimation(_gifFile->SWidth * 4) * _gifFile->SHeight;
    
    /* Scan the content of the GIF file and load the image(s) in: */
    do
    {
        if ( DGifGetRecordType( _gifFile, &recordType ) == GIF_ERROR )
        {
            errorCode = _gifFile->Error;
            goto END;
        }
        
        switch ( recordType )
        {
            case EXTENSION_RECORD_TYPE:
            {
                GifByteType *gifExtBuffer;
                int gifExtCode;
                if ( DGifGetExtension( _gifFile, &gifExtCode, &gifExtBuffer ) == GIF_ERROR )
                {
                    errorCode = _gifFile->Error;
                    goto END;
                }
                if ( gifExtCode == GRAPHICS_EXT_FUNC_CODE && gifExtBuffer[0] == 4 )
                {
                    // Graphic Control Extension block
                    DGifExtensionToGCB( 4, &gifExtBuffer[1], &_gcb );
                    [durationArray addObject:@(_gcb.DelayTime * 0.01f)];
                }
                while ( gifExtBuffer != NULL )
                {
                    if ( DGifGetExtensionNext(_gifFile, &gifExtBuffer ) == GIF_ERROR )
                    {
                        errorCode = _gifFile->Error;
                        goto END;
                    }
                    
                    // Application Extension 只有 1 个
                    if ( gifExtBuffer && gifExtCode == APPLICATION_EXT_FUNC_CODE && gifExtBuffer[0] == 3 && gifExtBuffer[1] == 1 )
                    {
                        loopCount = INT_2_BYTES( gifExtBuffer[2], gifExtBuffer[3] );
                    }
                }
            }
                break;
            case IMAGE_DESC_RECORD_TYPE:
            {
                if (DGifShiftImageDataWithoutDecode(_gifFile) == GIF_ERROR)
                {
                    errorCode = _gifFile->Error;
                    goto END;
                }
                
                frameCount++;
                // workaround:
                // 正常情况下，EXTENSION_RECORD_TYPE 和 IMAGE_DESC_RECORD_TYPE 应当交错排列，不需要以下处理
                // 但某些文件格式错误，可能没有 EXTENSION_RECORD_TYPE，需要强行将 durationArray 补齐
                // 譬如 https://img04.sogoucdn.com/app/a/200678/14810141822767.gif
                while (durationArray.count < frameCount)
                    [durationArray addObject:@(0.0f)];
            }
                break;
            case TERMINATE_RECORD_TYPE:
            {
                [self resetGifDataOffset];
                // do nothing
            }
                break;
            default:		    /* Should be trapped by DGifGetRecordType. */
                break;
        }
    } while ( recordType != TERMINATE_RECORD_TYPE );
    
END:
    if (errorCode)
    {
        return NO;
    }
    
    _loopCount = loopCount;
    _frameCount = frameCount;
    _frameDurationArray = [NSArray arrayWithArray:durationArray];
    return YES;
}

- (BOOL)createGifDataFromFile:(NSString *)path
{
    void * buffer = NULL;
    size_t size = [SGIImageMmapManager openImageFileByMmap:path destBuffer:&buffer];
    if (!buffer)
        return NO;
    _imageDataBuffer = buffer;
    _imageDataBufferSize = size;
    _imageDataBufferFile = nil;
    return YES;
}

- (BOOL)createGifDataCopy:(NSData *)data
{
    NSString * fileName = [NSString stringWithFormat:@"sgi_gif_data_%zd", [data hash]];
    void * buffer = [SGIImageMmapManager createMmapFile:fileName
                                                  size:data.length];
    if (!buffer)
        return NO;
    _imageDataBuffer = buffer;
    _imageDataBufferSize = data.length;
    _imageDataBufferFile = fileName;
    // 不管外部传入的 data 从哪来，向内存映射文件上复制一份，decode 不需要 own data
    memcpy(_imageDataBuffer, data.bytes, data.length);
    return YES;
}

- (BOOL)createContextBufferFirst {
    NSString *fileNameFirst = [NSString stringWithFormat:@"sgi_gif_context_%zd_%@", [self hash], @"first"];
    void *bufferFirst = [SGIImageMmapManager createMmapFile:fileNameFirst
                                                      size:_contextBufferSize];
    if (!bufferFirst) {
        return NO;
    }
    
    _contextBufferFirst = bufferFirst;
    _contextBufferFirstFile = fileNameFirst;
    return YES;
}

- (BOOL)createContextBuffer
{
    NSString * fileName = [NSString stringWithFormat:@"sgi_gif_context_%zd", [self hash]];
    void * buffer = [SGIImageMmapManager createMmapFile:fileName
                                                  size:_contextBufferSize];
    if (!buffer)
        return NO;
    
    _contextBuffer = buffer;
    _contextBufferFile = fileName;
    return YES;
}

- (UIImage *)nextImage
{
    if (!_rowBuffer)
    {
        _rowBuffer = (GifRowType)malloc(_gifFile->SWidth * sizeof(GifPixelType));
        
        for (int i = 0; i < _gifFile->SWidth; i++)
        {
            _rowBuffer[i] = _gifFile->SBackGroundColor;
        }
    }
    
    void *contextBuffer = NULL;
    CGContextRef context = NULL;
    
//    if (!_contextBuffer)
//    {
//        _contextBufferSize = _imageBytesPerFrame;
//        if (![self createContextBuffer])
//            return nil;
//
//        memset(_contextBuffer, 0, _contextBufferSize);
//        _context = CGBitmapContextCreate(_contextBuffer, _gifFile->SWidth, _gifFile->SHeight,
//                                         8, SGIByteAlignForCoreAnimation(4 * _gifFile->SWidth),
//                                         CGColorSpaceCreateDeviceRGB(),
//                                         kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
//    }
//    contextBuffer = _contextBuffer;
//    context = _context;
    
    
    if (0 == _currentIndexToDecode) {
        if (!_contextBufferFirst) {
            _contextBufferSize = self.imageBytesPerFrame;
            if (![self createContextBufferFirst]) {
                return nil;
            }
            //未使用mmap缓存池，需在此在此初始化buffer
            memset(_contextBufferFirst, 0, _contextBufferSize);
            _contextFirst = CGBitmapContextCreate(_contextBufferFirst, _gifFile->SWidth, _gifFile->SHeight,
                                                  8, SGIByteAlignForCoreAnimation(4 * _gifFile->SWidth),
                                                  CGColorSpaceCreateDeviceRGB(),
                                                  kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
        }
        contextBuffer = _contextBufferFirst;
        context = _contextFirst;
    } else {
        if (!_contextBuffer) {
            _contextBufferSize = self.imageBytesPerFrame;
            if (![self createContextBuffer])
                return nil;
            _context = CGBitmapContextCreate(_contextBuffer, _gifFile->SWidth, _gifFile->SHeight,
                                             8, SGIByteAlignForCoreAnimation(4 * _gifFile->SWidth),
                                             CGColorSpaceCreateDeviceRGB(),
                                             kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
            
        }
        //若加码第2帧，需要从第1帧拿到第一帧处置后的数据
        if (_currentIndexToDecode == 1) {
            if (_contextFirst) {
                memcpy(_contextBuffer, _contextBufferFirst, _contextBufferSize);
            } else {
                memset(_contextBuffer, 0, _contextBufferSize);
            }
        }
        
        contextBuffer = _contextBuffer;
        context = _context;
    }

    UIImage * retImage = nil;
    int errorCode = 0;
    GifRecordType recordType;
    /* Scan the content of the GIF file and load the image(s) in: */
    do {
        if ( DGifGetRecordType( _gifFile, &recordType ) == GIF_ERROR ) {
            errorCode = _gifFile->Error;
            goto END;
        }
        
        switch ( recordType ) {
            case EXTENSION_RECORD_TYPE:
            {
                GifByteType *gifExtBuffer;
                int gifExtCode;
                if ( DGifGetExtension( _gifFile, &gifExtCode, &gifExtBuffer ) == GIF_ERROR )
                {
                    errorCode = _gifFile->Error;
                    goto END;
                }
                if ( gifExtCode == GRAPHICS_EXT_FUNC_CODE && gifExtBuffer[0] == 4 )
                {
                    // Graphic Control Extension block
                    DGifExtensionToGCB( 4, &gifExtBuffer[1], &_gcb );
                }
                while ( gifExtBuffer != NULL ) {
                    if ( DGifGetExtensionNext(_gifFile, &gifExtBuffer ) == GIF_ERROR )
                    {
                        errorCode = _gifFile->Error;
                        goto END;
                    }
                }
            }
                break;
            case IMAGE_DESC_RECORD_TYPE:
            {
                CGImageRef image = NULL;
                errorCode = renderGifFrameWithBufferSize(_gifFile, _rowBuffer, context, contextBuffer, _gcb, &image, _imageBytesPerFrame);
                if ( errorCode )
                {
                    goto END;
                }
                
                retImage = [UIImage imageWithCGImage:image];
                CGImageRelease( image );
                image = NULL;
                goto END;
            }
                break;
            case TERMINATE_RECORD_TYPE:
            {
                [self resetGifDataOffset];
                recordType = EXTENSION_RECORD_TYPE;
            }
                break;
            default:		    /* Should be trapped by DGifGetRecordType. */
                break;
        }
    } while ( recordType != TERMINATE_RECORD_TYPE );
    
    
END:
    if (errorCode)
    {
//        NSLog(@"------ errorCode : %zd", errorCode);
    }
    
    //    NSLog(@"--- decode one frame : %f ", (double)(clock() - t ) / CLOCKS_PER_SEC);
    
    return retImage;
}

#pragma mark - Public

- (UIImage *)imageFrameAtIndex:(NSUInteger)index
{
    NSLog(@"mdm---decode %@", @(index));
    if (index >= _frameCount)
        return nil;
    
    /**********************************************
    * 目前针对多线程的同步策略:
    *   decoder 严格按顺序解码，通过 _currentIndexToDecode 来记录待解码帧，
    *   同时，通过 _lastDecodedImage 来保存最新一次解码的结果
    *   每次传入 index，只有与 _currentIndexToDecode 相同才能触发下一次解码
    *   其它值均返回 _lastDecodedImage，只能享受上次解码的结果
    *
    *   在多个 imageView 共享一个 decoder 这种极端情况下，displayLink 刷新过程
    *   在主线程有序执行，在目前策略下所有 imageView 都会被强行对齐，播放帧保持一致
    *   单 imageView 独占 decoder 的情况下，额外获取 lock 开销可以忽略，苹果官方文档表述在 0.2 微秒左右
    **********************************************/
    
    // 检查 index 是否是当前待解帧
    pthread_mutex_lock(&_lock);
    if (_currentIndexToDecode != index)
    {
        UIImage * image = _lastDecodedImage;
        pthread_mutex_unlock(&_lock);
        return image;
    }
    // 实际解码
    UIImage * image = [self nextImage];
    _currentIndexToDecode ++;
    _lastDecodedImage = image;
    // 检查边界情况
    if (_currentIndexToDecode >= _frameCount)
    {
        [self resetGifDataOffset];
        _currentIndexToDecode = 0;
    }
    pthread_mutex_unlock(&_lock);
    return image;
}

- (NSTimeInterval)frameDurationAtIndex:(NSUInteger)index
{
    if (index >= _frameCount)
        return 0;

    NSTimeInterval duration = [_frameDurationArray[index] doubleValue];
    return duration;
}

- (NSData *)animatedImageData
{
    return [NSData dataWithBytes:_imageDataBuffer length:_imageDataBufferSize];
}

@end
