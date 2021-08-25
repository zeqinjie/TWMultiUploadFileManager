//
//  UIButton+ImageTitleSpacing.swift
//  TWMultiUploadFileManager_Example
//
//  Created by zhengzeqin on 2021/8/17.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
enum MKButtonEdgeInsetsStyle : Int {
    case top // image在上，label在下
    case left // image在左，label在右
    case bottom // image在下，label在上
    case right // image在右，label在左
}

extension UIButton {
    func layoutButton(
        with style: MKButtonEdgeInsetsStyle,
        imageTitleSpace space: CGFloat
    ) {
        let imageWith = imageView?.frame.size.width ?? 0.0
        let imageHeight = imageView?.frame.size.height ?? 0.0

        var labelWidth: CGFloat = 0.0
        var labelHeight: CGFloat = 0.0
        
        if Float(UIDevice.current.systemVersion) ?? 0.0 >= 8.0 {
            // 由于iOS8中titleLabel的size为0，用下面的这种设置
            labelWidth = titleLabel?.intrinsicContentSize.width ?? 0
            labelHeight = titleLabel?.intrinsicContentSize.height ?? 0
        } else {
            labelWidth = titleLabel?.frame.size.width ?? 0
            labelHeight = titleLabel?.frame.size.height ?? 0
        }
        
        // 2. 声明全局的imageEdgeInsets和labelEdgeInsets
        var imageEdgeInsets: UIEdgeInsets = .zero
        var labelEdgeInsets: UIEdgeInsets = .zero
        
        switch style {
        case .top:
            imageEdgeInsets = UIEdgeInsets(top: -labelHeight - space / 2.0, left: 0, bottom: 0, right: -labelWidth)
            labelEdgeInsets = UIEdgeInsets(top: 0, left: -imageWith, bottom: -imageHeight - space / 2.0, right: 0)
        case .left:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: -space / 2.0, bottom: 0, right: space / 2.0)
        case .bottom:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: -labelHeight - space / 2.0, right: -labelWidth)
            labelEdgeInsets = UIEdgeInsets(top: -imageHeight - space / 2.0, left: -imageWith, bottom: 0, right: 0)
        case .right:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: labelWidth + space / 2.0, bottom: 0, right: -labelWidth - space / 2.0)
            labelEdgeInsets = UIEdgeInsets(top: 0, left: -imageWith - space / 2.0, bottom: 0, right: imageWith + space / 2.0)
        }
        self.titleEdgeInsets = labelEdgeInsets
        self.imageEdgeInsets = imageEdgeInsets
    }
}
