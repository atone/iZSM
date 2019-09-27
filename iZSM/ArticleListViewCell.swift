//
//  ArticleListViewCell.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/22.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SnapKit

class ArticleListViewCell: UITableViewCell {

    let titleLabel = UILabel()
    let infoLabel = UILabel()
    let replyLabel = NTLabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    var thread: SMThread? {
        didSet {
            if let thread = self.thread {
                titleLabel.text = thread.subject + (hasAttachment ? " 📎" : "")
                if isAlwaysTop {
                    titleLabel.textColor = UIColor.systemRed
                } else {
                    titleLabel.textColor = UIColor(named: "MainText")
                }
                replyLabel.text = "\(thread.count - 1)"
                if thread.count == 1 {
                    replyLabel.isHidden = true
                } else {
                    replyLabel.isHidden = false
                }
                if thread.flags.hasPrefix("*") {
                    replyLabel.backgroundColor = UIColor.systemGray
                } else {
                    replyLabel.backgroundColor = UIColor.systemGray3
                }
                
                updateUI()
            }
        }
    }
    
    func setupUI() {
        titleLabel.numberOfLines = 0
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(replyLabel)
        contentView.addSubview(infoLabel)
        
        replyLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.lessThanOrEqualTo(replyLabel.snp.leading).offset(-5)
            make.top.equalTo(contentView.snp.topMargin)
        }
        infoLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualTo(replyLabel.snp.leading).offset(-5)
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.bottom.equalTo(contentView.snp.bottomMargin)
        }
        replyLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(contentView)
            make.trailing.equalTo(contentView.snp.trailingMargin)
        }
    }
    
    func updateUI() {
        let titleDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
        let replyDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: titleDescriptor.pointSize)
        replyLabel.font = UIFont.boldSystemFont(ofSize: replyDescriptor.pointSize)
        
        if let thread = self.thread {
            let infoDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .footnote)
            let normalInfoFont = UIFont.systemFont(ofSize: infoDescriptor.pointSize)
            let boldInfoFont = UIFont.boldSystemFont(ofSize: infoDescriptor.pointSize)
            let normalAttributes: [NSAttributedString.Key : Any] = [.font: normalInfoFont, .foregroundColor: UIColor.secondaryLabel]
            let userIDAttributes: [NSAttributedString.Key : Any] = [.font: boldInfoFont, .foregroundColor: UIColor.secondaryLabel]
            let attributedText = NSMutableAttributedString(string: thread.authorID, attributes: userIDAttributes)
            attributedText.append(NSAttributedString(string: " • \(thread.lastReplyTime.relativeDateString)", attributes: normalAttributes))
            if thread.count > 1 {
                attributedText.append(NSAttributedString(string: " • 最后回复", attributes: normalAttributes))
                attributedText.append(NSAttributedString(string: thread.lastReplyAuthorID, attributes: userIDAttributes))
            }
            infoLabel.attributedText = attributedText
        }
        
        replyLabel.textColor = UIColor.systemBackground
        let paddingWidth = replyDescriptor.pointSize / 2
        replyLabel.contentInsets = UIEdgeInsets(top: 0, left: paddingWidth, bottom: 0, right: paddingWidth)
        replyLabel.clipsToBounds = true
        replyLabel.layer.cornerRadius = paddingWidth
    }
    
    private var isAlwaysTop: Bool {
        if let flags = thread?.flags {
            if flags.hasPrefix("D") || flags.hasPrefix("d") {
                return true
            }
        }
        return false
    }
    
    private var hasAttachment: Bool {
        if let flags = thread?.flags {
            if flags[flags.index(flags.startIndex, offsetBy: 3)] == "@" {
                return true
            }
        }
        return false
    }
}
