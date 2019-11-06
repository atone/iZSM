//
//  StarThreadViewCell.swift
//  iZSM
//
//  Created by Naitong Yu on 2019/9/28.
//  Copyright © 2019 Naitong Yu. All rights reserved.
//

import UIKit

class StarThreadViewCell: UITableViewCell {
    
    var title: String?
    var boardID: String?
    var authorID: String?
    var postTime: Date?
    var comment: String?

    private let setting = AppSetting.shared
    private let titleLabel = UILabel()
    private let boardLabel = NTLabel()
    private let userIDLabel = UILabel()
    private let commentLabel = UILabel()
    
    func configure(with thread: StarThread?) {
        self.title = thread?.articleTitle
        self.boardID = thread?.boardID
        self.authorID = thread?.authorID
        self.postTime = thread?.postTime
        self.comment = thread?.comment
        updateUI()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    /// Setup constraints
    private func setupUI() {
        titleLabel.numberOfLines = 0
        boardLabel.lineBreakMode = .byClipping
        commentLabel.numberOfLines = 0
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        boardLabel.translatesAutoresizingMaskIntoConstraints = false
        userIDLabel.translatesAutoresizingMaskIntoConstraints = false
        commentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let upperHorizontalStack = UIStackView(arrangedSubviews: [boardLabel, userIDLabel])
        upperHorizontalStack.translatesAutoresizingMaskIntoConstraints = false
        upperHorizontalStack.axis = .horizontal
        upperHorizontalStack.alignment = .lastBaseline
        
        let verticalStack = UIStackView(arrangedSubviews: [upperHorizontalStack, titleLabel, commentLabel])
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        verticalStack.axis = .vertical
        verticalStack.alignment = .leading
        verticalStack.spacing = 5
        verticalStack.distribution = .equalSpacing
        
        contentView.addSubview(verticalStack)
        
        verticalStack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        verticalStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        verticalStack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        verticalStack.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
    }
    
    /// Update font size and color
    private func updateUI() {
        if let title = title, let boardID = boardID, let authorID = authorID, let postTime = postTime {
            titleLabel.text = title
            boardLabel.text = boardID
            let titleDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
            if setting.useBoldFont {
                titleLabel.font = UIFont.boldSystemFont(ofSize: titleDescriptor.pointSize * setting.smallFontScale)
            } else {
                titleLabel.font = UIFont.systemFont(ofSize: titleDescriptor.pointSize * setting.smallFontScale)
            }
            let infoDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .footnote)
            let normalInfoFont = UIFont.systemFont(ofSize: infoDescriptor.pointSize * setting.smallFontScale)
            let boldInfoFont = UIFont.boldSystemFont(ofSize: infoDescriptor.pointSize * setting.smallFontScale)
            let normalAttributes: [NSAttributedString.Key : Any] = [.font: normalInfoFont, .foregroundColor: UIColor.secondaryLabel]
            let userIDAttributes: [NSAttributedString.Key : Any] = [.font: boldInfoFont, .foregroundColor: UIColor.secondaryLabel]
            let attributedText = NSMutableAttributedString(string: " • ", attributes: normalAttributes)
            attributedText.append(NSAttributedString(string: authorID, attributes: userIDAttributes))
            attributedText.append(NSAttributedString(string: " • \(postTime.relativeDateString)", attributes: normalAttributes))
            userIDLabel.attributedText = attributedText
            if let comment = comment {
                commentLabel.attributedText = NSAttributedString(string: comment, attributes: normalAttributes)
                commentLabel.isHidden = false
            } else {
                commentLabel.text = nil
                commentLabel.isHidden = true
            }
            
            let paddingWidth = infoDescriptor.pointSize * setting.smallFontScale / 2
            boardLabel.contentInsets = UIEdgeInsets(top: 0, left: paddingWidth, bottom: 0, right: paddingWidth)
            boardLabel.clipsToBounds = true
            boardLabel.layer.cornerRadius = paddingWidth / 2
            boardLabel.textColor = UIColor.secondaryLabel
            boardLabel.font = normalInfoFont
            boardLabel.backgroundColor = UIColor.secondarySystemFill
            titleLabel.textColor = UIColor(named: "MainText")
        } else {
            titleLabel.text = nil
            boardLabel.text = nil
            userIDLabel.text = nil
            commentLabel.text = nil
        }
    }
}
