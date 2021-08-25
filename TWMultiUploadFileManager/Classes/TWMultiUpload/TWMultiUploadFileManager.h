//
//  TWMultiUploadFileManager.h
//  house591
//
//  Created by zhengzeqin on 2021/7/7.
//  上传处理类

#import <Foundation/Foundation.h>
#import "TWMultiUploadFileSource.h"
#import "TWMultiUploadFileFragment.h"
#import "TWMultiUploadConfigure.h"
#import "TWMultiFileManager.h"

typedef NS_ENUM(NSUInteger, TWMultiUploadFileUploadErrorCode) {
    /// 未知错误
    TWMultiUploadFileUploadErrorCodeNone = 0,
    /// 超过重试次数
//    TWMultiUploadFileUploadErrorCodeOverRetry,
    /// 超过文件大小
    TWMultiUploadFileUploadErrorCodeOverMaxSize,
    /// 超过请求时长
    TWMultiUploadFileUploadErrorCodeOverMaxDuration,
    /// 分片 data 读取失败
    TWMultiUploadFileUploadErrorCodeFragmentReadFail,
    /// 不正确的参数
    TWMultiUploadFileUploadErrorCodeIncorrectParameters,
    /// 文件不存在
    TWMultiUploadFileUploadErrorCodeReadFileFail,
    /// 网络问题
    TWMultiUploadFileUploadErrorCodeBadNetWork,
    /// 服务器响应失败
    TWMultiUploadFileUploadErrorBadServer,
    /// 错误的 URL
    TWMultiUploadFileUploadErrorBadUrl,
    /// 上传总片数未足，上传失败了
    TWMultiUploadFileUploadErrorUploadFail,
};

@class TWMultiUploadFileManager;
@protocol TWMultiUploadFileManagerDelegate <NSObject>
@optional
/// 准备开始上传
- (void)prepareStartUploadFileManager:(TWMultiUploadFileManager *)manager
                           fileSource:(TWMultiUploadFileSource *)fileSource;

/// 文件上传中进度
- (void)uploadingFileManager:(TWMultiUploadFileManager *)manager
                    progress:(CGFloat)progress;

/// 完成上传
- (void)finishUploadFileManager:(TWMultiUploadFileManager *)manager
                     fileSource:(TWMultiUploadFileSource *)fileSource;

/// 上传失败
- (void)failUploadFileManager:(TWMultiUploadFileManager *)manager
                   fileSource:(TWMultiUploadFileSource *)fileSource
                failErrorCode:(TWMultiUploadFileUploadErrorCode)code;

/// 取消上传
- (void)cancleUploadFileManager:(TWMultiUploadFileManager *)manager
                     fileSource:(TWMultiUploadFileSource *)fileSource;

/// 上传中某片文件失败
- (void)failUploadingFileManager:(TWMultiUploadFileManager *)manager
                      fileSource:(TWMultiUploadFileSource *)fileSource
                    fileFragment:(TWMultiUploadFileFragment *)fileFragment
                   failErrorCode:(TWMultiUploadFileUploadErrorCode)code;

@end

@interface TWMultiUploadFileManager : NSObject
#pragma mark - LifeCycle
/// 设置配置
- (instancetype)initWithConfigure:(TWMultiUploadConfigure *)configure;

#pragma mark - Public Method
/// 准备开始上传
@property (nonatomic, copy) void (^prepareStartUploadBlock)(TWMultiUploadFileManager *manager, TWMultiUploadFileSource *fileSource);
/// 文件上传中进度
@property (nonatomic, copy) void (^uploadingBlock)(TWMultiUploadFileManager *manager, CGFloat progress);
/// 完成上传
@property (nonatomic, copy) void (^finishUploadBlock)(TWMultiUploadFileManager *manager, TWMultiUploadFileSource *fileSource);
/// 上传失败
@property (nonatomic, copy) void (^failUploadBlock)(TWMultiUploadFileManager *manager, TWMultiUploadFileSource *fileSource, TWMultiUploadFileUploadErrorCode failErrorCode);
/// 取消上传
@property (nonatomic, copy) void (^cancleUploadBlock)(TWMultiUploadFileManager *manager, TWMultiUploadFileSource *fileSource);
/// 上传中某片文件失败
@property (nonatomic, copy) void (^failUploadingBlock)(TWMultiUploadFileManager *manager, TWMultiUploadFileSource *fileSource, TWMultiUploadFileFragment *fileFragment, TWMultiUploadFileUploadErrorCode failErrorCode);

/// 设置代理
@property (nonatomic, weak) id<TWMultiUploadFileManagerDelegate> delegate;
/// 上传资源
- (void)uploadFileSource:(TWMultiUploadFileSource *)fileSource;

///  继续上传失败的文件片段，注意 fileSource 是已经经过一次上传了
- (void)continueUploadFileSource:(TWMultiUploadFileSource *)fileSource;

/// 取消上传
- (void)cancleUpload;

/// 继续队列上传
- (void)resumeUpload;

/// 暂停队列上传
- (void)pauseUpload;

@end

