//
//  HotTableViewCell.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/21.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SmthConnection

class HotTableViewCell: UITableViewCell {
    let setting = AppSetting.shared
    let titleLabel = UILabel()
    let boardLabel = NTLabel()
    let userIDLabel = UILabel()
    let replyLabel = NTLabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    /// Setup constraints
    func setupUI() {
        titleLabel.numberOfLines = 0
        boardLabel.lineBreakMode = .byClipping
        replyLabel.lineBreakMode = .byClipping
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        boardLabel.translatesAutoresizingMaskIntoConstraints = false
        userIDLabel.translatesAutoresizingMaskIntoConstraints = false
        replyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        replyLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        let lowerHorizontalStack = UIStackView(arrangedSubviews: [boardLabel, userIDLabel])
        lowerHorizontalStack.translatesAutoresizingMaskIntoConstraints = false
        lowerHorizontalStack.axis = .horizontal
        lowerHorizontalStack.alignment = .lastBaseline
        
        let leftVerticalStack = UIStackView(arrangedSubviews: [titleLabel, lowerHorizontalStack])
        leftVerticalStack.translatesAutoresizingMaskIntoConstraints = false
        leftVerticalStack.axis = .vertical
        leftVerticalStack.alignment = .leading
        leftVerticalStack.spacing = 5
        
        let horizontalStack = UIStackView(arrangedSubviews: [leftVerticalStack, replyLabel])
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .center
        horizontalStack.spacing = 5
        
        contentView.addSubview(horizontalStack)
        
        horizontalStack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        horizontalStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        horizontalStack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        horizontalStack.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
    }
    
    /// Update font size and color
    func updateUI() {
        let titleDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
        let replyDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
        
        if setting.useBoldFont {
            titleLabel.font = UIFont.boldSystemFont(ofSize: titleDescriptor.pointSize * setting.smallFontScale)
        } else {
            titleLabel.font = UIFont.systemFont(ofSize: titleDescriptor.pointSize * setting.smallFontScale)
        }
        replyLabel.font = UIFont.boldSystemFont(ofSize: replyDescriptor.pointSize * setting.smallFontScale)
        
        if let thread = hotThread {
            let infoDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .footnote)
            let normalInfoFont = UIFont.systemFont(ofSize: infoDescriptor.pointSize * setting.smallFontScale)
            let boldInfoFont = UIFont.boldSystemFont(ofSize: infoDescriptor.pointSize * setting.smallFontScale)
            let normalAttributes: [NSAttributedString.Key : Any] = [.font: normalInfoFont, .foregroundColor: UIColor.secondaryLabel]
            let userIDAttributes: [NSAttributedString.Key : Any] = [.font: boldInfoFont, .foregroundColor: UIColor.secondaryLabel]
            let attributedText = NSMutableAttributedString(string: " • ", attributes: normalAttributes)
            attributedText.append(NSAttributedString(string: thread.authorID, attributes: userIDAttributes))
            userIDLabel.attributedText = attributedText
            
            let paddingWidth = infoDescriptor.pointSize * setting.smallFontScale / 2
            boardLabel.contentInsets = UIEdgeInsets(top: 0, left: paddingWidth, bottom: 0, right: paddingWidth)
            boardLabel.clipsToBounds = true
            boardLabel.layer.cornerRadius = paddingWidth / 2
            boardLabel.textColor = UIColor.secondaryLabel
            boardLabel.font = normalInfoFont
            boardLabel.backgroundColor = UIColor.secondarySystemFill
        }
        titleLabel.textColor = UIColor(named: "MainText")
        replyLabel.textColor = UIColor.systemBackground
        replyLabel.backgroundColor = UIColor.systemGray
        let paddingWidth = replyDescriptor.pointSize * setting.smallFontScale / 2
        replyLabel.contentInsets = UIEdgeInsets(top: 0, left: paddingWidth, bottom: 0, right: paddingWidth)
        replyLabel.clipsToBounds = true
        replyLabel.layer.cornerRadius = paddingWidth
    }
    
    var hotThread: SMHotThread? {
        didSet {
            if let hotThread = hotThread {
                titleLabel.text = hotThread.subject
                boardLabel.text = hotThread.boardID
                replyLabel.text = String(hotThread.count)
                updateUI()
            }
        }
    }
}
