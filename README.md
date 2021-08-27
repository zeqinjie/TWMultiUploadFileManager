# TWMultiUploadFileManager

[![CI Status](https://img.shields.io/travis/zhengzeqin/TWMultiUploadFileManager.svg?style=flat)](https://travis-ci.org/zhengzeqin/TWMultiUploadFileManager)
[![Version](https://img.shields.io/cocoapods/v/TWMultiUploadFileManager.svg?style=flat)](https://cocoapods.org/pods/TWMultiUploadFileManager)
[![License](https://img.shields.io/cocoapods/l/TWMultiUploadFileManager.svg?style=flat)](https://cocoapods.org/pods/TWMultiUploadFileManager)
[![Platform](https://img.shields.io/cocoapods/p/TWMultiUploadFileManager.svg?style=flat)](https://cocoapods.org/pods/TWMultiUploadFileManager)

## Introduce

### 背景
- 背景：最近一次业务需求是通过本地录制或者相册视频上传到亚马逊服务器。
- 研究：前端小伙伴尝试接入 SDK 发现 AWS3 的上传部分还是需要做很多工作，比如切片部分 > 5M 及 ETAG 处理等
- 决策：为了减少前端工作，决定采用后端调用 S3 SDK 方式，前端通过后端预签名后的 URL 直接进行文件分段上传

### 方案
后端执行执行 AWS3 SDK API，前端通过后端预签名后的 URL 直接进行文件分段上传

### 流程图

![图片](https://github.com/zeqinjie/TWMultiUploadFileManager/blob/master/assets/1.png)

### 功能
封装了对文件分片处理，以及上传功能
	
- 具体功能 ☑️
	- maxConcurrentOperationCount：上传线程并发个数（默认3 ）
	- maxSize：文件大小限制（默认2GB ） 
	- perSlicedSize：每个分片大小（默认5M）
	- retryTimes：每个分片上传尝试次数（默认3）
	- timeoutInterval：請求時長 （默認 120 s）
	- headerFields：附加 header
	- mimeType：文件上传类型 不为空 （默认 text/plain）
- TODO ⏳
	- 上传文件最大时长（秒s）默认7200
	- 最大缓冲分片数（默认100，建议不低于10，不高于100）
	- 附加参数， 目前封装 put 请求，后续会补充 post 请求

## Example
### step 1
从相册中选择视频源（文件）

```swift
// MARK: - Action
/// 选择影片
fileprivate func selectPhotoAction(animated: Bool = true) {
    let imagePicker: TZImagePickerController! = TZImagePickerController(maxImagesCount: 9, delegate: self)
    imagePicker.allowPickingVideo = true
    imagePicker.allowPreview = false
    imagePicker.videoMaximumDuration = Macro.videoMaximumDuration
    imagePicker.maxCropVideoDuration = Int(Macro.videoMaximumDuration)
    imagePicker.allowPickingOriginalPhoto = false
    imagePicker.allowPickingImage = false
    imagePicker.allowPickingMultipleVideo = false
    imagePicker.autoDismiss = false
    imagePicker.navLeftBarButtonSettingBlock = { leftButton in
        leftButton?.isHidden = true
    }
    present(imagePicker, animated: animated, completion: nil)
}
    
/// 获取视频资源
fileprivate func handleRequestVideoURL(asset: PHAsset)  {
    /// loading
    print("loading....")
    self.requestVideoURL(asset: asset) { [weak self] (urlasset, url) in
        guard let self = self else { return }
        print("success....")
        self.url = url
        self.asset = asset
        self.uploadVideoView.play(videoUrl: url)
    } failure: { (info) in
        print("fail....")
    }
}
```

对视频源文件进行切片并创建上传资源对象（文件）

```swift
/// 上传影片
fileprivate func uploadVideoAction() {
    guard let url = url, let asset = asset ,let outputPath: String = self.fetchVideoPath(url: url) else { return }
    let relativePath: String = TWMultiFileManager.copyVideoFile(atPath: outputPath, dirPathName: Macro.dirPathName)
    // 创建上传资源对象, 对文件进行切片
    let fileSource: TWMultiUploadFileSource = TWMultiUploadFileSource(
        configure: self.configure,
        filePath: relativePath,
        fileType: .video,
        localIdentifier: asset.localIdentifier
    )
    // 📢 上传前需要从服务端获取每个分片的上传到亚马逊 url ，执行上传
    // fileSource.setFileFragmentRequestUrls([])
    
    uploadFileManager.uploadFileSource(fileSource)
}
```
切片的核心逻辑

```objc
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
```
### step 2
- 业务逻辑：通过后端调用 AWS3 SDK 获取资源文件分片上传的 urls, 后端配合获取上传 aws3 的 url 
- 📢 这里也可以上传到自己服务端的 urls ,组件已封装的上传逻辑 put 请求，具体按各自业务修改即可


### step 3
```swift
/// 执行上传到 AWS3 服务端
uploadFileManager.uploadFileSource(fileSource)
```

设置代理回调，当然也支持 block 

```swift
extension ViewController: TWMultiUploadFileManagerDelegate {
    /// 准备开始上传
    func prepareStart(_ manager: TWMultiUploadFileManager!, fileSource: TWMultiUploadFileSource!) {
        
    }
    
    /// 文件上传中进度
    func uploadingFileManager(_ manager: TWMultiUploadFileManager!, progress: CGFloat) {
        
    }
    
    /// 完成上传
    func finish(_ manager: TWMultiUploadFileManager!, fileSource: TWMultiUploadFileSource!) {
    
    }
    
    /// 上传失败
    func fail(_ manager: TWMultiUploadFileManager!, fileSource: TWMultiUploadFileSource!, fail code: TWMultiUploadFileUploadErrorCode) {
        
    }
    
    /// 取消上传
    func cancleUploadFileManager(_ manager: TWMultiUploadFileManager!, fileSource: TWMultiUploadFileSource!) {
        
    }
    
    /// 上传中某片文件失败
    func failUploadingFileManager(_ manager: TWMultiUploadFileManager!, fileSource: TWMultiUploadFileSource!, fileFragment: TWMultiUploadFileFragment!, fail code: TWMultiUploadFileUploadErrorCode) {
        
    }
}
```
### step 4
业务逻辑：最后资源上传完毕后，后端对上传完毕的资源文件做校验 

### 📢 说明

- 业务逻辑是各自的业务方处理， 本组件封装的是上传功能：包括切片，重试次数，文件大小，分片大小，最大支持分片数等
- 具体看上传资源的配置对象

```objc
@interface TWMultiUploadConfigure : NSObject
/// 同时上传线程 默认3
@property (nonatomic, assign) NSInteger maxConcurrentOperationCount;
/// 上传文件最大限制（字节B）默认2GB
@property (nonatomic, assign) NSUInteger maxSize;
/// todo: 上传文件最大时长（秒s）默认7200
@property (nonatomic, assign) NSUInteger maxDuration;
/// todo:  最大缓冲分片数（默认100，建议不低于10，不高于100）
@property (nonatomic, assign) NSUInteger maxSliceds;
/// 每个分片占用大小（字节B）默认5M
@property (nonatomic, assign) NSUInteger perSlicedSize;
/// 每个分片上传尝试次数（默认3）
@property (nonatomic, assign) NSUInteger retryTimes;
/// 請求時長 默認 120 s
@property (nonatomic, assign) NSUInteger timeoutInterval;
/// todo: 附加参数, 目前封装 put ，后续会补充 post 请求
@property (nonatomic, strong) NSDictionary *parameters;
/// 附加 header
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *headerFields;
/// 文件上传类型 不为空 默认 text/plain
@property (nonatomic, strong) NSString *mimeType;
@end
```

## Installation

TWMultiUploadFileManager is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'TWMultiUploadFileManager'
```

## Author

zhengzeqin, zhengzeqin@addcn.com

## License

TWMultiUploadFileManager is available under the MIT license. See the LICENSE file for more info.
