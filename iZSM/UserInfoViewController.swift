//
//  UserInfoViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/9.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit
import SnapKit
import SVProgressHUD

class UserInfoViewController: UIViewController {
    
    var userID: String?
    var label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = userID
        view.backgroundColor = UIColor.white
        label.numberOfLines = 0
        label.textAlignment = .center
        view.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.leadingMargin.equalTo(view)
            make.trailingMargin.equalTo(view)
            make.topMargin.equalTo(view)
            make.bottomMargin.equalTo(view)
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let userID = userID {
            SVProgressHUD.show()
            SMUserInfoUtil.querySMUser(for: userID) { (user) in
                self.label.text = user.debugDescription
                SVProgressHUD.dismiss()
            }
        }
    }
}
