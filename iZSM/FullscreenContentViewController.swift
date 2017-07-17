//
//  FullscreenContentViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/17.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit
import YYKit
import SnapKit

class FullscreenContentViewController: NTViewController {
    
    var article: SMArticle?
    
    private let titleLabel = UILabel()
    private let contentTextView = YYTextView()
    
    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(contentTextView)
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .vertical)
        contentTextView.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .vertical)
        contentTextView.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .vertical)
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.textAlignment = .center
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(view.snp.leadingMargin)
            make.trailing.equalTo(view.snp.trailingMargin)
            make.top.equalTo(view.snp.top).offset(20)
        }
        contentTextView.backgroundColor = UIColor.clear
        contentTextView.isEditable = false
        contentTextView.dataDetectorTypes = .all
        contentTextView.snp.makeConstraints { (make) in
            make.leading.equalTo(view.snp.leadingMargin)
            make.trailing.equalTo(view.snp.trailingMargin)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.bottom.equalTo(view.snp.bottomMargin)
        }
        updateContent()
    }
    
    private func updateContent() {
        view.backgroundColor = AppTheme.shared.backgroundColor
        if let article = article {
            titleLabel.text = article.subject
            let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2)
            titleLabel.font = UIFont.boldSystemFont(ofSize: descriptor.pointSize)
            titleLabel.textColor = AppTheme.shared.textColor
            
            let attributedBody = AppSetting.shared.nightMode ? article.attributedDarkBody : article.attributedBody
            let mutableAttributedBody = NSMutableAttributedString(attributedString: attributedBody)
            mutableAttributedBody.setFont(UIFont.preferredFont(forTextStyle: .title3),
                                          range: NSMakeRange(0, mutableAttributedBody.string.characters.count))
            contentTextView.attributedText = mutableAttributedBody
        }
    }
    
    func refreshContent(notification: Notification) {
        updateContent()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshContent(notification:)),
                                               name: .UIContentSizeCategoryDidChange,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshContent(notification:)),
                                               name: AppTheme.kAppThemeChangedNotification,
                                               object: nil)
        let tapGesture = UITapGestureRecognizer { [unowned self] (_) in
            self.dismiss(animated: true, completion: nil)
        }
        view.addGestureRecognizer(tapGesture)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
