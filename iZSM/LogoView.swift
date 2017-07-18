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
    let versionLabel = UILabel()
    let tipsLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func updateUI() {
        backgroundColor = AppTheme.shared.lightBackgroundColor
        versionLabel.textColor = AppTheme.shared.absoluteTintColor
        versionLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        tipsLabel.textColor = AppTheme.shared.lightTextColor
        tipsLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
    }

    func setup() {
        contentMode = .redraw
        imageView.image = #imageLiteral(resourceName: "Logo")
        imageView.clipsToBounds = true
        addSubview(imageView)
        if
            let infoDictionary = Bundle.main.infoDictionary,
            let appVersion = infoDictionary["CFBundleShortVersionString"] as? String,
            let appBuild = infoDictionary["CFBundleVersion"] as? String
        {
            versionLabel.text = "最水木(iZSM) \(appVersion)(\(appBuild))"
            
        }
        addSubview(versionLabel)
        tipsLabel.numberOfLines = 0
        tipsLabel.text = "最水木追求简约、实用的设计理念，致力于给您浏览水木社区带来最好的体验。如果您用着觉得还不错，不妨赞赏一把～您的赞赏是我前进的最大动力！"
        addSubview(tipsLabel)
        imageView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.lessThanOrEqualToSuperview()
        }
        versionLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(8)
        }
        tipsLabel.translatesAutoresizingMaskIntoConstraints = false
        tipsLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8).isActive = true
        tipsLabel.topAnchor.constraint(greaterThanOrEqualTo: versionLabel.bottomAnchor, constant: 20).isActive = true
        let guide = self.readableContentGuide
        guide.leadingAnchor.constraint(equalTo: tipsLabel.leadingAnchor).isActive = true
        guide.trailingAnchor.constraint(equalTo: tipsLabel.trailingAnchor).isActive = true
        updateUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = imageView.frame.width / 4
    }
}
