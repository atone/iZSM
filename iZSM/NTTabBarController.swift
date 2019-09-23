//
//  NTTabBarController.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/13.
//  Copyright © 2017 Naitong Yu. All rights reserved.
//

import UIKit
import SVProgressHUD

class NTTabBarController: UITabBarController {

    private let setting = AppSetting.shared
    
    override var shouldAutorotate: Bool {
        return globalShouldRotate
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if setting.portraitLock || globalLockPortrait {
            return [.portrait, .portraitUpsideDown]
        } else {
            return .all
        }
    }
    
    override var childForStatusBarHidden: UIViewController? {
        return selectedViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        updateSVProgressHUDStyle()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            updateSVProgressHUDStyle()
        }
    }
    
    private func updateSVProgressHUDStyle() {
        if traitCollection.userInterfaceStyle == .dark {
            SVProgressHUD.setDefaultStyle(.dark)
        } else {
            SVProgressHUD.setDefaultStyle(.light)
        }
    }
}
