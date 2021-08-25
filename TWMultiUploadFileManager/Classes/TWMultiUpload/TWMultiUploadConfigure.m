//
//  TWMultiUploadConfigure.m
//  house591
//
//  Created by zhengzeqin on 2021/7/7.
//

#import "TWMultiUploadConfigure.h"

@implementation TWMultiUploadConfigure

- (instancetype)init {
    if (self = [super init]) {
        self.maxConcurrentOperationCount = 3;
        self.maxSize = 2 * 1024 * 1024 * 1024;
        self.maxDuration = 2 * 60 * 60;
        self.maxSliceds = 100;
        self.perSlicedSize = 5 * 1024 * 1024;
        self.retryTimes = 3;
        self.timeoutInterval = 120;
        self.mimeType = @"text/plain";
    }
    return self;
}

@end
