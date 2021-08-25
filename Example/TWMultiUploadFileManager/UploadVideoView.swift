//
//  UploadVideoView.swift
//  TWMultiUploadFileManager_Example
//
//  Created by zhengzeqin on 2021/8/17.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import SnapKit
import SJVideoPlayer

enum UploadVideoViewActionType {
    case selectVideo
}

class UploadVideoView: UIView {
    
    var actionBlock: ((_ type: UploadVideoViewActionType) -> Void)?
    
    // MARK: - Private Property
    fileprivate struct Metric {
        static let playerContainerViewHeightRate: CGFloat = 9 / 16
        static let progessViewHeight: CGFloat = 6
        static let titleLabelTopMargin: CGFloat = -15
        static let titleLabelHeight: CGFloat = 20
        static let videoSelectedBottomMargin: CGFloat = -10
        static let videoSelectedWidth: CGFloat = 200
        static let videoSelectedHeight: CGFloat = 195
        static let playBtnSize: CGFloat = 44
    }
    
    struct Macro {
        static let fetchVideoListFailTips = "获取播放资源失敗"
        // 最后一步占比
        static let uploadLastStepPercent: CGFloat = 0.1
        static let pauseTime: TimeInterval = 0.25
        static let fetchVideoInfoSuccessPercent: CGFloat = 0.01 // 获取资源成功的进度是 0.01
        static let uploadFilesCompletePercent: CGFloat = 0.9 // 文件上传成功，待合并
        static let requestMergeFilesCompletePercent: CGFloat = 1 // 文件合并成功
    }
    
    fileprivate lazy var playerContainerView: UIView = {
        let controlView: UIView = UIView(frame: .zero)
        return controlView
    }()
    
    
    fileprivate lazy var player: SJVideoPlayer = {
        let player: SJVideoPlayer = SJVideoPlayer()
        player.defaultEdgeControlLayer.isHiddenBackButtonWhenOrientationIsPortrait = true
        player.defaultEdgeControlLayer.isHiddenBottomProgressIndicator = true
        player.controlLayerAppearObserver.appearStateDidChangeExeBlock = { [weak self] mgr in
            guard let self = self else { return }
            self.player.promptPopupController.bottomMargin = mgr.isAppeared ? self.player.defaultEdgeControlLayer.bottomContainerView.bounds.size.height : 16
        }
        player.defaultEdgeControlLayer.bottomAdapter.removeItem(forTag: SJEdgeControlLayerBottomItem_Full)
        if #available(iOS 14.0, *) {
            player.defaultEdgeControlLayer.automaticallyShowsPictureInPictureItem = false
        }
        player.defaultEdgeControlLayer.bottomAdapter.reload()
        return player
    }()
    
    fileprivate let selectVideoView: UIView = UIView().then {
        $0.backgroundColor = .white
    }
    
    fileprivate lazy var selectVideoViewBtn: UIButton = {
        let btn: UIButton = UIButton(type: .custom)
//        btn.setTitle("選擇或錄製影片", for: .normal)
//        btn.addTarget(self, action: #selector(clickAction(_:)), for: .touchUpInside)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 26)
        btn.setTitleColor(.gray, for: .normal)
        btn.setImage(UIImage(named: "sale_house_video_upload_big_video"), for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: Metric.videoSelectedWidth, height: Metric.videoSelectedHeight)
        btn.tag = 1
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        self.backgroundColor = .black
        createUI()
    }
    
    // MARK: - Public Method
    /// 播放视频，是否暂停 默认暂停
    func play(videoUrl: URL, pause: Bool = false) {
        player.view.isHidden = false
        selectVideoView.isHidden = true
        guard let asset: SJVideoPlayerURLAsset = SJVideoPlayerURLAsset(url: videoUrl) else { return }
        self.player.urlAsset = asset
        if pause {
            self.player.pauseForUser()
        }
    }
    
    /// 暂停播放
    func pausePlay() {
        if self.player.isPlaying {
            self.player.pauseForUser()
        }
    }
    
    // MARK: - Private Method
    fileprivate func isShowVideoPlayerAndTips(_ isShow: Bool) {
        player.view.isHidden = !isShow
    }
    
    /// 是否禁止 player 的操作
    fileprivate func isForbiddenPlayerOperation(_ isForbidden: Bool) {
        player.view.isUserInteractionEnabled = !isForbidden
        player.defaultEdgeControlLayer.bottomAdapter.isHidden = isForbidden
        if isForbidden {
            self.player.pauseForUser()
        }
    }
    
    // MARK: - Action Method
    @objc func clickAction(_ btn: UIButton) {
        actionBlock?(.selectVideo)
    }
}

// MARK: - UI
extension UploadVideoView {
    fileprivate func createUI() {
        addSubview(playerContainerView)
        playerContainerView.snp.makeConstraints { make in
            make.bottom.top.left.width.equalToSuperview()
            make.height.equalTo(playerContainerView.snp.width).multipliedBy(Metric.playerContainerViewHeightRate)
        }
        
        playerContainerView.addSubview(player.view)
        player.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        playerContainerView.addSubview(selectVideoView)
        selectVideoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        selectVideoView.addSubview(selectVideoViewBtn)
        selectVideoViewBtn.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview().offset(Metric.videoSelectedBottomMargin)
            make.width.equalTo(Metric.videoSelectedWidth)
            make.height.equalTo(Metric.videoSelectedHeight)
        }
        
//        selectVideoViewBtn.layoutButton(with: .top, imageTitleSpace: 13)
    }
}

