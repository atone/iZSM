//
//  PlaceholderViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2019/10/9.
//  Copyright © 2019 Naitong Yu. All rights reserved.
//

import UIKit
import SnapKit

class PlaceholderViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let logoView = UIImageView(image: UIImage(named: "Logo"))
        logoView.clipsToBounds = true
        logoView.layer.cornerRadius = 30
        view.addSubview(logoView)
        view.backgroundColor = .systemBackground
        logoView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(120)
        }
    }
}
