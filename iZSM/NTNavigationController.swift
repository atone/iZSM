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
    }
    
    private func changeColor() {
        navigationBar.barStyle = .black
        switch traitCollection.userInterfaceStyle {
        case .dark:
            let naviForgoundColor = UIColor(red: 215/255.0, green: 215/255.0, blue: 215/255.0, alpha: 1)
            let naviBackgroundColor = UIColor.black
            navigationBar.tintColor = naviForgoundColor
            navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: naviForgoundColor]
            navigationBar.barTintColor = naviBackgroundColor
        default:
            let naviForgoundColor = UIColor.white
            let naviBackgroundColor = UIColor(red: 0/255.0, green: 139/255.0, blue: 203/255.0, alpha: 1)
            navigationBar.tintColor = naviForgoundColor
            navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: naviForgoundColor]
            navigationBar.barTintColor = naviBackgroundColor
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            changeColor()
        }
    }
}
