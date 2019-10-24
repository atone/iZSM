//
//  ArticleContentCell.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/22.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import YYKit

class ArticleContentCell: UITableViewCell {
    
    private let containerView = UIView()
    private let bckgroundView = UIView()
    
    private let avatarImageView = YYAnimatedImageView()
    
    private let authorLabel = UILabel()
    private let floorAndTimeLabel = UILabel()
    private let replyButton = UIButton(type: .system)
    private let moreButton = UIButton(type: .system)
    
    var boxImageView: BoxImageView?
    
    private var contentLabel = YYLabel()
    
    private var quotBars: [UIView] = []
    
    private weak var delegate: ArticleContentCellDelegate?
    private weak var controller: ArticleContentViewController?
    
    private let setting = AppSetting.shared
    
    var article: SMArticle?
    private var displayFloor: Int = 0
    
    private let replyButtonWidth: CGFloat = AppSetting.shared.isSmallScreen ? 36 : 40
    private let moreButtonWidth: CGFloat = AppSetting.shared.isSmallScreen ? 32 : 36
    private let buttonHeight: CGFloat = AppSetting.shared.isSmallScreen ? 24 : 26
    private let avatarHeight: CGFloat = AppSetting.shared.isSmallScreen ? 36 : 40
    
    private let authorFontSize: CGFloat = AppSetting.shared.isSmallScreen ? 16 : 18
    private let floorTimeFontSize: CGFloat = AppSetting.shared.isSmallScreen ? 11 : 13
    private let replyMoreFontSize: CGFloat = AppSetting.shared.isSmallScreen ? 13 : 15
    
    private let padding: CGFloat = AppSetting.shared.isSmallScreen ? 8 : 12
    
    var isDrawed: Bool = false
    var isVisible: Bool = false {
        didSet {
            if isVisible && !isDrawed {
                isDrawed = true
                drawQuotBar(with: self.article?.quotedRange)
                if !setting.noPicMode {
                    drawImagesWithInfo(imageAtt: self.article?.imageAttachments)
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    func setup() {
        selectionStyle = .none
        contentView.addSubview(bckgroundView)
        contentView.addSubview(containerView)
        contentView.backgroundColor = .systemBackground
        bckgroundView.backgroundColor = .secondarySystemGroupedBackground
        
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
        horizontalStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding).isActive = true
        horizontalStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -padding).isActive = true
        horizontalStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: padding).isActive = true
        horizontalStack.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -padding).isActive = true
        
        //contentLabel.displaysAsynchronously = true
        //contentLabel.fadeOnAsynchronouslyDisplay = false
        contentLabel.ignoreCommonProperties = true
        contentLabel.highlightTapAction = { [unowned self] (containerView, text, range, rect) in
            let attributes = text.attributedSubstring(from: range).attributes!
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
    
    func setData(displayFloor floor: Int, smarticle: SMArticle, delegate: ArticleContentCellDelegate, controller: ArticleContentViewController) {
        self.displayFloor = floor
        self.delegate = delegate
        self.article = smarticle
        self.controller = controller
        
        authorLabel.text = smarticle.authorID
        let floorText = displayFloor == 0 ? "楼主" : "\(displayFloor)楼"
        floorAndTimeLabel.text = "\(floorText) • \(smarticle.timeString)"
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        isVisible = false
        isDrawed = false
    }
    
    //MARK: - Layout Subviews
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let controller = controller else { return }
        
        let leftMargin = contentView.layoutMargins.left
        let rightMargin = contentView.layoutMargins.right
        let leftSafeAreaMargin = contentView.safeAreaInsets.left
        let rightSafeAreaMargin = contentView.safeAreaInsets.right
        let upDownMargin = min(leftMargin - leftSafeAreaMargin, rightMargin - rightSafeAreaMargin) * 3 / 4
        let size = contentView.bounds.size
        
        let containerWidth = size.width - leftMargin - rightMargin
        let containerHeight = size.height - 2 * upDownMargin
        let imageHeight = boxImageView != nil ? boxImageView!.imageHeight(boundingWidth: containerWidth) : 0
        
        containerView.frame = CGRect(x: leftMargin, y: upDownMargin, width: containerWidth, height: containerHeight)
        containerView.clipsToBounds = true
        containerView.layer.cornerRadius = 16
        
        bckgroundView.frame = containerView.frame
        bckgroundView.layer.cornerRadius = 16
        bckgroundView.layer.shadowColor = UIColor.black.cgColor
        bckgroundView.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        bckgroundView.layer.shadowOpacity = 0.1
        bckgroundView.layer.shadowRadius = 8.0
        
        let contentWidth = containerWidth - 2 * padding
        let contentHeight = max(0, containerHeight - avatarHeight - 3 * padding - imageHeight)
        contentLabel.frame = CGRect(x: padding, y: padding * 2 + avatarHeight, width: contentWidth, height: contentHeight)
        
        // contentLabel's layout also needs to be updated
        if let article = article {
            if let layout = controller.articleContentLayout["\(article.id)_\(Int(containerWidth))"] {
                contentLabel.textLayout = layout
            } else {
                dPrint("ERROR: This should not happen. Calculating layout and updating cache.")
                // Calculate layout
                let attributedText: NSAttributedString = article.attributedBody
                let container = fixedLineHeightContainer(boundingSize: CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude))
                if let layout = YYTextLayout(container: container, text: attributedText) {
                    // Store it in dictionary
                    controller.articleContentLayout["\(article.id)_\(Int(containerWidth))"] = layout
                    contentLabel.textLayout = layout
                } else {
                    dPrint("ERROR: Can't generate YYTextLayout!")
                }
            }
            
            if article.quotedRange.count == quotBars.count {
                for i in 0..<quotBars.count {
                    let quotedRange = article.quotedRange[i]
                    let rawRect = contentLabel.textLayout!.rect(for: YYTextRange(range: quotedRange))
                    let quotedRect = containerView.convert(rawRect, from: contentLabel)
                    quotBars[i].frame = CGRect(x: padding, y: quotedRect.origin.y, width: 5, height: quotedRect.height)
                }
            }
        }
        
        if let boxImageView = boxImageView {
            boxImageView.frame = CGRect(x: 0, y: containerHeight - imageHeight, width: containerWidth, height: imageHeight)
        }
    }
    
    private func fixedLineHeightContainer(boundingSize: CGSize) -> YYTextContainer {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let modifier = YYTextLinePositionHorizontalFixedModifier()
        modifier.fixedLineHeight = descriptor.pointSize * setting.fontScale * 1.4
        let container = YYTextContainer()
        container.size = boundingSize
        container.linePositionModifier = modifier
        return container
    }
    
    //MARK: - Calculate Fitting Size
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        
        guard let article = self.article, let controller = self.controller else { return .zero }
        
        let leftMargin = controller.view.layoutMargins.left
        let rightMargin = controller.view.layoutMargins.right
        let leftSafeAreaMargin = controller.view.safeAreaInsets.left
        let rightSafeAreaMargin = controller.view.safeAreaInsets.right
        let upDownMargin = min(leftMargin - leftSafeAreaMargin, rightMargin - rightSafeAreaMargin) * 3 / 4
        
        let containerWidth = size.width - leftMargin - rightMargin
        let contentWidth = containerWidth - 2 * padding
        guard contentWidth > 0 else { return .zero }
        
        
        let textBoundingSize: CGSize
        if let layout = controller.articleContentLayout["\(article.id)_\(Int(containerWidth))"] {
            // Set size with stored text layout
            textBoundingSize = layout.textBoundingSize
        } else {
            // Calculate text layout
            let boundingSize = CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude)
            let container = fixedLineHeightContainer(boundingSize: boundingSize)
            if let layout = YYTextLayout(container: container, text: article.attributedBody) {
                // Store in dictionary
                controller.articleContentLayout["\(article.id)_\(Int(containerWidth))"] = layout
                // Set size with calculated text layout
                textBoundingSize = layout.textBoundingSize
            } else {
                textBoundingSize = .zero
            }
        }
        
        let imageHeight = setting.noPicMode ? 0 : BoxImageView.imageHeight(count: article.imageAttachments.count, boundingWidth: containerWidth)
        
        let height: CGFloat
        if textBoundingSize.height > 0 {
            height = 2 * upDownMargin + 3 * padding + avatarHeight + textBoundingSize.height + imageHeight
        } else {
            height = 2 * upDownMargin + 2 * padding + avatarHeight + imageHeight
        }
        
        return CGSize(width: size.width, height: height)
    }
    
    private func drawImagesWithInfo(imageAtt: [ImageInfo]?) {
        if setting.showAvatar, let article = self.article {
            avatarImageView.setImageWith(SMUser.faceURL(for: article.authorID, withFaceURL: nil),
                                         placeholder: UIImage(named: "face_default"))
        }
        
        // remove old image views
        if let boxImageView = self.boxImageView {
            boxImageView.removeFromSuperview()
            self.boxImageView = nil
        }
        
        // add new image views
        if let imageAtt = imageAtt {
            let imageURLs = imageAtt.map { $0.thumbnailURL }
            let boxImageView = BoxImageView(imageURLs: imageURLs, target: self, action: #selector(singleTapOnImage(_:)))
            containerView.addSubview(boxImageView)
            self.boxImageView = boxImageView
        }
    }
    
    private func drawQuotBar(with ranges: [NSRange]?) {
        
        // remove old quot bars
        for quotBar in quotBars {
            quotBar.removeFromSuperview()
        }
        quotBars.removeAll()
        
        // add new quot bars
        if let ranges = ranges {
            for _ in ranges {
                let quotBar = UIView()
                quotBar.backgroundColor = .systemFill
                containerView.addSubview(quotBar)
                quotBars.append(quotBar)
            }
        }
    }
    
    //MARK: - Action
    @objc private func singleTapOnImage(_ recognizer: UIGestureRecognizer) {
        if
            let imageView = recognizer.view as? YYAnimatedImageView,
            let index = boxImageView?.imageViews.firstIndex(of: imageView)
        {
            delegate?.cell(self, didClickImageAt: index)
        }
    }
    
    @objc private func reply(_ button: UIButton) {
        delegate?.cell(self, didClickReply: button)
    }
    
    @objc private func action(_ button: UIButton) {
        delegate?.cell(self, didClickMore: button)
    }
    
    @objc private func showUserInfo(_ recognizer: UITapGestureRecognizer) {
        delegate?.cell(self, didClickUser: recognizer.view)
    }
    
}

protocol ArticleContentCellDelegate: class {
    func cell(_ cell: ArticleContentCell, didClickImageAt index: Int)
    func cell(_ cell: ArticleContentCell, didClick url: URL)
    func cell(_ cell: ArticleContentCell, didClickReply sender: UIView?)
    func cell(_ cell: ArticleContentCell, didClickMore sender: UIView?)
    func cell(_ cell: ArticleContentCell, didClickUser sender: UIView?)
}

class YYTextLinePositionHorizontalFixedModifier: NSObject, YYTextLinePositionModifier {
    
    var fixedLineHeight: CGFloat = 0.0
    
    func modifyLines(_ lines: [YYTextLine], fromText text: NSAttributedString, in container: YYTextContainer) {
        for line in lines {
            line.position.y = CGFloat(line.row) * fixedLineHeight + fixedLineHeight * 0.7 + container.insets.top
        }
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let one = YYTextLinePositionHorizontalFixedModifier()
        one.fixedLineHeight = self.fixedLineHeight
        return one
    }
}
