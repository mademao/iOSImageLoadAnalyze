//
//  main.m
//  ImageDemo
//
//  Created by mademao on 2020/7/15.
//  Copyright © 2020 mademao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "fishhook.h"
#import "SGIImageMmapManager.h"

static int (*orig_close)(int);
static int (*orig_open)(const char *, int, ...);
 
int my_close(int fd) {
  printf("Calling real close(%d)\n", fd);
  return orig_close(fd);
}
 
int my_open(const char *path, int oflag, ...) {
  va_list ap = {0};
  mode_t mode = 0;
 
  if ((oflag & O_CREAT) != 0) {
    // mode only applies to O_CREAT
    va_start(ap, oflag);
    mode = va_arg(ap, int);
    va_end(ap);
    printf("Calling real open('%s', %d, %d)\n", path, oflag, mode);
    return orig_open(path, oflag, mode);
  } else {
    printf("Calling real open('%s', %d)\n", path, oflag);
    return orig_open(path, oflag, mode);
  }
}

static void *(*orig_mmap)(void *, size_t, int, int, int, off_t);

void *sg_mmap(void *argv1, size_t argv2, int argv3, int argv4, int argv5, off_t argv6)
{
    printf("Call real mmap(%d %d %d)\n", argv3, argv4, argv5);
    return orig_mmap(argv1, argv2, argv3, argv4, argv5, argv6);
}

static void *(*orig_malloc)(size_t __size);

void *sg_malloc(size_t __size)
{
    if (__size > 10 * 1024 * 1024) {
        printf("Call real malloc(%zu)\n", __size);
    }
    
    return orig_malloc(__size);
}

typedef void(sgi_malloc_logger_t)(uint32_t type_flags, uintptr_t zone_ptr, uintptr_t arg2, uintptr_t arg3, uintptr_t return_val, uint32_t num_hot_to_skip);

extern sgi_malloc_logger_t *malloc_logger;
extern sgi_malloc_logger_t *__syscall_logger;

sgi_malloc_logger_t *org_malloc_logger;
sgi_malloc_logger_t *org___syscall_logger;

#define sgi_allocations_type_free 0
#define sgi_allocations_type_generic 1        /* anything that is not allocation/deallocation */
#define sgi_allocations_type_alloc 2          /* malloc, realloc, etc... */
#define sgi_allocations_type_dealloc 4        /* free, realloc, etc... */
#define sgi_allocations_type_vm_allocate 16   /* vm_allocate or mmap */
#define sgi_allocations_type_vm_deallocate 32 /* vm_deallocate or munmap */
#define sgi_allocations_type_mapped_file_or_shared_mem 128

static const char *vm_flags[] = {
    "0", "malloc", "malloc_small", "malloc_large", "malloc_huge", "SBRK",
    "realloc", "malloc_tiny", "malloc_large_reusable", "malloc_large_reused",
    "analysis_tool", "malloc_nano", "12", "13", "14",
    "15", "16", "17", "18", "19",
    "mach_msg", "iokit", "22", "23", "24",
    "25", "26", "27", "28", "29",
    "stack", "guard", "shared_pmap", "dylib", "objc_dispatchers",
    "unshared_pmap", "36", "37", "38", "39",
    "appkit", "foundation", "core_graphics", "carbon_or_core_services", "java",
    "coredata", "coredata_objectids", "47", "48", "49",
    "ats", "layerkit", "cgimage", "tcmalloc", "CG_raster_data(layers&images)",
    "CG_shared_images_fonts", "CG_framebuffers", "CG_backingstores", "CG_x-alloc", "59",
    "dyld", "dyld_malloc", "sqlite", "JavaScriptCore", "JIT_allocator",
    "JIT_file", "GLSL", "OpenCL", "QuartzCore", "WebCorePurgeableBuffers",
    "ImageIO", "CoreProfile", "assetsd", "os_once_alloc", "libdispatch",
    "Accelerate.framework", "CoreUI", "CoreUIFile", "GenealogyBuffers", "RawCamera",
    "CorpseInfo", "ASL", "SwiftRuntime", "SwiftMetadata", "DHMM",
    "85", "SceneKit.framework", "skywalk", "IOSurface", "libNetwork",
    "Audio", "VideoBitStream", "CoreMediaXCP", "CoreMediaRPC", "CoreMediaMemoryPool",
    "CoreMediaReadCache", "CoreMediaCrabs", "QuickLook", "Accounts.framework", "99",
};

void sgi_malloc_logging(uint32_t type_flags, uintptr_t zone_ptr, uintptr_t arg2, uintptr_t arg3, uintptr_t return_val, uint32_t num_hot_to_skip) {
    if (org_malloc_logger) {
        org_malloc_logger(type_flags, zone_ptr, arg2, arg3, return_val, num_hot_to_skip);
    }
    
    if (type_flags & sgi_allocations_type_alloc || type_flags & sgi_allocations_type_vm_allocate) {
        if (arg2 / 1024.0 / 1024.0 < 10.0) {
            return;
        }
    }
    
    if (type_flags & sgi_allocations_type_dealloc || type_flags & sgi_allocations_type_vm_deallocate) {
        if (arg3 / 1024.0 / 1024.0 < 10.0) {
            return;
        }
    }
    
    const char *flag = "unknown";
    if (type_flags & sgi_allocations_type_vm_allocate ||
        type_flags & sgi_allocations_type_vm_deallocate) {
        uint32_t type = (type_flags & ~sgi_allocations_type_vm_allocate);
        type = (type_flags & ~sgi_allocations_type_vm_deallocate);
        type = type >> 24;
        if (type <= 99)
            flag = vm_flags[type];
    }
    
    printf("mdm---%ld %ld %s %ld-------------\n", arg2, arg3, flag, return_val);
    if (type_flags & sgi_allocations_type_alloc) {
        printf("mdm---sgi_allocations_type_alloc\n");
    }
    if (type_flags & sgi_allocations_type_dealloc) {
        printf("mdm---sgi_allocations_type_dealloc\n");
    }
    if (type_flags & sgi_allocations_type_vm_allocate) {
        printf("mdm---sgi_allocations_type_vm_allocate\n");
    }
    if (type_flags & sgi_allocations_type_vm_deallocate) {
        printf("mdm---sgi_allocations_type_vm_deallocate\n");
    }
    if (type_flags & sgi_allocations_type_mapped_file_or_shared_mem) {
        printf("mdm---sgi_allocations_type_mapped_file_or_shared_mem %ld\n", type_flags);
    }
    printf("\n");
}

void sgi_syscall_logging(uint32_t type_flags, uintptr_t zone_ptr, uintptr_t arg2, uintptr_t arg3, uintptr_t return_val, uint32_t num_hot_to_skip) {
    if (org___syscall_logger) {
        org___syscall_logger(type_flags, zone_ptr, arg2, arg3, return_val, num_hot_to_skip);
    }
    
    if (type_flags & sgi_allocations_type_alloc || type_flags & sgi_allocations_type_vm_allocate) {
        if (arg2 / 1024.0 / 1024.0 < 10.0) {
            return;
        }
    }
    
    if (type_flags & sgi_allocations_type_dealloc || type_flags & sgi_allocations_type_vm_deallocate) {
        if (arg3 / 1024.0 / 1024.0 < 10.0) {
            return;
        }
    }
    
    const char *flag = "unknown";
    if (type_flags & sgi_allocations_type_vm_allocate ||
        type_flags & sgi_allocations_type_vm_deallocate) {
        uint32_t type = (type_flags & ~sgi_allocations_type_vm_allocate);
        type = (type_flags & ~sgi_allocations_type_vm_deallocate);
        type = type >> 24;
        if (type <= 99)
            flag = vm_flags[type];
    }
    
    printf("mdm---%ld %ld %s %ld-------------\n", arg2, arg3, flag, return_val);
    if (type_flags & sgi_allocations_type_alloc) {
        printf("mdm---sgi_allocations_type_alloc\n");
    }
    if (type_flags & sgi_allocations_type_dealloc) {
        printf("mdm---sgi_allocations_type_dealloc\n");
    }
    if (type_flags & sgi_allocations_type_vm_allocate) {
        printf("mdm---sgi_allocations_type_vm_allocate\n");
    }
    if (type_flags & sgi_allocations_type_vm_deallocate) {
        printf("mdm---sgi_allocations_type_vm_deallocate\n");
    }
    if (type_flags & sgi_allocations_type_mapped_file_or_shared_mem) {
        printf("mdm---sgi_allocations_type_mapped_file_or_shared_mem %ld\n", type_flags);
    }
    printf("\n");
}

int main(int argc, char * argv[]) {
//    [SGIImageMmapManager createMmapFile:@"/123" size:100];
    
    
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    
//    
    rcd_rebind_symbols((struct rcd_rebinding[1]){ {"mmap", sg_mmap, (void *)&orig_mmap} }, 1);
    
//    if (malloc_logger) {
//        org_malloc_logger = malloc_logger;
//    }
//    if (__syscall_logger) {
//        org___syscall_logger = __syscall_logger;
//    }
//    malloc_logger = (sgi_malloc_logger_t *)sgi_malloc_logging;
//    __syscall_logger = sgi_syscall_logging;
    
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
