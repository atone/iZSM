//
//  ReminderListCell.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/23.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit

class ReminderListCell: UITableViewCell {
    let setting = AppSetting.shared
    let titleLabel = UILabel()
    let boardLabel = NTLabel()
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
        boardLabel.lineBreakMode = .byClipping
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        boardLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let horizontalStack = UIStackView(arrangedSubviews: [boardLabel, infoLabel])
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .lastBaseline
        
        let verticalStack = UIStackView(arrangedSubviews: [titleLabel, horizontalStack])
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
        guard let reference = reference else { return }
        boardLabel.text = reference.boardID
        let titleDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
        titleLabel.font = UIFont.boldSystemFont(ofSize: titleDescriptor.pointSize * setting.smallFontScale)
        let infoDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
        let normalInfoFont = UIFont.systemFont(ofSize: infoDescriptor.pointSize * setting.smallFontScale)
        let boldInfoFont = UIFont.boldSystemFont(ofSize: infoDescriptor.pointSize * setting.smallFontScale)
        let normalAttributes: [NSAttributedString.Key : Any] = [.font: normalInfoFont, .foregroundColor: UIColor.secondaryLabel]
        let userIDAttributes: [NSAttributedString.Key : Any] = [.font: boldInfoFont, .foregroundColor: UIColor.secondaryLabel]
        let attributedText = NSMutableAttributedString(string: " • ", attributes: normalAttributes)
        attributedText.append(NSAttributedString(string: reference.userID, attributes: userIDAttributes))
        attributedText.append(NSAttributedString(string: " • \(reference.time.relativeDateString)", attributes: normalAttributes))
        infoLabel.attributedText = attributedText
        
        let paddingWidth = infoDescriptor.pointSize * setting.smallFontScale / 2
        boardLabel.contentInsets = UIEdgeInsets(top: 0, left: paddingWidth, bottom: 0, right: paddingWidth)
        boardLabel.clipsToBounds = true
        boardLabel.layer.cornerRadius = paddingWidth / 2
        boardLabel.textColor = UIColor.secondaryLabel
        boardLabel.font = normalInfoFont
        boardLabel.backgroundColor = UIColor.secondarySystemFill
        
        let titleFont = UIFont.boldSystemFont(ofSize: titleDescriptor.pointSize * setting.smallFontScale)
        let unreadAttributes : [NSAttributedString.Key : Any] = [.font: titleFont, .foregroundColor: UIColor.red]
        let titleAttributes : [NSAttributedString.Key : Any] = [.font: titleFont, .foregroundColor: UIColor(named: "MainText")!]
        
        let attributedTitle = NSMutableAttributedString(string: reference.subject, attributes: titleAttributes)
        if reference.flag == 0 {
            attributedTitle.append(NSAttributedString(string: " ⦁", attributes: unreadAttributes))
        }
        titleLabel.attributedText = attributedTitle
    }

    var reference: SMReference? {
        didSet {
            updateUI()
        }
    }
}
