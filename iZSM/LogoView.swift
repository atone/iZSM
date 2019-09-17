//
//  LogoView.swift
//  zsmth
//
//  Created by Naitong Yu on 15/7/12.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit
import SnapKit

class LogoView: UIView {

    let imageView = UIImageView()
    let titleLabel = UILabel()
    let versionLabel = UILabel()
    let imageWidth: CGFloat = 120

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func updateUI() {
        titleLabel.textColor = UIColor(named: "SmthColor")
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        versionLabel.textColor = UIColor.secondaryLabel
        versionLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
    }

    func setup() {
        contentMode = .redraw
        imageView.image = UIImage(named: "Logo")
        imageView.clipsToBounds = true
        addSubview(imageView)
        titleLabel.text = "最水木 (iZSM)"
        addSubview(titleLabel)
        if
            let infoDictionary = Bundle.main.infoDictionary,
            let appVersion = infoDictionary["CFBundleShortVersionString"] as? String,
            let appBuild = infoDictionary["CFBundleVersion"] as? String
        {
            versionLabel.text = "版本 \(appVersion) (\(appBuild))"
            
        }
        addSubview(versionLabel)
        imageView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(imageWidth)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(8)
        }
        versionLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom)
        }
        
        updateUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = imageView.frame.width / 4
    }
}
