//
//  ViewController.swift
//  TWMultiUploadFileManager
//
//  Created by zhengzeqin on 08/17/2021.
//  Copyright (c) 2021 zhengzeqin. All rights reserved.
//  📢：采用 S3 SDK 调用都由后端执行，前端通过后端预签名后的 URL 直接进行文件分段上传

import UIKit
import TWMultiUploadFileManager
import TZImagePickerController
import Then
import SnapKit

class ViewController: UIViewController {

    fileprivate struct Macro {
        static let videoMaximumDuration: TimeInterval = 600 // 限制10分钟
        static let videoMaximumSize: UInt = 500 * 1024 * 1024 // 限制 500 M 大小
        static let dirPathName: String = "com.salehousevideoupload.upload" // 目标文件夹名称
    }
    
    /// 上传配置对象
    fileprivate let configure: TWMultiUploadConfigure = TWMultiUploadConfigure().then {
        $0.maxSize = Macro.videoMaximumSize //500 M
    }
    
    fileprivate lazy var uploadFileManager: TWMultiUploadFileManager = {
        let uploadFileManager: TWMultiUploadFileManager! = TWMultiUploadFileManager(configure: self.configure)
        return uploadFileManager
    }()
    
    fileprivate lazy var uploadVideoView: UploadVideoView = {
        let view: UploadVideoView = UploadVideoView()
        view.actionBlock = { [weak self] actionType in
            self?.clickVideoViewAction(actionType)
        }
        return view
    }()
    
    fileprivate lazy var selectVideoBtn: UIButton = {
        let btn: UIButton = UIButton(type: .custom)
        btn.setTitle("選擇或錄製影片", for: .normal)
        btn.backgroundColor = .red
        btn.addTarget(self, action: #selector(clickAction(_:)), for: .touchUpInside)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        btn.setTitleColor(.black, for: .normal)
        btn.tag = 1
        return btn
    }()
    
    fileprivate lazy var uploadVideoBtn: UIButton = {
        let btn: UIButton = UIButton(type: .custom)
        btn.setTitle("上传", for: .normal)
        btn.backgroundColor = .yellow
        btn.addTarget(self, action: #selector(clickAction(_:)), for: .touchUpInside)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        btn.setTitleColor(.black, for: .normal)
        btn.tag = 2
        return btn
    }()
    
    /// 记录最后一次选择的视频的 url
    fileprivate var url: URL?
    /// 记录最后一次选择的视频的 asset
    fileprivate var asset: PHAsset?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        createUI()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
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
    
    /// 上传影片
    fileprivate func uploadVideoAction() {
        guard let url = url, let asset = asset ,let outputPath: String = self.fetchVideoPath(url: url) else { return }
        let relativePath: String = TWMultiFileManager.copyVideoFile(atPath: outputPath, dirPathName: Macro.dirPathName)
        // 创建上传资源对象
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

    /// 视频选择按钮
    fileprivate func clickVideoViewAction(_ actionType: UploadVideoViewActionType) {
        switch actionType {
        case .selectVideo:
            selectPhotoAction()
        }
    }
    
}

// MARK: - UI
extension ViewController {
    fileprivate func createUI() {
        view.backgroundColor = .black
        view.addSubview(uploadVideoView)
        uploadVideoView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        
        view.addSubview(selectVideoBtn)
        selectVideoBtn.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.bottom.equalTo(uploadVideoView.snp.top)
            make.height.equalTo(40)
            make.width.equalTo(140)
        }
        
        view.addSubview(uploadVideoBtn)
        uploadVideoBtn.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.bottom.equalTo(uploadVideoView.snp.top)
            make.height.equalTo(40)
            make.width.equalTo(140)
        }
        
    }
    
    @objc fileprivate func clickAction(_ btn: UIButton) {
        switch btn.tag {
        case 2:
            uploadVideoAction()
        default:
            selectPhotoAction()
        }
    }
}

// MARK: - Private Method
extension ViewController {
    /// 获取视频文件地址，去掉 file://
    fileprivate func fetchVideoPath(url: URL) -> String? {
        if let path = url.absoluteString.components(separatedBy: "file://").last {
            return path
        }
        return nil
    }
    
    fileprivate func getVideoRequestOptions() -> PHVideoRequestOptions? {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        options.version = .original
        return options
    }
    
    /// 获取原始视频 url
    fileprivate func requestVideoURL(
        asset: PHAsset,
        success: ((_ avasset: AVURLAsset, _ url: URL) -> ())?,
        failure: ((_ info: [AnyHashable : Any]?) -> ())?
    ) {
        PHImageManager.default().requestAVAsset(forVideo: asset, options: getVideoRequestOptions()) { (avasset, audioMix, info) in
            DispatchQueue.main.async {
                if let avasset = avasset as? AVURLAsset {
                    success?(avasset, avasset.url)
                } else {
                    failure?(info)
                }
            }
        }
    }
    
    /// 请求资源
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
}

// MARK: - TZImagePickerControllerDelegate
extension ViewController: TZImagePickerControllerDelegate {
    /// 单个视频选择回调
    func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingPhotos photos: [UIImage]!, sourceAssets assets: [Any]!, isSelectOriginalPhoto: Bool) {
        picker.dismiss(animated: true, completion: nil)
        guard let asset = assets.first as? PHAsset else { return }
        handleRequestVideoURL(asset: asset)
    }
    
    /// 取消
    func tz_imagePickerControllerDidCancel(_ picker: TZImagePickerController!) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}
