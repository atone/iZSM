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
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.bottom.equalTo(view)
        }
        updateContent()
    }
    
    private func updateContent() {
        view.backgroundColor = UIColor.systemBackground
        if let article = article {
            let fullArticle = NSMutableAttributedString()
            
            let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2)
            let titleFont = UIFont.boldSystemFont(ofSize: descriptor.pointSize)
            let titleColor = UIColor.label
            let titleParagraphStyle = NSMutableParagraphStyle()
            titleParagraphStyle.alignment = .center
            titleParagraphStyle.lineBreakMode = .byWordWrapping
            titleParagraphStyle.lineSpacing = titleFont.pointSize / 4
            let title = NSAttributedString(string: article.subject,
                                           attributes: [NSAttributedString.Key.paragraphStyle: titleParagraphStyle,
                                                        NSAttributedString.Key.font: titleFont,
                                                        NSAttributedString.Key.foregroundColor: titleColor])
            fullArticle.append(title)
            fullArticle.appendString("\n")
            
            let subtitleText = "作者: \(article.authorID) 时间: \(article.timeString)"
            let subtitleFont = UIFont.preferredFont(forTextStyle: .subheadline)
            let subtitleColor = UIColor.secondaryLabel
            let subtitleParagraphStyle = NSMutableParagraphStyle()
            subtitleParagraphStyle.alignment = .center
            subtitleParagraphStyle.lineBreakMode = .byWordWrapping
            subtitleParagraphStyle.paragraphSpacing = titleFont.pointSize
            subtitleParagraphStyle.paragraphSpacingBefore = titleFont.pointSize / 4
            let subtitle = NSAttributedString(string: subtitleText,
                                              attributes: [NSAttributedString.Key.paragraphStyle: subtitleParagraphStyle,
                                                           NSAttributedString.Key.font: subtitleFont,
                                                           NSAttributedString.Key.foregroundColor: subtitleColor])
            fullArticle.append(subtitle)
            fullArticle.appendString("\n")
            
            let font = UIFont.preferredFont(forTextStyle: .title3)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = font.pointSize / 4
            paragraphStyle.alignment = .natural
            paragraphStyle.lineBreakMode = .byWordWrapping
            let attributedBody = attributedStringFromContent(article.body)
            let mutableAttributedBody = NSMutableAttributedString(attributedString: attributedBody)
            mutableAttributedBody.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.font: font],
                                                range: NSMakeRange(0, mutableAttributedBody.string.count))
            fullArticle.append(mutableAttributedBody)
            contentTextView.attributedText = fullArticle
        }
    }
    
    private func attributedStringFromContent(_ string: String) -> NSAttributedString {
        let attributeText = NSMutableAttributedString()
        
        let normal: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .body),
                                                    .paragraphStyle: NSParagraphStyle.default,
                                                    .foregroundColor: UIColor.label]
        let quoted: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .body),
                                                    .paragraphStyle: NSParagraphStyle.default,
                                                    .foregroundColor: UIColor.secondaryLabel]
        
        string.enumerateLines { (line, stop) -> () in
            if line.hasPrefix(":") {
                attributeText.append(NSAttributedString(string: "\(line)\n", attributes: quoted))
            } else {
                attributeText.append(NSAttributedString(string: "\(line)\n", attributes: normal))
            }
        }
        return attributeText
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
                                               name: UIContentSizeCategory.didChangeNotification,
                                               object: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapToDismiss(_:)))
        contentTextView.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentTextView.textContainerInset = UIEdgeInsets(top: 8.0, left: view.layoutMargins.left, bottom: 8.0, right: view.layoutMargins.right)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
