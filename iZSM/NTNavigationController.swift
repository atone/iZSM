//
//  NTNavigationController.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/13.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit

class NTNavigationController: UINavigationController {
    
    private let setting = AppSetting.shared
    
    override var shouldAutorotate: Bool {
        return globalShouldRotate
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
        navigationBar.barStyle = .black
        navigationBar.tintColor = AppTheme.shared.naviContentColor
        navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: AppTheme.shared.naviContentColor]
        navigationBar.barTintColor = AppTheme.shared.naviBackgroundColor
    }
}
