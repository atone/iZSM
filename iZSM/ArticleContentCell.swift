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
    
    private let avatarImageView = YYAnimatedImageView()
    
    private let authorLabel = UILabel()
    private let floorAndTimeLabel = UILabel()
    private let replyLabel = UILabel()
    private let moreLabel = UILabel()
    
    private let avatarTapRecognizer = UITapGestureRecognizer()
    private let authorTapRecognizer = UITapGestureRecognizer()
    private let replyTapRecognizer = UITapGestureRecognizer()
    private let moreTapRecognizer = UITapGestureRecognizer()
    
    var imageViews = [YYAnimatedImageView]()
    
    private var contentLabel = YYLabel()
    
    private var quotBars: [UIView] = []
    
    private weak var delegate: ArticleContentCellDelegate?
    private weak var controller: ArticleContentViewController?
    
    private let setting = AppSetting.shared
    
    var article: SMArticle?
    private var displayFloor: Int = 0
    
    private let blankWidth: CGFloat = 4
    private let picNumPerLine: CGFloat = 3
    
    private let replyButtonWidth: CGFloat = 40
    private let moreButtonWidth: CGFloat = 36
    private let buttonHeight: CGFloat = 26
    private let avatarWidth: CGFloat = 40
    
    private let margin1: CGFloat = 30
    private let margin2: CGFloat = 2
    private let margin3: CGFloat = 8
    
    var isDrawed: Bool = false
    var isVisible: Bool = false {
        didSet {
            if isVisible && !isDrawed {
                isDrawed = true
                drawQuotBar(with: self.article?.quotedAttributedRange)
                if !setting.noPicMode {
                    drawImagesWithInfo(imageAtt: self.article?.imageAtt)
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
        updateColor()
        self.clipsToBounds = true
        self.selectionStyle = .none
        
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = avatarWidth / 2
        avatarImageView.layer.borderWidth = 1.0 / UIScreen.main.nativeScale
        avatarImageView.layer.borderColor = UIColor.black.withAlphaComponent(0.2).cgColor
        avatarImageView.clipsToBounds = true
        avatarTapRecognizer.addTarget(self, action: #selector(showUserInfo(_:)))
        avatarTapRecognizer.numberOfTapsRequired = 1
        avatarImageView.addGestureRecognizer(avatarTapRecognizer)
        avatarImageView.isUserInteractionEnabled = true
        self.contentView.addSubview(avatarImageView)
        
        authorTapRecognizer.addTarget(self, action: #selector(showUserInfo(_:)))
        authorTapRecognizer.numberOfTapsRequired = 1
        authorLabel.addGestureRecognizer(authorTapRecognizer)
        authorLabel.isUserInteractionEnabled = true
        self.contentView.addSubview(authorLabel)
        
        self.contentView.addSubview(floorAndTimeLabel)
        
        replyLabel.text = "回复"
        replyLabel.textAlignment = .center
        replyLabel.layer.cornerRadius = 4
        replyLabel.clipsToBounds = true
        replyTapRecognizer.addTarget(self, action: #selector(reply(_:)))
        replyTapRecognizer.numberOfTapsRequired = 1
        replyLabel.addGestureRecognizer(replyTapRecognizer)
        replyLabel.isUserInteractionEnabled = true
        self.contentView.addSubview(replyLabel)
        
        moreLabel.text = "•••"
        moreLabel.textAlignment = .center
        moreLabel.layer.cornerRadius = 4
        moreLabel.clipsToBounds = true
        moreTapRecognizer.addTarget(self, action: #selector(action(_:)))
        moreTapRecognizer.numberOfTapsRequired = 1
        moreLabel.addGestureRecognizer(moreTapRecognizer)
        moreLabel.isUserInteractionEnabled = true
        self.contentView.addSubview(moreLabel)
        
        contentLabel.displaysAsynchronously = true
        contentLabel.fadeOnAsynchronouslyDisplay = false
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
        self.contentView.addSubview(contentLabel)
    }
    
    func updateColor() {
        authorLabel.textColor = UIColor(named: "MainText")
        floorAndTimeLabel.textColor = UIColor.secondaryLabel
        replyLabel.textColor = UIColor(named: "SmthColor")
        replyLabel.backgroundColor = UIColor.secondarySystemBackground
        moreLabel.textColor = UIColor(named: "SmthColor")
        moreLabel.backgroundColor = UIColor.secondarySystemBackground
        
        for quotBar in quotBars {
            quotBar.backgroundColor = UIColor.secondaryLabel.withAlphaComponent(0.5)
        }
    }
    
    func setData(displayFloor floor: Int, smarticle: SMArticle, delegate: ArticleContentCellDelegate, controller: ArticleContentViewController) {
        self.displayFloor = floor
        self.delegate = delegate
        self.article = smarticle
        self.controller = controller
        
        authorLabel.text = smarticle.authorID
        let floorText = displayFloor == 0 ? "楼主" : "\(displayFloor)楼"
        floorAndTimeLabel.text = "\(floorText)  \(smarticle.timeString)"
        
        updateColor()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        isVisible = false
        isDrawed = false
    }
    
    //MARK: - Layout Subviews
    override func layoutSubviews() {
        
        guard let controller = controller else { return }
        
        super.layoutSubviews()
        
        let leftMargin = contentView.layoutMargins.left
        let rightMargin = contentView.layoutMargins.right
        let size = contentView.bounds.size
        
        let authorFontSize: CGFloat = size.width < 350 ? 16 : 18
        let floorTimeFontSize: CGFloat = size.width < 350 ? 11 : 13
        let replyMoreFontSize: CGFloat = 15
        
        if (!setting.noPicMode) && setting.showAvatar {
            avatarImageView.isHidden = false
            avatarImageView.frame = CGRect(x: leftMargin, y: margin1 - avatarWidth / 2, width: avatarWidth, height: avatarWidth)
        } else {
            avatarImageView.isHidden = true
        }
        
        authorLabel.font = UIFont.boldSystemFont(ofSize: authorFontSize)
        authorLabel.sizeToFit()
        floorAndTimeLabel.font = UIFont.systemFont(ofSize: floorTimeFontSize)
        floorAndTimeLabel.sizeToFit()
        
        if (!setting.noPicMode) && setting.showAvatar {
            authorLabel.frame = CGRect(origin: CGPoint(x: leftMargin + margin3 + avatarWidth, y: margin1 - margin2 / 2 - authorLabel.bounds.height), size: authorLabel.bounds.size)
            floorAndTimeLabel.frame = CGRect(origin: CGPoint(x: leftMargin + margin3 + avatarWidth, y: margin1 + margin2 / 2), size: floorAndTimeLabel.bounds.size)
        } else {
            authorLabel.frame = CGRect(origin: CGPoint(x: leftMargin, y: margin1 - margin2 / 2 - authorLabel.bounds.height), size: authorLabel.bounds.size)
            floorAndTimeLabel.frame = CGRect(origin: CGPoint(x: leftMargin, y: margin1 + margin2 / 2), size: floorAndTimeLabel.bounds.size)
        }
        
        replyLabel.font = UIFont.systemFont(ofSize: replyMoreFontSize)
        replyLabel.frame = CGRect(x: size.width - rightMargin - margin3 - replyButtonWidth - moreButtonWidth, y: margin1 - buttonHeight / 2, width: replyButtonWidth, height: buttonHeight)
        moreLabel.font = UIFont.systemFont(ofSize: replyMoreFontSize)
        moreLabel.frame = CGRect(x: size.width - rightMargin - moreButtonWidth, y: margin1 - buttonHeight / 2, width: moreButtonWidth, height: buttonHeight)
        
        let boundingWidth = size.width - leftMargin - rightMargin
        let imageHeight = heightForImages(count: self.imageViews.count, boundingWidth: boundingWidth)
        
        contentLabel.frame = CGRect(x: leftMargin, y: margin1 * 2, width: boundingWidth, height: size.height - margin1 * 2 - margin3 - imageHeight)
        
        // contentLabel's layout also needs to be updated
        if let article = article {
            if let layout = controller.articleContentLayout["\(article.id)_\(Int(boundingWidth))"] {
                contentLabel.textLayout = layout
            } else {
                dPrint("ERROR: This should not happen. Calculating layout and updating cache.")
                // Calculate layout
                let attributedText: NSAttributedString = article.attributedBody
                let container = fixedLineHeightContainer(boundingSize: CGSize(width: boundingWidth, height: CGFloat.greatestFiniteMagnitude))
                let layout = YYTextLayout(container: container, text: attributedText)!
                // Store it in dictionary
                controller.articleContentLayout["\(article.id)_\(Int(boundingWidth))"] = layout
                contentLabel.textLayout = layout
            }
            
            if article.quotedAttributedRange.count == quotBars.count {
                for i in 0..<quotBars.count {
                    let quotedRange = article.quotedAttributedRange[i]
                    let rawRect = contentLabel.textLayout!.rect(for: YYTextRange(range: quotedRange))
                    let quotedRect = contentView.convert(rawRect, from: contentLabel)
                    quotBars[i].frame = CGRect(x: leftMargin, y: quotedRect.origin.y, width: 5, height: quotedRect.height)
                }
            }
        }
        
        var imageViews = self.imageViews
        var startY = size.height - imageHeight
        let headImageHeight = (boundingWidth - blankWidth) / 2
        
        switch imageViews.count % Int(picNumPerLine) {
        case 1:
            let first = imageViews.remove(at: 0)
            first.frame = CGRect(x: leftMargin, y: startY, width: boundingWidth, height: headImageHeight)
            startY += (headImageHeight + blankWidth)
        case 2:
            let first = imageViews.remove(at: 0)
            first.frame = CGRect(x: leftMargin, y: startY, width: headImageHeight, height: headImageHeight)
            let second = imageViews.remove(at: 0)
            second.frame = CGRect(x: leftMargin + headImageHeight + blankWidth, y: startY, width: headImageHeight, height: headImageHeight)
            startY += (headImageHeight + blankWidth)
        default:
            break
        }
        
        for (index, imageView) in imageViews.enumerated() {
            let length = (boundingWidth - (picNumPerLine - 1) * blankWidth) / picNumPerLine
            let offsetY = (length + blankWidth) * CGFloat(index / Int(picNumPerLine))
            let X = leftMargin + CGFloat(index % Int(picNumPerLine)) * (length + blankWidth)
            imageView.frame = CGRect(x: X, y: startY + offsetY, width: length, height: length)
        }
    }
    
    private func fixedLineHeightContainer(boundingSize: CGSize) -> YYTextContainer {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let modifier = YYTextLinePositionHorizontalFixedModifier()
        modifier.fixedLineHeight = descriptor.pointSize * 1.4
        let container = YYTextContainer()
        container.size = boundingSize
        container.linePositionModifier = modifier
        return container
    }
    
    //MARK: - Calculate Fitting Size
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        
        guard let article = self.article, let controller = self.controller else { return CGSize.zero }
        
        let leftMargin = controller.view.layoutMargins.left
        let rightMargin = controller.view.layoutMargins.right
        
        let boundingSize = CGSize(width: size.width - leftMargin - rightMargin, height: CGFloat.greatestFiniteMagnitude)
        
        let textBoundingSize: CGSize
        if let layout = controller.articleContentLayout["\(article.id)_\(Int(boundingSize.width))"] {
            // Set size with stored text layout
            textBoundingSize = layout.textBoundingSize
        } else {
            // Calculate text layout
            let container = fixedLineHeightContainer(boundingSize: boundingSize)
            let layout = YYTextLayout(container: container, text: article.attributedBody)!
            // Store in dictionary
            controller.articleContentLayout["\(article.id)_\(Int(boundingSize.width))"] = layout
            // Set size with calculated text layout
            textBoundingSize = layout.textBoundingSize
        }
        
        let imageHeight = heightForImages(count: article.imageAtt.count, boundingWidth: boundingSize.width)
        
        return CGSize(width: size.width, height: margin1 * 2 + ceil(textBoundingSize.height) + margin3 + imageHeight)
    }
    
    private func heightForImages(count: Int, boundingWidth: CGFloat) -> CGFloat {
        var totalHeight: CGFloat = 0
        if !setting.noPicMode && count > 0 {
            let oneImageHeight = (boundingWidth - (picNumPerLine - 1) * blankWidth) / picNumPerLine
            totalHeight = (oneImageHeight + blankWidth) * CGFloat(count / Int(picNumPerLine)) - blankWidth
            switch count % Int(picNumPerLine) {
            case 1, 2:
                let headImageHeight = (boundingWidth - blankWidth) / 2
                totalHeight += (headImageHeight + blankWidth)
            default:
                break
            }
        }
        return totalHeight
    }
    
    private func drawImagesWithInfo(imageAtt: [ImageInfo]?) {
        if setting.showAvatar, let article = self.article {
            avatarImageView.setImageWith(SMUser.faceURL(for: article.authorID, withFaceURL: nil),
                                         placeholder: UIImage(named: "face_default"),
                                         options: [.progressiveBlur, .setImageWithFadeAnimation])
        }
        
        // remove old image views
        for imageView in imageViews {
            imageView.removeFromSuperview()
        }
        imageViews.removeAll()

        // add new image views
        if let imageAtt = imageAtt {
            for imageInfo in imageAtt {
                let imageView = YYAnimatedImageView()
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.setImageWith(imageInfo.thumbnailURL,
                                       placeholder: UIImage(named: "loading"),
                                       options: [.progressiveBlur, .showNetworkActivity, .setImageWithFadeAnimation])
                imageView.isUserInteractionEnabled = true
                let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapOnImage(_:)))
                singleTap.numberOfTapsRequired = 1
                imageView.addGestureRecognizer(singleTap)
                contentView.addSubview(imageView)
                imageViews.append(imageView)
            }
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
                quotBar.backgroundColor = UIColor.tertiaryLabel
                contentView.addSubview(quotBar)
                quotBars.append(quotBar)
            }
        }
    }
    
    //MARK: - Action
    @objc private func singleTapOnImage(_ recognizer: UIGestureRecognizer) {
        if
            let imageView = recognizer.view as? YYAnimatedImageView,
            let index = imageViews.firstIndex(of: imageView)
        {
            delegate?.cell(self, didClickImageAt: index)
        }
    }
    
    @objc private func reply(_ recognizer: UITapGestureRecognizer) {
        delegate?.cell(self, didClickReply: recognizer.view)
    }
    
    @objc private func action(_ recognizer: UITapGestureRecognizer) {
        delegate?.cell(self, didClickMore: recognizer.view)
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
