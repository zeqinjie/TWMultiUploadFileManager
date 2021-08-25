//
//  TWMultiUploadFileFragment.h
//  house591
//
//  Created by zhengzeqin on 2021/7/7.
//  每个文件分片

#import <Foundation/Foundation.h>
#import "TWMultiUploadHeader.h"
NS_ASSUME_NONNULL_BEGIN

@interface TWMultiUploadFileFragment : NSObject
/// 片的大小
@property (nonatomic, assign) NSUInteger fragmentSize;
/// 片的偏移量
@property (nonatomic, assign) NSUInteger fragmentOffset;
/// 片的索引 --- 切片 index 的部分 <从0开始> 对应接口 part 部分 <从1开始>
@property (nonatomic ,assign) NSUInteger fragmentIndex;
/// 源文件的ID localIdentifier <iOS 8.0 + 以后的版本  PHAsset 的唯一标识 ，用这个去获取 PHAsset对象，但是可能会因为用户从相册中删除，而获取不到 PHAsset>
@property (nonatomic, copy) NSString *localIdentifier;
/// 分配的的独立 id 采用 源文件的ID localIdentifier 拼接 index
@property (nonatomic, copy) NSString *fragmentId;
/// 每个分片的设置的独立文件名字
@property (nonatomic, copy) NSString *fragmentName;
/// 文件后缀 mp4
@property (nonatomic, copy) NSString *pathExtension;
/// 文件块ID aws3 etag 唯一标识
@property (nonatomic, copy) NSString *eTag;
/// 该文件片所处的文件块总大小 --- 对应接口<`totalSize`>
@property (nonatomic, assign) NSInteger totalFileSize;
/// 该文件片所处的文件块总片数 --- 对应接口<`blockTotal`>
@property (nonatomic, assign) NSInteger totalFileFragment;
/// 该文件片所处的文件块的文件路径
@property (nonatomic, copy) NSString *filePath;
/// 已请求次数记录，用以支持最多支持多少次重试机会
@property (nonatomic, assign) NSInteger hadRetryTimes;
/// fileType 文件类型
@property (nonatomic, assign) TWMultiUploadFileType fileType;
/// put 请求的 URL
@property (nonatomic, copy) NSString *url;
/// 当前上传状态 <默认是TWMultiUploadFileUploadStatusWaiting>
@property (nonatomic, assign) TWMultiUploadFileUploadStatus uploadStatus;

/// 获取文件大小
- (NSData *)fetchFileFragmentData;
///  设置上传亚马逊的 eTag
- (void)setFileFragmentETagWithData:(NSData *)data;
@end

NS_ASSUME_NONNULL_END
