//
//  MailListCell.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/23.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SnapKit

class MailListCell: UITableViewCell {
    let titleLabel = UILabel()
    let authorLabel = UILabel()
    let timeLabel = UILabel()
    let unreadLabel = UILabel()
    
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
        unreadLabel.text = "⦁"
        unreadLabel.font = UIFont.systemFont(ofSize: 12)
        updateUI()
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(authorLabel)
        contentView.addSubview(unreadLabel)
        
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.top.equalTo(contentView.snp.topMargin)
            make.trailing.equalTo(contentView.snp.trailingMargin)
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
        
        titleLabel.textColor = UIColor.label
        authorLabel.textColor = UIColor(named: "SmthColor")
        unreadLabel.textColor = UIColor(named: "SmthColor")
        timeLabel.textColor = UIColor.secondaryLabel
    }
    

    var mail: SMMail? {
        didSet {
            if let mail = self.mail {
                titleLabel.text = mail.subject
                authorLabel.text = mail.authorID
                timeLabel.text = mail.time.relativeDateString
                if mail.flags.hasPrefix("N") {
                    unreadLabel.isHidden = false
                } else {
                    unreadLabel.isHidden = true
                }
                updateUI()
            }
        }
    }
}
