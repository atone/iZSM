//
//  HotTableViewCell.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/7.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class HotTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var boardLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!

    var hotThread: SMHotThread? {
        didSet {
            titleLabel?.text = hotThread!.subject + " [\(hotThread!.count)]"
            boardLabel?.text = hotThread!.boardID
            authorLabel?.text = hotThread!.authorID

            boardLabel.textColor = UIApplication.sharedApplication().keyWindow?.tintColor
            authorLabel.textColor = UIApplication.sharedApplication().keyWindow?.tintColor


            let descriptor = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleSubheadline)
            titleLabel.font = UIFont.boldSystemFontOfSize(descriptor.pointSize)
            boardLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
            authorLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
        }
    }

}
