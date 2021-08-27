//
//  TWMultiUploadFileManager.h
//  house591
//
//  Created by zhengzeqin on 2021/7/7.
//
#import "TWMultiUploadFileManager.h"
#import <TWMultiUploadFileManager/TWMultiUploadFileManager-Swift.h>
@interface TWMultiUploadFileManager()
@property (nonatomic, strong) TWMultiUploadConfigure *configure;
/// 当前上传的文件
@property (nonatomic, strong) TWMultiUploadFileSource *fileSource;
/// 保存当前的上传任务 [fragmentId : task]
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSURLSessionDataTask *> *taskDic;

@property (nonatomic, strong) TWQueueManager *queueManager;
@end

@implementation TWMultiUploadFileManager
//检查是否为空对象
#define TWCheckNULL(object) ([object isKindOfClass:[NSNull class]]?nil:object)
//空对象 赋予空字符串
#define TWNullClass(object) (TWCheckNULL(object)?object:@"")

#define TWWS(weakSelf) __weak __typeof(&*self)weakSelf = self;

#pragma mark - LifeCycle
- (instancetype)initWithConfigure:(TWMultiUploadConfigure *)configure {
    if (self = [super init]) {
        self.configure = configure;
        NSString *name = [NSString stringWithFormat:@"%@-%f", NSStringFromClass([TWMultiUploadFileManager class]),[[[NSDate alloc] init] timeIntervalSince1970]];
        TWLog(@"TWMultiUploadFileManager 队列生成名字 = %@",name);
        self.queueManager = [[TWQueueManager alloc] initWithName:name
                                     maxConcurrentOperationCount:configure.maxConcurrentOperationCount
                                                qualityOfService:NSQualityOfServiceDefault];
        
    }
    return self;
}

#pragma mark - Setter && Getter
- (NSMutableDictionary *)taskDic {
    if (!_taskDic) {
        _taskDic = [NSMutableDictionary dictionary];
    }
    return _taskDic;
}

#pragma mark - Public Method
/// 上传资源文件
- (void)uploadFileSource:(TWMultiUploadFileSource *)fileSource {
    if (![self checkIsCorrectFileSource:fileSource]) {
        return;
    }
    fileSource.uploadStatus = TWMultiUploadFileUploadStatusUploading;
    self.fileSource = fileSource;
    if (self.delegate && [self.delegate respondsToSelector:@selector(prepareStartUploadFileManager:fileSource:)]) {
        [self.delegate prepareStartUploadFileManager:self fileSource:self.fileSource];
    }
    if (self.prepareStartUploadBlock) {
        self.prepareStartUploadBlock(self, self.fileSource);
    }
    /// 上传片段
    for (TWMultiUploadFileFragment *fileFragment in fileSource.fileFragments) {
        fileFragment.uploadStatus = TWMultiUploadFileUploadStatusUploading;
        [self putFileFragmentToAWSServices:fileFragment];
    }
}

/// 取消上传
- (void)cancleUpload {
    [self removeUploadTasks];
    if (self.delegate && [self.delegate respondsToSelector:@selector(cancleUploadFileManager:fileSource:)]) {
        [self.delegate cancleUploadFileManager:self fileSource:self.fileSource];
    }
    if (self.cancleUploadBlock) {
        self.cancleUploadBlock(self, self.fileSource);
    }
}

///  继续上传失败的文件片段，注意 fileSource 是已经经过一次上传了
- (void)continueUploadFileSource:(TWMultiUploadFileSource *)fileSource {
    if (![self checkIsCorrectFileSource:fileSource]) {
        return;
    }
    self.fileSource = fileSource;
    fileSource.uploadStatus = TWMultiUploadFileUploadStatusUploading;
    /// 上传未上传成功的片段
    for (TWMultiUploadFileFragment *fileFragment in fileSource.fileFragments) {
        if (fileFragment.uploadStatus != TWMultiUploadFileUploadStatusFinished) { // 分片没有成功则重新上传一次
            fileFragment.uploadStatus = TWMultiUploadFileUploadStatusUploading;
            [self putFileFragmentToAWSServices:fileFragment];
        }
    }
    
}

/// 继续队列上传
- (void)resumeUpload {
    [self.queueManager resume];
}

/// 暂停队列上传
- (void)pauseUpload {
    [self.queueManager pause];
}

#pragma mark - Priavte Method

#pragma mark -- Deal Upload
/// 检查文件是否符合上传资格
- (BOOL)checkIsCorrectFileSource:(TWMultiUploadFileSource *)fileSource {
    if (fileSource.uploadStatus == TWMultiUploadFileUploadStatusReadFileFail) { // 文件不存在
        [self failUploadCode:TWMultiUploadFileUploadErrorCodeReadFileFail];
        return NO;
    } else if (fileSource.totalFileSize > self.configure.maxSize) { // 文件超过大小
        [self failUploadCode:TWMultiUploadFileUploadErrorCodeOverMaxSize];
        return NO;
    }
    return YES;
}

/// 失败的上传
- (void)failUploadCode:(TWMultiUploadFileUploadErrorCode)errorCode {
    self.fileSource.uploadStatus = TWMultiUploadFileUploadStatusFail;
    if (self.delegate && [self.delegate respondsToSelector:@selector(failUploadFileManager:fileSource:failErrorCode:)]) {
        [self.delegate failUploadFileManager:self
                                     fileSource:self.fileSource
                                  failErrorCode:errorCode];
    }
    
    if (self.failUploadBlock) {
        self.failUploadBlock(self, self.fileSource, errorCode);
    }
    [self removeUploadTasks];
}

/// 成功的上传
- (void)successUpload{
    self.fileSource.uploadStatus = TWMultiUploadFileUploadStatusFinished;
    [self.fileSource deletFile];
    if (self.delegate && [self.delegate respondsToSelector:@selector(finishUploadFileManager:fileSource:)]) {
        [self.delegate finishUploadFileManager:self fileSource:self.fileSource];
        [self removeUploadTasks];
    }
    if (self.finishUploadBlock) {
        self.finishUploadBlock(self, self.fileSource);
    }
}

/// 上传中某片文件上传失败
- (void)failUploadingFileFragment:(TWMultiUploadFileFragment *)fileFragment
                        errorCode:(TWMultiUploadFileUploadErrorCode)errorCode {
    self.fileSource.totalUploadFaileFileFragment++;
    fileFragment.uploadStatus = TWMultiUploadFileUploadStatusFail;
    // 设置上传失败的分片
    self.fileSource.failUploadFileFragmentDic[TWNullClass(fileFragment.fragmentId)] = fileFragment;
    if (self.delegate && [self.delegate respondsToSelector:@selector(failUploadingFileManager:fileSource:fileFragment:failErrorCode:)]) {
        [self.delegate failUploadingFileManager:self
                                     fileSource:self.fileSource
                                   fileFragment:fileFragment
                                  failErrorCode:errorCode];
    }
    
    if (self.failUploadingBlock) {
        self.failUploadingBlock(self, self.fileSource, fileFragment, errorCode);
    }
    /// 上传失败了
    [self failUploadCode:TWMultiUploadFileUploadErrorUploadFail];
}

/// 上传中某片文件上传成功
- (void)successUploadingFileFragment:(TWMultiUploadFileFragment *)fileFragment {
    self.fileSource.totalUploadSuccessFileFragment++;
    fileFragment.uploadStatus = TWMultiUploadFileUploadStatusFinished;
    // 设置已经上传成功的分片
    self.fileSource.finishUploadFileFragmentDic[TWNullClass(fileFragment.fragmentId)] = fileFragment;
    CGFloat progress = self.fileSource.totalUploadSuccessFileFragment / self.fileSource.totalFileFragment;
    if (self.delegate && [self.delegate respondsToSelector:@selector(uploadingFileManager:progress:)]) {
        [self.delegate uploadingFileManager:self progress:progress];
    }
    
    if (self.uploadingBlock) {
        self.uploadingBlock(self, progress);
    }
    
    // 移除当前任务
    [self removeUploadTask:fileFragment.fragmentId];
    if (progress == 1.0) { // 如果总数到达了，则上传完成
        [self successUpload];
    }
}

/// 移除所有上传任务
- (void)removeUploadTasks {
    // 清空文件
    if (self.fileSource) {
        self.fileSource = nil;
    }
    // 清空请求队列
    [self.queueManager cancleAll];
    // 取消所有上传
    for (NSURLSessionDataTask *task in [self.taskDic allValues]) {
        [task cancel];
    }
    // 清空
    [self.taskDic removeAllObjects];
}

///  移除上传任务
- (void)removeUploadTask:(NSString *)fragmentId {
    NSURLSessionDataTask *task = self.taskDic[TWNullClass(fragmentId)];
    [task cancel];
    [self.taskDic removeObjectForKey:TWNullClass(fragmentId)];
}

// 根據錯誤碼解析錯誤異常
- (TWMultiUploadFileUploadErrorCode)getServerError:(NSError *)error{
    if (error) {
        if (error.code == NSURLErrorUnknown) {
            return TWMultiUploadFileUploadErrorCodeNone;
        }
        if (error.code == NSURLErrorBadURL || error.code == NSURLErrorUnsupportedURL) {
            return TWMultiUploadFileUploadErrorBadUrl;
        }
        if (error.code == NSURLErrorTimedOut) {
            return TWMultiUploadFileUploadErrorCodeOverMaxDuration;
        }
        if (error.code == NSURLErrorNetworkConnectionLost) {
            return TWMultiUploadFileUploadErrorCodeBadNetWork;
        }
        if(error.code == NSURLErrorBadServerResponse){
            return TWMultiUploadFileUploadErrorBadServer;
        }
    }
    return TWMultiUploadFileUploadErrorBadServer;
}

#pragma mark -- Upload
/// 上传文件片到亚马逊服务器
- (void)putFileFragmentToAWSServices:(TWMultiUploadFileFragment *)fileFragment {
    // 限制超过重试
    TWWS(weakSelf);
    /// 添加进队列执行控制最大并发数
    [self.queueManager addConcurrentOperationWithName:fileFragment.fragmentName
                                       maximumRetries:self.configure.retryTimes
                                       executionBlock:^(ConcurrentOperation * operation) {
        NSData *fileData = [fileFragment fetchFileFragmentData];
        if (fileData == nil) { // 文件片不存在
            fileFragment.uploadStatus = TWMultiUploadFileUploadStatusReadFileFail;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf failUploadingFileFragment:fileFragment errorCode:TWMultiUploadFileUploadErrorCodeFragmentReadFail];
            });
            [weakSelf.queueManager finishWithOperation:operation success:YES]; // 文件不存在，立即结不让其重试，束掉队列操作
            return;
        }
        [fileFragment setFileFragmentETagWithData:fileData]; // 设置 etag
        TWLog(@"fileFragment.fragmentName ====> %@",fileFragment.fragmentName);
        NSURL *url = [NSURL URLWithString:fileFragment.url];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"PUT";
        request.timeoutInterval = weakSelf.configure.timeoutInterval;
        NSMutableDictionary *allHTTPHeaderFields = [NSMutableDictionary dictionaryWithDictionary:@{
            @"Content-Length": [NSString stringWithFormat:@"%lu",(unsigned long)fileData.length],
            @"Content-Type": [NSString stringWithFormat:@"%@",weakSelf.configure.mimeType]
        }];
        if (weakSelf.configure.headerFields) {
            [allHTTPHeaderFields addEntriesFromDictionary:weakSelf.configure.headerFields];
        }
        request.allHTTPHeaderFields = allHTTPHeaderFields;
        if (fileData) {
            request.HTTPBody = fileData;
        }
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            TWLog(@"上传文件片到亚马逊服务器 %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            if (error) {
                TWLog(@"error %@ ==> code %ld",error,(long)error.code);
                NSInteger hadRetryTimes = [weakSelf.queueManager getCurrentAttemptWithOperation:operation]; // 当前重试次数
                if (hadRetryTimes >= weakSelf.configure.retryTimes) { // 已经做了 3 次重试了
                    TWLog(@"上传文件片到亚马逊服务器失败: %@",fileFragment.fragmentName);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf failUploadingFileFragment:fileFragment errorCode:[weakSelf getServerError:error]];
                    });
                }
                [weakSelf.queueManager finishWithOperation:operation success:NO]; // 重试
            } else {
                TWLog(@"上传文件片到亚马逊服务器完成: %@",fileFragment.fragmentName);
                [weakSelf.queueManager finishWithOperation:operation success:YES]; // 完成立即结束掉队列操作
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf successUploadingFileFragment:fileFragment];
                });
            }
            
        }] ;
        weakSelf.taskDic[TWNullClass(fileFragment.fragmentId)] = task;
        [task resume];
    }];
}

@end
