//
//  TWMultiUploadConfigure.h
//  house591
//
//  Created by zhengzeqin on 2021/7/7.
//  配置对象

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TWMultiUploadConfigure : NSObject
/// 同时上传线程 默认3
@property (nonatomic, assign) NSInteger maxConcurrentOperationCount;
/// 上传文件最大限制（字节B）默认2GB
@property (nonatomic, assign) NSUInteger maxSize;
/// 上传文件最大时长（秒s）默认7200
@property (nonatomic, assign) NSUInteger maxDuration;
/// 最大缓冲分片数（默认100，建议不低于10，不高于100）
@property (nonatomic, assign) NSUInteger maxSliceds;
/// 每个分片占用大小（字节B）默认5M
@property (nonatomic, assign) NSUInteger perSlicedSize;
/// 每个分片上传尝试次数（默认3）
@property (nonatomic, assign) NSUInteger retryTimes;
/// 請求時長 默認 120 s
@property (nonatomic, assign) NSUInteger timeoutInterval;
/// 附加参数
@property (nonatomic, strong) NSDictionary *parameters;
/// 附加 header
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *headerFields;
/// 文件上传类型 不为空 默认 text/plain
@property (nonatomic, strong) NSString *mimeType;


@end

NS_ASSUME_NONNULL_END
