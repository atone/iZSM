//
//  MailListCell.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/23.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SmthConnection

class MailListCell: UITableViewCell {
    let setting = AppSetting.shared
    let titleLabel = UILabel()
    let infoLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    func setupUI() {
        titleLabel.numberOfLines = 0
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let verticalStack = UIStackView(arrangedSubviews: [titleLabel, infoLabel])
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        verticalStack.axis = .vertical
        verticalStack.alignment = .leading
        verticalStack.spacing = 5
        
        contentView.addSubview(verticalStack)
        
        verticalStack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        verticalStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        verticalStack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        verticalStack.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
    }
    
    func updateUI() {
        guard let mail = mail else { return }
        let titleDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
        let infoDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .footnote)
        
        let normalInfoFont = UIFont.systemFont(ofSize: infoDescriptor.pointSize * setting.smallFontScale)
        let boldInfoFont = UIFont.boldSystemFont(ofSize: infoDescriptor.pointSize * setting.smallFontScale)
        let normalAttributes: [NSAttributedString.Key : Any] = [.font: normalInfoFont, .foregroundColor: UIColor.secondaryLabel]
        let userIDAttributes: [NSAttributedString.Key : Any] = [.font: boldInfoFont, .foregroundColor: UIColor.secondaryLabel]
        let attributedText = NSMutableAttributedString(string: mail.authorID, attributes: userIDAttributes)
        attributedText.append(NSAttributedString(string: " • \(mail.time.relativeDateString)", attributes: normalAttributes))
        infoLabel.attributedText = attributedText
        
        let titleFont: UIFont
        if setting.useBoldFont {
            titleFont = UIFont.boldSystemFont(ofSize: titleDescriptor.pointSize * setting.smallFontScale)
        } else {
            titleFont = UIFont.systemFont(ofSize: titleDescriptor.pointSize * setting.smallFontScale)
        }
        let unreadAttributes : [NSAttributedString.Key : Any] = [.font: titleFont, .foregroundColor: UIColor.red]
        let titleAttributes : [NSAttributedString.Key : Any] = [.font: titleFont, .foregroundColor: UIColor(named: "MainText")!]
        
        let attributedTitle = NSMutableAttributedString(string: mail.subject, attributes: titleAttributes)
        if mail.flags.hasPrefix("N") {
            attributedTitle.append(NSAttributedString(string: " ⦁", attributes: unreadAttributes))
        }
        titleLabel.attributedText = attributedTitle
    }

    var mail: SMMail? {
        didSet {
            updateUI()
        }
    }
}
