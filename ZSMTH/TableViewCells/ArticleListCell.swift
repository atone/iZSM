//
//  ArticleListCell.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/17.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

private var formatter = NSDateFormatter()

class ArticleListCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!

    var thread: SMThread? {
        didSet {
            if let thread = self.thread {
                titleLabel?.text = thread.subject + " [\(thread.count-1)]" + (hasAttachment ? " 🔗" : "")
                if isAlwaysTop {
                    titleLabel?.textColor = UIColor.redColor()
                } else {
                    titleLabel?.textColor = UIColor.blackColor()
                }
                authorLabel?.text = thread.authorID
                timeLabel?.text = stringFromDate(thread.lastReplyTime)
                if thread.flags.hasPrefix("*") {
                    unreadLabel?.hidden = false
                } else {
                    unreadLabel?.hidden = true
                }

                let descriptor = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleSubheadline)
                titleLabel.font = UIFont.boldSystemFontOfSize(descriptor.pointSize)
                timeLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
                authorLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)

                authorLabel.textColor = UIApplication.sharedApplication().keyWindow?.tintColor
                timeLabel.textColor = UIApplication.sharedApplication().keyWindow?.tintColor
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

    private func stringFromDate(date: NSDate) -> String {
        var timeInterval = Int(date.timeIntervalSinceNow)
        if timeInterval >= 0 {
            return "现在"
        }

        timeInterval = -timeInterval
        if timeInterval < 60 {
            return "\(timeInterval)秒前"
        }
        timeInterval /= 60
        if timeInterval < 60 {
            return "\(timeInterval)分钟前"
        }
        timeInterval /= 60
        if timeInterval < 24 {
            return "\(timeInterval)小时前"
        }
        timeInterval /= 24
        if timeInterval < 7 {
            return "\(timeInterval)天前"
        }
        if timeInterval < 30 {
            return "\(timeInterval/7)周前"
        }
        if timeInterval < 365 {
            return "\(timeInterval/30)个月前"
        }
        timeInterval /= 365
        return "\(timeInterval)年前"
    }

}


