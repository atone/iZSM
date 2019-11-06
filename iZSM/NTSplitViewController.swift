//
//  NTSplitViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2019/10/9.
//  Copyright © 2019 Naitong Yu. All rights reserved.
//

import UIKit

class NTSplitViewController: UISplitViewController {
    
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
        if isCollapsed {
            return viewControllers.first
        } else {
            return viewControllers.last
        }
    }
}

extension NTSplitViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyCommands()
    }
    
    private func setupKeyCommands() {
        let hotKeyCommand = UIKeyCommand(title: "切换到“十大”", action: #selector(receiveKeyCommand(_:)), input: "1", modifierFlags: [.command])
        addKeyCommand(hotKeyCommand)
        let boardKeyCommand = UIKeyCommand(title: "切换到“版面”", action: #selector(receiveKeyCommand(_:)), input: "2", modifierFlags: [.command])
        addKeyCommand(boardKeyCommand)
        let favoriteKeyCommand = UIKeyCommand(title: "切换到“收藏”", action: #selector(receiveKeyCommand(_:)), input: "3", modifierFlags: [.command])
        addKeyCommand(favoriteKeyCommand)
        let userKeyCommand = UIKeyCommand(title: "切换到“用户”", action: #selector(receiveKeyCommand(_:)), input: "4", modifierFlags: [.command])
        addKeyCommand(userKeyCommand)
    }
    
    @objc private func receiveKeyCommand(_ sender: UIKeyCommand) {
        guard let input = sender.input else { return }
        guard let intKey = Int(input) else { return }
        guard let tabBarViewController = viewControllers.first as? NTTabBarController else { return }
        tabBarViewController.selectedIndex = intKey - 1
    }
}
