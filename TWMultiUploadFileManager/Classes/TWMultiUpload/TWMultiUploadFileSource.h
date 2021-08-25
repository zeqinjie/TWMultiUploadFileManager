//
//  TWMultiUploadFileSource.h
//  house591
//
//  Created by zhengzeqin on 2021/7/7.
//  文件资源

#import <Foundation/Foundation.h>
#import "TWMultiUploadFileFragment.h"
#import "TWMultiUploadHeader.h"
#import "TWMultiUploadConfigure.h"
NS_ASSUME_NONNULL_BEGIN

@interface TWMultiUploadFileSource : NSObject
/// 包括文件后缀名的文件名
@property (nonatomic , readwrite , copy) NSString *fileName;
/// localIdentifier <iOS 8.0 + 以后的版本  PHAsset 的唯一标识 ，用这个去获取 PHAsset对象，但是可能会因为用户从相册中删除，而获取不到 PHAsset>
@property (nonatomic, copy) NSString *localIdentifier;
/// 文件后缀 mp4
@property (nonatomic, copy) NSString *pathExtension;
/// 文件所在路径 <相对路径>
@property (nonatomic , copy) NSString *filePath;
/// fileType 文件类型
@property (nonatomic , assign) TWMultiUploadFileType fileType;
/// 文件资源总大小 <所有文件块的总大小之和> 无需手动设置  单位 字节B
@property (nonatomic , assign) NSInteger totalFileSize;
/// 文件资源总片数 <所有文件块的总片数之和> 无需手动设置
@property (nonatomic , assign) CGFloat totalFileFragment;
/// 上传完成成功的总片数
@property (nonatomic , assign) CGFloat totalUploadSuccessFileFragment;
/// 上传失败的总片数
@property (nonatomic , assign) CGFloat totalUploadFaileFileFragment;
/// fileFragments 该资源下的所有文件片 无需手动设置
@property (nonatomic , strong) NSArray <TWMultiUploadFileFragment *> *fileFragments;
/// 文件的上传状态 <默认是TWMultiUploadFileUploadStatusWaiting>
@property (nonatomic , assign) TWMultiUploadFileUploadStatus uploadStatus;
/// 上传成功的切片的独立 [fragmentId : fileFragment]
@property (nonatomic, strong) NSMutableDictionary<NSString *,TWMultiUploadFileFragment *> *finishUploadFileFragmentDic;
/// 上传失败的切片的独立 [fragmentId : fileFragment]
@property (nonatomic, strong) NSMutableDictionary<NSString *,TWMultiUploadFileFragment *> *failUploadFileFragmentDic;

#pragma mark - LifeCycle Method
/// 创建上传的资源文件
- (instancetype)initWithConfigure:(TWMultiUploadConfigure *)configure
                         filePath:(NSString *)filePath
                         fileType:(TWMultiUploadFileType)fileType
                  localIdentifier:(NSString *)localIdentifier;

#pragma mark - Public Method
/// 设置分配请求的 aws3 url
- (void)setFileFragmentRequestUrls:(NSArray<NSString*>*)urls;

/// 上传成功，删除文件
- (BOOL)deletFile;
@end

NS_ASSUME_NONNULL_END
