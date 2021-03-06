//
//  ArticleListViewCell.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/22.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SmthConnection

class ArticleListViewCell: UITableViewCell {
    let setting = AppSetting.shared
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
                if thread.count <= 1 {
                    replyLabel.isHidden = true
                    replyLabel.text = nil
                } else {
                    replyLabel.isHidden = false
                    replyLabel.text = "\(thread.count - 1)"
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
        replyLabel.lineBreakMode = .byClipping
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        replyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        replyLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        let leftVerticalStack = UIStackView(arrangedSubviews: [titleLabel, infoLabel])
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
    
    func updateUI() {
        let titleDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
        let replyDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
        
        if setting.useBoldFont {
            titleLabel.font = UIFont.boldSystemFont(ofSize: titleDescriptor.pointSize * setting.smallFontScale)
        } else {
            titleLabel.font = UIFont.systemFont(ofSize: titleDescriptor.pointSize * setting.smallFontScale)
        }
        replyLabel.font = UIFont.boldSystemFont(ofSize: replyDescriptor.pointSize * setting.smallFontScale)
        
        if let thread = self.thread {
            let infoDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .footnote)
            let normalInfoFont = UIFont.systemFont(ofSize: infoDescriptor.pointSize * setting.smallFontScale)
            let boldInfoFont = UIFont.boldSystemFont(ofSize: infoDescriptor.pointSize * setting.smallFontScale)
            let normalAttributes: [NSAttributedString.Key : Any] = [.font: normalInfoFont, .foregroundColor: UIColor.secondaryLabel]
            let userIDAttributes: [NSAttributedString.Key : Any] = [.font: boldInfoFont, .foregroundColor: UIColor.secondaryLabel]
            let attributedText = NSMutableAttributedString(string: thread.authorID, attributes: userIDAttributes)
            if thread.count > 0 {
                attributedText.append(NSAttributedString(string: " • \(thread.lastReplyTime.relativeDateString)", attributes: normalAttributes))
            } else { // origin mode
                attributedText.append(NSAttributedString(string: " • \(thread.time.relativeDateString)", attributes: normalAttributes))
            }
            if thread.count > 1 {
                attributedText.append(NSAttributedString(string: " • 最后回复", attributes: normalAttributes))
                attributedText.append(NSAttributedString(string: thread.lastReplyAuthorID, attributes: userIDAttributes))
            }
            infoLabel.attributedText = attributedText
        }
        
        replyLabel.textColor = UIColor.systemBackground
        let paddingWidth = replyDescriptor.pointSize * setting.smallFontScale / 2
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
            if flags.count <= 2, flags[flags.index(after: flags.startIndex)] == "@" {
                return true
            } else if flags.count >= 4, flags[flags.index(flags.startIndex, offsetBy: 3)] == "@" {
                return true
            }
        }
        return false
    }
}
