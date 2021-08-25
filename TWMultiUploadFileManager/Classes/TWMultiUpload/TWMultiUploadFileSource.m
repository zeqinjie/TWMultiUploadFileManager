//
//  TWMultiUploadFileSource.m
//  house591
//
//  Created by zhengzeqin on 2021/7/7.
//

#import "TWMultiUploadFileSource.h"
#import "TWMultiFileManager.h"

@interface TWMultiUploadFileSource()
@property (nonatomic, strong) TWMultiUploadConfigure *configure;
@end

@implementation TWMultiUploadFileSource

#pragma mark - LifeCycle Method
- (instancetype)initWithConfigure:(TWMultiUploadConfigure *)configure
                         filePath:(NSString *)filePath
                         fileType:(TWMultiUploadFileType)fileType
                  localIdentifier:(NSString *)localIdentifier {
    if (self = [super init]) {
        self.configure = configure;
        self.localIdentifier = localIdentifier;
        self.fileType = fileType;
        self.finishUploadFileFragmentDic = [NSMutableDictionary dictionary];
        self.failUploadFileFragmentDic = [NSMutableDictionary dictionary];
        BOOL fetchFileSuccess = [self fetchFileInfoAtPath:filePath];
        if (fetchFileSuccess) { // 获取文件成功
            [self cutFileForFragments];
        } else {
            self.uploadStatus = TWMultiUploadFileUploadStatusReadFileFail;
        }
    }
    return self;
}

#pragma mark - Public Method
/// 设置分配请求的 url 信息
- (void)setFileFragmentRequestUrls:(NSArray<NSString*>*)urls {
    for (NSInteger i = 0; i < self.fileFragments.count; i++) {
        TWMultiUploadFileFragment *fFragment = self.fileFragments[i];
        if (fFragment && urls.count > i) {
            fFragment.url = urls[i];
            TWLog(@"设置分配请求的 url 信息 %@: %@",fFragment.fragmentId,fFragment.url);
        }
    }
}

/// 上传成功，删除文件
- (BOOL)deletFile {
    NSString *cachesDir = [TWMultiFileManager cachesDir];
    NSString *fileDirPath = [cachesDir stringByAppendingPathComponent:self.filePath];
    BOOL isSuccess = [TWMultiFileManager removeItemAtPath:fileDirPath];
    if (isSuccess) {
        TWLog(@"删除文件成功...");
    } else {
        TWLog(@"删除文件失败...");
    }
    return isSuccess;
}

#pragma mark - Pirvate Method
/// 获取文件信息
- (BOOL)fetchFileInfoAtPath:(NSString *)path {
    // 验证文件存在
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    // 拼接路径，path 是相对路径
    NSString *absolutePath = [[TWMultiFileManager cachesDir] stringByAppendingPathComponent:path];
    if (![fileMgr fileExistsAtPath:absolutePath]) {
        TWLog(@"+++ 文件不存在 +++：%@",absolutePath);
        return NO;
    }
    // 存取文件路径
    self.filePath = path;
    
    // 文件大小
    NSDictionary *attr = [fileMgr attributesOfItemAtPath:absolutePath error:nil];
    // 单位是 B
    self.totalFileSize = attr.fileSize;
    
    // 文件名
    NSString *fileName = [path lastPathComponent];
    self.fileName = fileName;
    // 文件类型名
    self.pathExtension = fileName.pathExtension;
//    // 文件类型
//    self.fileType = ([self.videoTypeArr containsObject:fileName.pathExtension.lowercaseString]) ? TWMultiUploadFileTypeVideo:TWMultiUploadFileTypePicture;
    
    return YES;
}

/// 切片处理
- (void)cutFileForFragments {
    NSUInteger offset = self.configure.perSlicedSize;
    // 总片数
    NSUInteger totalFileFragment = (self.totalFileSize%offset==0)?(self.totalFileSize/offset):(self.totalFileSize/(offset) + 1);
    self.totalFileFragment = totalFileFragment;
    NSMutableArray<TWMultiUploadFileFragment *> *fragments = [NSMutableArray array];
    for (NSUInteger i = 0; i < totalFileFragment; i++) {
        TWMultiUploadFileFragment *fFragment = [[TWMultiUploadFileFragment alloc] init];
        fFragment.fragmentIndex = i+1; // 从 1 开始
        fFragment.uploadStatus = TWMultiUploadFileUploadStatusWaiting;
        fFragment.fragmentOffset = i * offset;
        if (i != totalFileFragment - 1) {
            fFragment.fragmentSize = offset;
        } else {
            fFragment.fragmentSize = self.totalFileSize - fFragment.fragmentOffset;
        }
        /// 关联属性
        fFragment.localIdentifier = self.localIdentifier;
        fFragment.fragmentId = [NSString stringWithFormat:@"%@-%ld",self.localIdentifier, (long)i];
        fFragment.fragmentName = [NSString stringWithFormat:@"%@-%ld.%@",self.localIdentifier, (long)i, self.fileName.pathExtension];
        fFragment.fileType = self.fileType;
        fFragment.filePath = self.filePath;
        fFragment.totalFileFragment = self.totalFileFragment ;
        fFragment.totalFileSize = self.totalFileSize;
        [fragments addObject:fFragment];
    }
    self.fileFragments = fragments;
}

@end
