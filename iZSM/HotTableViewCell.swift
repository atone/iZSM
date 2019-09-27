//
//  HotTableViewCell.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/21.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SnapKit

class HotTableViewCell: UITableViewCell {
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
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(boardLabel)
        contentView.addSubview(userIDLabel)
        contentView.addSubview(replyLabel)
        
        replyLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.lessThanOrEqualTo(replyLabel.snp.leading).offset(-5)
            make.top.equalTo(contentView.snp.topMargin)
        }
        boardLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.bottom.equalTo(contentView.snp.bottomMargin)
        }
        userIDLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(boardLabel.snp.trailing)
            make.lastBaseline.equalTo(boardLabel)
            make.trailing.lessThanOrEqualTo(replyLabel.snp.leading).offset(-5)
        }
        replyLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(contentView)
            make.trailing.equalTo(contentView.snp.trailingMargin)
        }
    }
    
    /// Update font size and color
    func updateUI() {
        let titleDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
        let replyDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: titleDescriptor.pointSize)
        replyLabel.font = UIFont.boldSystemFont(ofSize: replyDescriptor.pointSize)
        
        if let thread = hotThread {
            let infoDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .footnote)
            let normalInfoFont = UIFont.systemFont(ofSize: infoDescriptor.pointSize)
            let boldInfoFont = UIFont.boldSystemFont(ofSize: infoDescriptor.pointSize)
            let normalAttributes: [NSAttributedString.Key : Any] = [.font: normalInfoFont, .foregroundColor: UIColor.secondaryLabel]
            let userIDAttributes: [NSAttributedString.Key : Any] = [.font: boldInfoFont, .foregroundColor: UIColor.secondaryLabel]
            let attributedText = NSMutableAttributedString(string: " • ", attributes: normalAttributes)
            attributedText.append(NSAttributedString(string: thread.authorID, attributes: userIDAttributes))
            userIDLabel.attributedText = attributedText
            
            let paddingWidth = infoDescriptor.pointSize / 2
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
        let paddingWidth = replyDescriptor.pointSize / 2
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
