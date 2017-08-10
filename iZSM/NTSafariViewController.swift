//
//  NTSafariViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/8/10.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit
import SafariServices

class NTSafariViewController: SFSafariViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 10.0, *) {
            preferredControlTintColor = AppTheme.shared.absoluteTintColor
        } else {
            view.tintColor = AppTheme.shared.absoluteTintColor
        }
    }
}
