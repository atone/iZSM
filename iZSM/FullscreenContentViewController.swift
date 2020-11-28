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
    let setting = AppSetting.shared
    var article: Article?
    
    private let contentTextView = UITextView()
    
    private func setupUI() {
        view.addSubview(contentTextView)
        contentTextView.alwaysBounceVertical = true
        contentTextView.isEditable = false
        contentTextView.dataDetectorTypes = [.link, .phoneNumber]
        contentTextView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        updateContent()
    }
    
    private func updateContent() {
        if let article = article {
            let fullArticle = NSMutableAttributedString()
            
            let titleDescr = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
            let titleFont = UIFont.boldSystemFont(ofSize: titleDescr.pointSize * setting.largeFontScale)
            let titleColor = UIColor(named: "MainText")!
            let titleParagraphStyle = NSMutableParagraphStyle()
            titleParagraphStyle.alignment = .center
            titleParagraphStyle.lineBreakMode = .byWordWrapping
            titleParagraphStyle.lineSpacing = titleFont.pointSize / 4
            let title = NSAttributedString(string: article.subject,
                                           attributes: [.paragraphStyle: titleParagraphStyle,
                                                        .font: titleFont,
                                                        .foregroundColor: titleColor])
            fullArticle.append(title)
            fullArticle.append(NSAttributedString(string: "\n"))
            
            let subtitleText = "作者: \(article.authorID) 时间: \(article.timeString)"
            let subtitleDescr = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
            let subtitleFont = UIFont.systemFont(ofSize: subtitleDescr.pointSize * setting.largeFontScale)
            let subtitleColor = UIColor.secondaryLabel
            let subtitleParagraphStyle = NSMutableParagraphStyle()
            subtitleParagraphStyle.alignment = .center
            subtitleParagraphStyle.lineBreakMode = .byWordWrapping
            subtitleParagraphStyle.paragraphSpacing = titleFont.pointSize
            subtitleParagraphStyle.paragraphSpacingBefore = titleFont.pointSize / 4
            let subtitle = NSAttributedString(string: subtitleText,
                                              attributes: [.paragraphStyle: subtitleParagraphStyle,
                                                           .font: subtitleFont,
                                                           .foregroundColor: subtitleColor])
            fullArticle.append(subtitle)
            fullArticle.append(NSAttributedString(string: "\n"))
            
            let bodyDescr = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            let bodyFont = UIFont.systemFont(ofSize: bodyDescr.pointSize * setting.largeFontScale)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = bodyFont.pointSize / 4
            paragraphStyle.alignment = .natural
            paragraphStyle.lineBreakMode = .byWordWrapping
            let attributedBody = attributedStringFromContent(article.body)
            let mutableAttributedBody = NSMutableAttributedString(attributedString: attributedBody)
            mutableAttributedBody.addAttributes([.paragraphStyle: paragraphStyle, .font: bodyFont],
                                                range: NSMakeRange(0, mutableAttributedBody.string.count))
            fullArticle.append(mutableAttributedBody)
            contentTextView.attributedText = fullArticle
        }
    }
    
    private func attributedStringFromContent(_ string: String) -> NSAttributedString {
        let bodyDescr = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let bodyFont = UIFont.systemFont(ofSize: bodyDescr.pointSize * setting.largeFontScale)
        let attributeText = NSMutableAttributedString()
        
        let normal: [NSAttributedString.Key: Any] = [.font: bodyFont,
                                                    .paragraphStyle: NSParagraphStyle.default,
                                                    .foregroundColor: UIColor(named: "MainText")!]
        let quoted: [NSAttributedString.Key: Any] = [.font: bodyFont,
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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshContent(_:)),
                                               name: SettingsViewController.fontScaleDidChangeNotification,
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
