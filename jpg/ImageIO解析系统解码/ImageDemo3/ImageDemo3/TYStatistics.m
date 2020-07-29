//
//  TYStatistics.m
//  TYActions
//
//  Created by ydhz on 2017/9/18.
//  Copyright © 2017年 ydhz. All rights reserved.
//

#import "TYStatistics.h"
#include <net/if.h>
#include <net/if_dl.h>
#include <sys/socket.h>
#include <sys/sysctl.h>

#include <arpa/inet.h>
#include <ifaddrs.h>

#include <dlfcn.h>
#import <stdlib.h>

#import <mach-o/ldsyms.h>

#import <mach/mach.h>
#import <mach/mach_host.h>
#import <sys/sysctl.h>
#import <sys/types.h>

@implementation TYStatistics
+ (float)residentSizeOfMemory {
    task_basic_info_data_t taskInfo;
    mach_msg_type_number_t infoCount = TASK_BASIC_INFO_COUNT;
    kern_return_t kernReturn = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&taskInfo, &infoCount);
    
    if (kernReturn != KERN_SUCCESS) {
        return 0.0f;
    }
    return (taskInfo.resident_size / (1024.0 * 1024.0));
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

+ (float)realFootprint {
    task_vm_info_data_t taskInfo;
    mach_msg_type_number_t infoCount = TASK_VM_INFO_COUNT;
    kern_return_t kernReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&taskInfo, &infoCount);

    if (kernReturn != KERN_SUCCESS) {
        return 0;
    }
    return (taskInfo.phys_footprint / 1024.0 / 1024.0);
}

+ (float)internalPeakOfMemory {
    task_vm_info_data_t taskInfo;
    mach_msg_type_number_t infoCount = TASK_VM_INFO_COUNT;
    kern_return_t kernReturn = task_info(mach_task_self(), TASK_VM_INFO_PURGEABLE, (task_info_t)&taskInfo, &infoCount);
    
    if (kernReturn != KERN_SUCCESS) {
        return 0.0f;
    }
    return (taskInfo.internal_peak / (1024.0 * 1024.0));
}

+ (NSString *)stringOfResidentMemorySize {
    task_basic_info_data_t taskInfo;
    mach_msg_type_number_t infoCount = TASK_BASIC_INFO_COUNT;
    kern_return_t kernReturn = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&taskInfo, &infoCount);
    
    if (kernReturn != KERN_SUCCESS) {
        return @"";
    }
    return [NSString stringWithFormat:@"%.2f", taskInfo.resident_size / (1024.0 * 1024.0)];
}

+ (NSString *)systemMemoryState {
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    
    vm_statistics_data_t vm_stat;
    
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
        NSLog(@"Failed to fetch vm statistics");
    
    /* Stats in bytes */
    natural_t mem_used = (natural_t)((vm_stat.active_count + vm_stat.inactive_count + vm_stat.wire_count) * pagesize / (1024 * 1024));
    natural_t mem_free = (natural_t)(vm_stat.free_count * pagesize / (1024 * 1024));
    natural_t mem_total = (mem_used + mem_free);
    
    NSString *curMemory = [NSString stringWithFormat:@"Memory: used: %u free: %u total: %u", mem_used, mem_free, mem_total];
    
    return curMemory;
}

+ (float)systemCpuUsage {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
 
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
 
    task_basic_info_t basic_info;
    thread_array_t thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads
    
    basic_info = (task_basic_info_t)tinfo;
 
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0)
        stat_thread += thread_count;
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
 
    for (j = 0; j < thread_count; j++) {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO, (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->system_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
        
    } // for each thread
    
    // release ( issue - 9.19 leaks )
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    if (kr != KERN_SUCCESS) {
        return -1;
    }
 
    return tot_cpu;
}
@end
