//
//  NTViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/16.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit

class NTViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        view.becomeFirstResponder()
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        view.resignFirstResponder()
        super.viewDidDisappear(animated)
    }
    
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        if AppSetting.shared.shakeToSwitch && motion == .motionShake {
            print("shaking phone... switch color theme")
            AppSetting.shared.nightMode = !AppSetting.shared.nightMode
            NotificationCenter.default.post(name: AppTheme.kAppThemeChangedNotification, object: nil)
        }
    }
}
