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
        preferredControlTintColor = UIColor(named: "SmthColor")
    }
}
