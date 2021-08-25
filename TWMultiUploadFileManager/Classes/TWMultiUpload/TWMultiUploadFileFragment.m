//
//  TWMultiUploadFileFragment.m
//  house591
//
//  Created by zhengzeqin on 2021/7/7.
// 

#import "TWMultiUploadFileFragment.h"
#import "TWMultiFileManager.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCrypto.h>
#import <CommonCrypto/CommonHMAC.h>

@implementation TWMultiUploadFileFragment
/// 获取文件大小
- (NSData *)fetchFileFragmentData {
    NSData *data = nil;
    /// 资源文件的绝对路径
    NSString *absolutePath = [[TWMultiFileManager cachesDir] stringByAppendingPathComponent:self.filePath];
    if ([TWMultiFileManager isExistsAtPath:absolutePath]) {
        NSFileHandle *readHandle = [NSFileHandle fileHandleForReadingAtPath:absolutePath];
        [readHandle seekToFileOffset:self.fragmentOffset];
        /// 读取文件
        data = [readHandle readDataOfLength:self.fragmentSize];
        /// CoderMikeHe Fixed Bug: 获取了数据，要关闭文件
        [readHandle closeFile];
    }else{
        TWLog(@"😭😭😭+++ 上传文件不存在 +++😭😭😭》〉");
    }
    return data;
}

///  设置上传亚马逊的 eTag
- (void)setFileFragmentETagWithData:(NSData *)data {
    self.eTag = [self fetchFileFragmentETagWithData:data];
}

#pragma mark - Private Method
/// 获取 aws3 的Etag
- (NSString *)fetchFileFragmentETagWithData:(NSData *)data {
    NSString *md5String = [self md5WithData:data];
    TWLog(@"获取 aws3 的Etag = %@",md5String);
    return md5String;
}

- (NSString *)md5WithData:(NSData *)data {
    unsigned char digist[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, digist);
    NSMutableString *outPutStr = [NSMutableString stringWithCapacity:10];
    for(int  i =0; i<CC_MD5_DIGEST_LENGTH;i++){
        [outPutStr appendFormat:@"%02x",digist[i]];//小写x表示输出的是小写MD5，大写X表示输出的是大写MD5
    }
    return [outPutStr lowercaseString];
    
}


@end
