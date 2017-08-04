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
    
    var isVisible: Bool = false {
        didSet {
            if isVisible && (!setting.noPicMode) {
                drawImagesWithInfo(imageAtt: self.article?.imageAtt)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
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
        avatarTapRecognizer.addTarget(self, action: #selector(showUserInfo(recognizer:)))
        avatarTapRecognizer.numberOfTapsRequired = 1
        avatarImageView.addGestureRecognizer(avatarTapRecognizer)
        avatarImageView.isUserInteractionEnabled = true
        self.contentView.addSubview(avatarImageView)
        
        authorTapRecognizer.addTarget(self, action: #selector(showUserInfo(recognizer:)))
        authorTapRecognizer.numberOfTapsRequired = 1
        authorLabel.addGestureRecognizer(authorTapRecognizer)
        authorLabel.isUserInteractionEnabled = true
        self.contentView.addSubview(authorLabel)
        
        self.contentView.addSubview(floorAndTimeLabel)
        
        replyLabel.text = "回复"
        replyLabel.textAlignment = .center
        replyLabel.layer.cornerRadius = 4
        replyLabel.layer.borderWidth = 1
        replyLabel.clipsToBounds = true
        replyTapRecognizer.addTarget(self, action: #selector(reply(recognizer:)))
        replyTapRecognizer.numberOfTapsRequired = 1
        replyLabel.addGestureRecognizer(replyTapRecognizer)
        replyLabel.isUserInteractionEnabled = true
        self.contentView.addSubview(replyLabel)
        
        moreLabel.text = "•••"
        moreLabel.textAlignment = .center
        moreLabel.layer.cornerRadius = 4
        moreLabel.layer.borderWidth = 1
        moreLabel.clipsToBounds = true
        moreTapRecognizer.addTarget(self, action: #selector(action(recognizer:)))
        moreTapRecognizer.numberOfTapsRequired = 1
        moreLabel.addGestureRecognizer(moreTapRecognizer)
        moreLabel.isUserInteractionEnabled = true
        self.contentView.addSubview(moreLabel)
        
        contentLabel.displaysAsynchronously = true
        contentLabel.fadeOnAsynchronouslyDisplay = false
        contentLabel.ignoreCommonProperties = true
        contentLabel.highlightTapAction = { [unowned self] (containerView, text, range, rect) in
            var urlString = text.attributedSubstring(from: range).string
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
        self.backgroundColor = AppTheme.shared.backgroundColor
        authorLabel.textColor = AppTheme.shared.textColor
        floorAndTimeLabel.textColor = AppTheme.shared.lightTextColor
        replyLabel.textColor = AppTheme.shared.tintColor
        replyLabel.layer.borderColor = AppTheme.shared.tintColor.cgColor
        moreLabel.textColor = AppTheme.shared.tintColor
        moreLabel.layer.borderColor = AppTheme.shared.tintColor.cgColor
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
    
    //MARK: - Layout Subviews
    override func layoutSubviews() {
        
        guard let controller = controller else { return }
        
        super.layoutSubviews()
        
        let leftMargin = controller.view.layoutMargins.left
        let rightMargin = controller.view.layoutMargins.right
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
        let imageHeight = heightForImages(count: imageViews.count, boundingWidth: boundingWidth)
        
        contentLabel.frame = CGRect(x: leftMargin, y: margin1 * 2, width: boundingWidth, height: size.height - margin1 * 2 - margin3 - imageHeight)
        
        // contentLabel's layout also needs to be updated
        if let article = article {
            if let layout = controller.articleContentLayout["\(article.id)_\(boundingWidth)\(setting.nightMode ? "_dark" : "")"] {
                if contentLabel.textLayout != layout {
                    contentLabel.textLayout = layout
                }
            } else {
                dPrint("ERROR: This should not happen. Calculating layout and updating cache.")
                // Calculate layout
                let attributedText: NSAttributedString = setting.nightMode ? article.attributedDarkBody : article.attributedBody
                let layout = YYTextLayout(containerSize: CGSize(width: boundingWidth, height: CGFloat.greatestFiniteMagnitude), text: attributedText)
                // Store it in dictionary
                controller.articleContentLayout["\(article.id)_\(boundingWidth)\(setting.nightMode ? "_dark" : "")"] = layout
                contentLabel.textLayout = layout
            }
        }
        
        switch imageViews.count {
        case 1:
            imageViews.first!.frame = CGRect(x: leftMargin, y: size.height - boundingWidth, width: boundingWidth, height: boundingWidth)
        case 2, 4:
            for (index, imageView) in imageViews.enumerated() {
                let length = (boundingWidth - blankWidth) / 2
                let startY = size.height - ((length + blankWidth) * ceil(CGFloat(imageViews.count) / 2) - blankWidth)
                let offsetY = (length + blankWidth) * CGFloat(index / 2)
                let X = leftMargin + CGFloat(index % 2) * (length + blankWidth)
                imageView.frame = CGRect(x: X, y: startY + offsetY, width: length, height: length)
            }
        case let count where count == 3 || count > 4:
            for (index, imageView) in imageViews.enumerated() {
                let length = (boundingWidth - (picNumPerLine - 1) * blankWidth) / picNumPerLine
                let startY = size.height - ((length + blankWidth) * ceil(CGFloat(imageViews.count) / picNumPerLine) - blankWidth)
                let offsetY = (length + blankWidth) * CGFloat(index / Int(picNumPerLine))
                let X = leftMargin + CGFloat(index % Int(picNumPerLine)) * (length + blankWidth)
                imageView.frame = CGRect(x: X, y: startY + offsetY, width: length, height: length)
            }
        default:
            break
        }
    }
    
    //MARK: - Calculate Fitting Size
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        
        guard let article = self.article, let controller = self.controller else { return CGSize.zero }
        
        let leftMargin = controller.view.layoutMargins.left
        let rightMargin = controller.view.layoutMargins.right
        
        let boundingSize = CGSize(width: size.width - leftMargin - rightMargin, height: CGFloat.greatestFiniteMagnitude)
        
        let textBoundingSize: CGSize
        if let layout = controller.articleContentLayout["\(article.id)_\(boundingSize.width)"] {
            // Set size with stored text layout
            textBoundingSize = layout.textBoundingSize
        } else {
            // Calculate text layout
            let layout = YYTextLayout(containerSize: boundingSize, text: article.attributedBody)!
            let darkLayout = YYTextLayout(containerSize: boundingSize, text: article.attributedDarkBody)!
            // Store in dictionary
            controller.articleContentLayout["\(article.id)_\(boundingSize.width)"] = layout
            controller.articleContentLayout["\(article.id)_\(boundingSize.width)_dark"] = darkLayout
            // Set size with calculated text layout
            textBoundingSize = layout.textBoundingSize
        }
        
        let imageHeight = heightForImages(count: article.imageAtt.count, boundingWidth: boundingSize.width)
        
        return CGSize(width: size.width, height: margin1 * 2 + ceil(textBoundingSize.height) + margin3 + imageHeight)
    }
    
    private func heightForImages(count: Int, boundingWidth: CGFloat) -> CGFloat {
        var totalHeight: CGFloat = 0
        if !setting.noPicMode {
            switch count {
            case 1, 4:
                totalHeight = boundingWidth
            case 2:
                totalHeight = (boundingWidth - blankWidth) / 2
            case let num where num == 3 || num > 4:
                let oneImageHeight = (boundingWidth - (picNumPerLine - 1) * blankWidth) / picNumPerLine
                totalHeight = (oneImageHeight + blankWidth) * ceil(CGFloat(count) / picNumPerLine) - blankWidth
            default:
                break
            }
        }
        return totalHeight
    }
    
    private func drawImagesWithInfo(imageAtt: [ImageInfo]?) {
        if setting.showAvatar, let article = self.article {
            avatarImageView.setImageWith(SMUser.faceURL(for: article.authorID, withFaceURL: nil),
                                         placeholder: #imageLiteral(resourceName: "face_default"),
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
                                       placeholder: #imageLiteral(resourceName: "loading"),
                                       options: [.progressiveBlur, .showNetworkActivity, .setImageWithFadeAnimation])
                imageView.isUserInteractionEnabled = true
                let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapOnImage(recognizer:)))
                singleTap.numberOfTapsRequired = 1
                imageView.addGestureRecognizer(singleTap)
                contentView.addSubview(imageView)
                imageViews.append(imageView)
            }
        }
    }
    
    //MARK: - Action
    @objc private func singleTapOnImage(recognizer: UIGestureRecognizer) {
        if
            let imageView = recognizer.view as? YYAnimatedImageView,
            let index = imageViews.index(of: imageView)
        {
            delegate?.cell(self, didClickImageAt: index)
        }
    }
    
    @objc private func reply(recognizer: UITapGestureRecognizer) {
        delegate?.cell(self, didClickReply: recognizer.view)
    }
    
    @objc private func action(recognizer: UITapGestureRecognizer) {
        delegate?.cell(self, didClickMore: recognizer.view)
    }
    
    @objc private func showUserInfo(recognizer: UITapGestureRecognizer) {
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
