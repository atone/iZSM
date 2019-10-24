//
//  NTNavigationController.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/13.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit

class NTNavigationController: UINavigationController {
    
    override var title: String? {
        get {
            if let vc = topViewController {
                return vc.title
            }
            return nil
        }
        set {
            super.title = newValue
        }
    }
    
    override var shouldAutorotate: Bool {
        return globalShouldRotate
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if globalLockPortrait {
            return [.portrait, .portraitUpsideDown]
        } else {
            return .all
        }
    }
    
    override var childForStatusBarHidden: UIViewController? {
        return topViewController
    }
}
