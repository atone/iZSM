//
//  NTTabBarController.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/13.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit

class NTTabBarController: UITabBarController {

    private let setting = AppSetting.shared
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if setting.portraitLock {
            return [.portrait, .portraitUpsideDown]
        } else {
            return .all
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changeColor()
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeChanged(_:)), name: AppTheme.kAppThemeChangedNotification, object: nil)
    }
    
    @objc private func nightModeChanged(_ notification: Notification) {
        changeColor()
    }
    
    private func changeColor() {
        tabBar.tintColor = AppTheme.shared.tintColor
        tabBar.barTintColor = AppTheme.shared.tabBackgroundColor
    }

}
