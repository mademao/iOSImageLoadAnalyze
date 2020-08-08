# iOS加载图片内存占用分析
该工程用于验证iOS各种加载图片方式中，图片解码过程中内存使用情况，以及进程内存计算情况。



对于iOS来说，常用的图片加载方式有两种：1.CoreAnimation触发图片解码 2.CoreGraphics重绘触发图片解码。



无论使用何种方式加载图片，图片解码均由ImageIO完成。



# 一、静图

### 1.CoreAnimation

![PNG_CoreAnimation](https://github.com/mademao/iOSImageLoadAnalyze/raw/master/pic/PNG_CoreAnimation.png)



* ImageIO_PNG_Data：被计算在进程内存使用内

##### (1)解码峰值

发生在图片解码时

图片文件原始数据+图片解码后数据

##### (2)展示时内存

图片文件原始数据+图片解码后数据



### 2.CoreGraphics

![PNG_CoreGraphics](https://github.com/mademao/iOSImageLoadAnalyze/raw/master/pic/PNG_CoreGraphics.png)



* CGSImageHandle：被计算在进程内存使用内
* CGBitmapAllocateData：使用mmap申请，不会计算在进程内存使用，但受设备mmap申请大小限制
* CGDataProviderCreateWithCopyOfData：使用mmap申请，不会计算在进程内存使用，但受设备mmap申请大小限制

##### (1)解码峰值

发生在CoreGraphics重绘时

图片文件原始数据+图片解码后数据+CGSImageHandle

##### (2)展示时内存

没有被进程计算在内的内存使用



# 二、动图

### 1.CoreAnimation

![GIF_CoreAnimation](https://github.com/mademao/iOSImageLoadAnalyze/raw/master/pic/GIF_CoreAnimation.png)



* GIFColorMap：被计算在进程内存使用内
* ColorIndex：被计算在进程内存使用内
* GIFBufferInfo：被计算在进程内存使用内

##### (1)解码峰值

发生在第N帧解码后生成GIFBufferInfo时

图片文件原始数据+全局调色板+N*帧图片解码后数据+2*GIFBufferInfo（第一帧只有一个）

##### (2)展示时内存

图片文件原始数据+全局调色板+N*帧图片解码后数据+GIFBufferInfo



### 2.CoreGraphics

![GIF_CoreGraphics](https://github.com/mademao/iOSImageLoadAnalyze/raw/master/pic/GIF_CoreGraphics.png)



##### (1)解码峰值

发生在第N帧解码后生成GIFBufferInfo时

图片文件原始数据+全局调色板+帧图片解码后数据+GIFBufferInfo

##### (2)展示内存

图片文件原始数据+全局调色板+GIFBufferInfo



# 三、下采样

ImageIO提供了下采样的方法获取缩略图，该API本质是调用CoreGraphics重绘得到缩略图。



但是在底层CoreGraphics触发ImageIO解码时，比调用```CGContextDrawImage```消耗内存小，这种方法在ImageIO解码时，并不会以原始尺寸进行解码，而是以预定尺寸进行解码，所以内存消耗小。



但很可惜相关API并没有暴露。



# 四、总结

1.iOS中ImageIO库负责图片的解析和解码。

2.ImageIO暴露的API仅能对图片进行解析。

3.CoreGraphics可以触发ImageIO对图片进行解码。

4.CoreAnimation可以触发CoreGraphics绘制图片，进而触发ImageIO对图片进行解码。

5.ImageIO无论解码动图还是静图，在解码过程中产生的内存使用均会被计算在进程内存使用中。

6.使用CoreAnimation中Context对图片进行重绘，bitmap及最终生成新图片对应的颜色信息所使用的内存均不会被计算在进程使用中，但这两部分内存大小受限于机器mmap可分配大小；而在重绘过程中对颜色进行柔光处理使用到的内存，是会被计算在进程内存使用中的。

