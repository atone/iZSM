//
//  AvatarViewCell.swift
//  zsmth
//
//  Created by Naitong Yu on 15/3/27.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class AvatarViewCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView! {
        didSet {
            if let avatar = avatarImageView {
                avatar.layer.cornerRadius = avatar.frame.width / 2
                avatar.clipsToBounds = true
            }
        }
    }
    @IBOutlet weak var nickNameLabel: UILabel!

    @IBOutlet weak var userIDLabel: UILabel!
    
}
