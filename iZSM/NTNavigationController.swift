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
        if setting.portraitLock || globalLockPortrait {
            return [.portrait, .portraitUpsideDown]
        } else {
            return .all
        }
    }
}
