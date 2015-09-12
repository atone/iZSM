//
//  LogoView.swift
//  zsmth
//
//  Created by Naitong Yu on 15/7/12.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class LogoView: UIView {

    let imageView = UIImageView(frame: CGRectZero)
    let versionLabel = UILabel(frame: CGRectZero)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func setup() {
        contentMode = .Redraw
        backgroundColor = UIColor.groupTableViewBackgroundColor()
        imageView.image = UIImage(named: "Logo")
        addSubview(imageView)
        if let infoDictionary = NSBundle.mainBundle().infoDictionary,
            appVersion = infoDictionary["CFBundleShortVersionString"] as? String,
            appBuild = infoDictionary["CFBundleVersion"] as? String
        {
            versionLabel.text = "最水木(iZSM) \(appVersion)(\(appBuild))"
            versionLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
            versionLabel.textColor = UIColor.darkGrayColor()
        }
        addSubview(versionLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.sizeToFit()
        versionLabel.sizeToFit()
        imageView.layer.cornerRadius = imageView.frame.width/4
        imageView.clipsToBounds = true

        imageView.center = CGPoint(x: bounds.width/2, y: bounds.height/2)
        versionLabel.center = CGPoint(x: bounds.width/2, y: bounds.height/2+(imageView.frame.height+versionLabel.frame.height)/2+8)
    }

}
