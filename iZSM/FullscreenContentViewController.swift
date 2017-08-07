//
//  FullscreenContentViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/17.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit
import SnapKit

class FullscreenContentViewController: UIViewController {
    
    var article: SMArticle?
    
    weak var previewDelegate: SmthViewControllerPreviewingDelegate?
    
    override var previewActionItems: [UIPreviewActionItem] {
        if let previewDelegate = previewDelegate {
            return previewDelegate.previewActionItems(for: self)
        } else {
            return [UIPreviewActionItem]()
        }
    }
    
    private let contentTextView = UITextView()
    
    private func setupUI() {
        view.addSubview(contentTextView)
        contentTextView.backgroundColor = UIColor.clear
        contentTextView.isEditable = false
        contentTextView.dataDetectorTypes = [.link, .phoneNumber]
        contentTextView.snp.makeConstraints { (make) in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.top.equalTo(view).offset(20)
            make.bottom.equalTo(view)
        }
        updateContent()
    }
    
    private func updateContent() {
        view.backgroundColor = AppTheme.shared.backgroundColor
        if let article = article {
            let fullArticle = NSMutableAttributedString()
            
            let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2)
            let titleFont = UIFont.boldSystemFont(ofSize: descriptor.pointSize)
            let titleColor = AppTheme.shared.textColor
            let titleParagraphStyle = NSMutableParagraphStyle()
            titleParagraphStyle.alignment = .center
            titleParagraphStyle.lineBreakMode = .byWordWrapping
            titleParagraphStyle.lineSpacing = titleFont.pointSize / 4
            let title = NSAttributedString(string: article.subject,
                                           attributes: [NSParagraphStyleAttributeName: titleParagraphStyle,
                                                        NSFontAttributeName: titleFont,
                                                        NSForegroundColorAttributeName: titleColor])
            fullArticle.append(title)
            fullArticle.appendString("\n")
            
            let subtitleText = "作者: \(article.authorID) 时间: \(article.timeString)"
            let subtitleFont = UIFont.preferredFont(forTextStyle: .subheadline)
            let subtitleColor = AppTheme.shared.lightTextColor
            let subtitleParagraphStyle = NSMutableParagraphStyle()
            subtitleParagraphStyle.alignment = .center
            subtitleParagraphStyle.lineBreakMode = .byWordWrapping
            subtitleParagraphStyle.paragraphSpacing = titleFont.pointSize
            subtitleParagraphStyle.paragraphSpacingBefore = titleFont.pointSize / 4
            let subtitle = NSAttributedString(string: subtitleText,
                                              attributes: [NSParagraphStyleAttributeName: subtitleParagraphStyle,
                                                           NSFontAttributeName: subtitleFont,
                                                           NSForegroundColorAttributeName: subtitleColor])
            fullArticle.append(subtitle)
            fullArticle.appendString("\n")
            
            let attributedBody = AppSetting.shared.nightMode ? article.attributedDarkBody : article.attributedBody
            let font = UIFont.preferredFont(forTextStyle: .title3)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = font.pointSize / 4
            paragraphStyle.alignment = .natural
            paragraphStyle.lineBreakMode = .byWordWrapping
            let mutableAttributedBody = NSMutableAttributedString(attributedString: attributedBody)
            mutableAttributedBody.addAttributes([NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: font],
                                                range: NSMakeRange(0, mutableAttributedBody.string.characters.count))
            fullArticle.append(mutableAttributedBody)
            contentTextView.attributedText = fullArticle
        }
    }
    
    @objc private func refreshContent(_ notification: Notification) {
        updateContent()
    }
    
    @objc private func tapToDismiss(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshContent(_:)),
                                               name: .UIContentSizeCategoryDidChange,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshContent(_:)),
                                               name: AppTheme.kAppThemeChangedNotification,
                                               object: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapToDismiss(_:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentTextView.textContainerInset = UIEdgeInsets(top: 8.0, left: view.layoutMargins.left, bottom: 8.0, right: view.layoutMargins.right)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
