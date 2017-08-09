//
//  NTSafariViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/8/9.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit
import SafariServices

class NTSafariViewController: SFSafariViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.statusBarStyle = .default
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag) { 
            UIApplication.shared.statusBarStyle = .lightContent
            completion?()
        }
    }
}
