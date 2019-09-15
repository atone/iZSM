//
//  HotTableViewCell.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/21.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SnapKit

class HotTableViewCell: UITableViewCell {

    let titleLabel = UILabel()
    let boardLabel = UILabel()
    let authorLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    /// Setup constraints
    func setupUI() {
        titleLabel.numberOfLines = 0
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(boardLabel)
        contentView.addSubview(authorLabel)
        
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(contentView.snp.trailingMargin)
            make.top.equalTo(contentView.snp.topMargin)
        }
        boardLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.bottom.equalTo(contentView.snp.bottomMargin)
        }
        authorLabel.snp.makeConstraints { (make) in
            make.trailing.equalTo(titleLabel.snp.trailingMargin)
            make.bottom.equalTo(boardLabel)
            make.top.equalTo(boardLabel)
        }
    }
    
    /// Update font size and color
    func updateUI() {
        titleLabel.textColor = UIColor.label
        boardLabel.textColor = UIColor.secondaryLabel
        authorLabel.textColor = UIColor(named: "SmthColor")
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
        titleLabel.font = UIFont.boldSystemFont(ofSize: descriptor.pointSize)
        boardLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        authorLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
    }
    
    var hotThread: SMHotThread? {
        didSet {
            if let hotThread = hotThread {
                titleLabel.text = hotThread.subject + " (\(hotThread.count))"
                boardLabel.text = hotThread.boardID
                authorLabel.text = hotThread.authorID
                updateUI()
            }
        }
    }
}
