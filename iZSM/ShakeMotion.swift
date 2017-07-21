//
//  ShakeMotion.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/21.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit

extension UIWindow {
    open override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if AppSetting.shared.shakeToSwitch && motion == .motionShake {
            print("shaking phone... switch color theme")
            AppSetting.shared.nightMode = !AppSetting.shared.nightMode
            NotificationCenter.default.post(name: AppTheme.kAppThemeChangedNotification, object: nil)
        }
    }
}
