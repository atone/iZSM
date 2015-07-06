//
//  ArticleListCell.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/17.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class ArticleListCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var replyLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!

    var thread: SMThread? {
        didSet {
            if let thread = self.thread {
                titleLabel?.text = thread.subject + (hasAttachment ? " 🔗" : "")
                if isAlwaysTop {
                    titleLabel?.textColor = UIColor.redColor()
                } else {
                    titleLabel?.textColor = UIColor.blackColor()
                }
                authorLabel?.text = thread.authorID
                timeLabel?.text = thread.lastReplyTime.relativeDateString
                replyLabel?.text = "\(thread.count-1)💬"
                if thread.flags.hasPrefix("*") {
                    unreadLabel?.hidden = false
                } else {
                    unreadLabel?.hidden = true
                }

                let descriptor = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleSubheadline)
                titleLabel.font = UIFont.boldSystemFontOfSize(descriptor.pointSize)
                timeLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
                replyLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
                authorLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)

                authorLabel.textColor = UIApplication.sharedApplication().keyWindow?.tintColor
                unreadLabel.textColor = UIApplication.sharedApplication().keyWindow?.tintColor
            }
        }
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
            let start = advance(flags.startIndex, 3)
            let flag3 = flags.substringWithRange(start...start)
            if flag3 == "@" {
                return true
            }
        }
        return false
    }

}


