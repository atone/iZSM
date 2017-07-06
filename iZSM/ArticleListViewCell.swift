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
    let authorLabel = UILabel()
    let timeLabel = UILabel()
    let unreadLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
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
                titleLabel.text = thread.subject + (hasAttachment ? " 📎" : "") + " (\(thread.count - 1))"
                if isAlwaysTop {
                    titleLabel.textColor = UIColor.red
                } else {
                    titleLabel.textColor = UIColor.black
                }
                authorLabel.text = thread.authorID
                timeLabel.text = thread.lastReplyTime.relativeDateString
                if thread.flags.hasPrefix("*") {
                    unreadLabel.isHidden = false
                } else {
                    unreadLabel.isHidden = true
                }
                
                updateUI()
            }
        }
    }
    
    func setupUI() {
        titleLabel.numberOfLines = 0
        unreadLabel.text = "⦁"
        unreadLabel.font = UIFont.systemFont(ofSize: 12)
        unreadLabel.textColor = UIApplication.shared.keyWindow?.tintColor
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(authorLabel)
        contentView.addSubview(unreadLabel)
        
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(contentView.snp.trailingMargin)
            make.top.equalTo(contentView.snp.topMargin)
        }

        authorLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.leading.equalTo(titleLabel.snp.leading)
            make.bottom.equalTo(contentView.snp.bottomMargin)
        }
        timeLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(authorLabel.snp.centerY)
            make.trailing.equalTo(titleLabel.snp.trailing)
        }
        unreadLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.trailing.equalTo(titleLabel.snp.leading).offset(-1)
        }
    }
    
    func updateUI() {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
        titleLabel.font = UIFont.boldSystemFont(ofSize: descriptor.pointSize)
        timeLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        authorLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        
        authorLabel.textColor = UIApplication.shared.keyWindow?.tintColor
        unreadLabel.textColor = UIApplication.shared.keyWindow?.tintColor
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
            let start = flags.index(flags.startIndex, offsetBy: 3)
            let end = flags.index(after: start)
            let flag3 = flags.substring(with: start ..< end)
            if flag3 == "@" {
                return true
            }
        }
        return false
    }

}
