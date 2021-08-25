//
//  TWMultiUploadHeader.h
//  house591
//
//  Created by zhengzeqin on 2021/7/7.
//  分片上传亚马逊 aws3 服务器

#ifndef TWMultiUploadHeader_h
#define TWMultiUploadHeader_h

/// 文件片上传状态
typedef NS_ENUM(NSUInteger, TWMultiUploadFileUploadStatus) {
    TWMultiUploadFileUploadStatusWaiting = 0,     /// 准备上传
    TWMultiUploadFileUploadStatusUploading,       /// 正在上传
    TWMultiUploadFileUploadStatusFinished,        /// 上传完成
    TWMultiUploadFileUploadStatusFail,  /// 上传失败
    TWMultiUploadFileUploadStatusPaused, /// 暂停
    TWMultiUploadFileUploadStatusReadFileFail, // 文件读取失败
};

typedef NS_ENUM(NSInteger ,TWMultiUploadFileType) {
    TWMultiUploadFileTypePicture = 0,   /// 图片
    TWMultiUploadFileTypeVideo = 1,     /// 视频
};

#define TWLog(format, ...) printf("DEBUG class: <%s:(%d) > method: %s \n%s\n", [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, __PRETTY_FUNCTION__, [[NSString stringWithFormat:(format), ##__VA_ARGS__] UTF8String] )

#endif /* TWMultiUploadHeader_h */
