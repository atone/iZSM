//
//  MailListCell.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/19.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class MailListCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!

    var mail: SMMail? {
        didSet {
            if let mail = self.mail {
                titleLabel?.text = mail.subject
                authorLabel?.text = mail.authorID
                timeLabel?.text = mail.time.relativeDateString

                if mail.flags.hasPrefix("N") {
                    unreadLabel?.hidden = false
                } else {
                    unreadLabel?.hidden = true
                }

                let descriptor = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleSubheadline)
                titleLabel?.font = UIFont.boldSystemFontOfSize(descriptor.pointSize)
                timeLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
                authorLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)

                authorLabel?.textColor = UIApplication.sharedApplication().keyWindow?.tintColor
            }
        }
    }

}
