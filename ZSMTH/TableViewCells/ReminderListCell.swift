//
//  ReminderListCell.swift
//  zsmth
//
//  Created by Naitong Yu on 15/3/19.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class ReminderListCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!

    var reference: SMReference? {
        didSet {
            if let reference = self.reference {
                titleLabel?.text = "[\(reference.boardID)] \(reference.subject)"
                authorLabel?.text = reference.userID
                timeLabel?.text = reference.time.relativeDateString

                if reference.flag == 0 {
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
