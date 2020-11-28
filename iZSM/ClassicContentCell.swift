//
//  ClassicContentCell.swift
//  iZSM
//
//  Created by Naitong Yu on 2019/11/06.
//  Copyright © 2019 Naitong Yu. All rights reserved.
//

import UIKit
import YYText

class ClassicContentCell: ArticleContentCell {
    override func setup() {
        contentView.addSubview(containerView)
        
        if (!setting.noPicMode) && setting.showAvatar {
            avatarImageView.contentMode = .scaleAspectFill
            avatarImageView.layer.cornerRadius = avatarHeight / 2
            avatarImageView.layer.borderWidth = 1.0 / UIScreen.main.nativeScale
            avatarImageView.layer.borderColor = UIColor.black.withAlphaComponent(0.2).cgColor
            avatarImageView.clipsToBounds = true
            avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showUserInfo(_:))))
            avatarImageView.isUserInteractionEnabled = true
            avatarImageView.translatesAutoresizingMaskIntoConstraints = false
            avatarImageView.widthAnchor.constraint(equalToConstant: avatarHeight).isActive = true
            avatarImageView.heightAnchor.constraint(equalToConstant: avatarHeight).isActive = true
        } else {
            avatarImageView.isHidden = true
        }
        
        authorLabel.textColor = UIColor(named: "MainText")
        authorLabel.font = .boldSystemFont(ofSize: authorFontSize)
        authorLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showUserInfo(_:))))
        authorLabel.isUserInteractionEnabled = true
        authorLabel.translatesAutoresizingMaskIntoConstraints = false
        floorAndTimeLabel.textColor = UIColor.secondaryLabel
        floorAndTimeLabel.font = .systemFont(ofSize: floorTimeFontSize)
        floorAndTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        replyButton.setTitle("回复", for: .normal)
        replyButton.titleLabel?.font = .systemFont(ofSize: replyMoreFontSize)
        replyButton.backgroundColor = .quaternarySystemFill
        replyButton.layer.cornerRadius = 4
        replyButton.clipsToBounds = true
        replyButton.addTarget(self, action: #selector(reply(_:)), for: .touchUpInside)
        replyButton.translatesAutoresizingMaskIntoConstraints = false
        replyButton.widthAnchor.constraint(equalToConstant: replyButtonWidth).isActive = true
        replyButton.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        
        moreButton.setTitle("•••", for: .normal)
        moreButton.titleLabel?.font = .systemFont(ofSize: replyMoreFontSize)
        moreButton.backgroundColor = .quaternarySystemFill
        moreButton.layer.cornerRadius = 4
        moreButton.clipsToBounds = true
        moreButton.addTarget(self, action: #selector(action(_:)), for: .touchUpInside)
        moreButton.translatesAutoresizingMaskIntoConstraints = false
        moreButton.widthAnchor.constraint(equalToConstant: moreButtonWidth).isActive = true
        moreButton.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        
        let verticalStack = UIStackView(arrangedSubviews: [authorLabel, floorAndTimeLabel])
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        verticalStack.axis = .vertical
        verticalStack.alignment = .leading
        
        let rightStack = UIStackView(arrangedSubviews: [replyButton, moreButton])
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        rightStack.axis = .horizontal
        rightStack.alignment = .center
        rightStack.spacing = padding
        
        let horizontalStack = UIStackView()
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .center
        horizontalStack.distribution = .equalSpacing
        
        if (!setting.noPicMode) && setting.showAvatar {
            let leftStack = UIStackView(arrangedSubviews: [avatarImageView, verticalStack])
            leftStack.translatesAutoresizingMaskIntoConstraints = false
            leftStack.axis = .horizontal
            leftStack.alignment = .center
            leftStack.spacing = padding
            
            horizontalStack.addArrangedSubview(leftStack)
        } else {
            horizontalStack.addArrangedSubview(verticalStack)
        }
        horizontalStack.addArrangedSubview(rightStack)
        
        containerView.addSubview(horizontalStack)
        horizontalStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        horizontalStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        horizontalStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: padding).isActive = true
        horizontalStack.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -padding).isActive = true
        
        contentLabel.displaysAsynchronously = true
        contentLabel.fadeOnAsynchronouslyDisplay = false
        contentLabel.clearContentsBeforeAsynchronouslyDisplay = false
        contentLabel.ignoreCommonProperties = true
        contentLabel.highlightTapAction = { [unowned self] (containerView, text, range, rect) in
            let attributes = text.attributedSubstring(from: range).yy_attributes!
            var urlString = attributes[NSAttributedString.Key.link.rawValue] as! String
            if !urlString.contains(":") {
                if urlString.contains("@") {
                    urlString = "mailto:\(urlString.lowercased())"
                } else {
                    urlString = "http://\(urlString.lowercased())"
                }
            }
            if let url = URL(string: urlString) {
                self.delegate?.cell(self, didClick: url)
            } else {
                dPrint("ERROR: \(urlString) can't be recognized as URL")
            }
        }
        containerView.addSubview(contentLabel)
    }
    
    //MARK: - Layout Subviews
    override func layoutSubviews() {
        superLayoutSubviews()
        
        guard let controller = controller else { return }
        
        let leftMargin = contentView.layoutMargins.left
        let rightMargin = contentView.layoutMargins.right
        let size = contentView.bounds.size
        
        let containerWidth = size.width - leftMargin - rightMargin
        let containerHeight = size.height - 1.0 / UIScreen.main.scale
        let imageHeight = boxImageView != nil ? boxImageView!.imageHeight(boundingWidth: containerWidth) : 0
        
        containerView.frame = CGRect(x: leftMargin, y: 0, width: containerWidth, height: containerHeight)
        
        let contentHeight = max(0, containerHeight - avatarHeight - 3 * padding - imageHeight)
        contentLabel.frame = CGRect(x: 0, y: padding * 2 + avatarHeight, width: containerWidth, height: contentHeight)
        
        // contentLabel's layout also needs to be updated
        if let article = article {
            var layoutKey = "\(article.id)_\(Int(containerWidth))"
            if controller.traitCollection.userInterfaceStyle == .dark {
                layoutKey.append("_dark")
            }
            if let layout = controller.articleContentLayout[layoutKey] {
                contentLabel.textLayout = layout
            }
            
            if article.quotedRange.count == quotBars.count {
                for i in 0..<quotBars.count {
                    let quotedRange = article.quotedRange[i]
                    let rawRect = contentLabel.textLayout!.rect(for: YYTextRange(range: quotedRange))
                    let quotedRect = containerView.convert(rawRect, from: contentLabel)
                    quotBars[i].frame = CGRect(x: 0, y: quotedRect.origin.y, width: 5, height: quotedRect.height)
                }
            }
        }
        
        if let boxImageView = boxImageView {
            boxImageView.frame = CGRect(x: 0, y: containerHeight - imageHeight, width: containerWidth, height: imageHeight)
        }
    }
    
    //MARK: - Calculate Fitting Size
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        
        guard let article = self.article, let controller = self.controller else { return .zero }
        
        let leftMargin = controller.view.layoutMargins.left
        let rightMargin = controller.view.layoutMargins.right
        
        let containerWidth = size.width - leftMargin - rightMargin
        guard containerWidth > 0 else { return .zero }
        
        let textBoundingSize: CGSize
        if let layout = controller.articleContentLayout["\(article.id)_\(Int(containerWidth))"] {
            // Set size with stored text layout
            textBoundingSize = layout.textBoundingSize
        } else {
            // Calculate text layout
            let boundingSize = CGSize(width: containerWidth, height: CGFloat.greatestFiniteMagnitude)
            let container = fixedLineHeightContainer(boundingSize: boundingSize)
            if let layout = YYTextLayout(container: container, text: article.attributedBody),
                let darkLayout = YYTextLayout(container: container, text: article.attributedDarkBody) {
                // Store in dictionary
                controller.articleContentLayout["\(article.id)_\(Int(containerWidth))"] = layout
                controller.articleContentLayout["\(article.id)_\(Int(containerWidth))_dark"] = darkLayout
                // Set size with calculated text layout
                textBoundingSize = layout.textBoundingSize
            } else {
                textBoundingSize = .zero
            }
        }
        
        let imageHeight = setting.noPicMode ? 0 : BoxImageView.imageHeight(count: article.imageAttachments.count, boundingWidth: containerWidth)
        
        let height: CGFloat
        if textBoundingSize.height > 0 {
            height = 3 * padding + avatarHeight + textBoundingSize.height + imageHeight
        } else {
            height = 2 * padding + avatarHeight + imageHeight
        }
        
        return CGSize(width: size.width, height: height)
    }
}
