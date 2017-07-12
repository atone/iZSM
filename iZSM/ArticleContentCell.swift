//
//  ArticleContentCell.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/22.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import YYKit
import TTTAttributedLabel

class ArticleContentCell: UITableViewCell, TTTAttributedLabelDelegate {
    
    private let avatarImageView = UIImageView()
    
    private let authorLabel = UILabel()
    private let floorAndTimeLabel = UILabel()
    private let replyLabel = UILabel()
    private let moreLabel = UILabel()
    
    private let avatarTapRecognizer = UITapGestureRecognizer()
    private let authorTapRecognizer = UITapGestureRecognizer()
    private let replyTapRecognizer = UITapGestureRecognizer()
    private let moreTapRecognizer = UITapGestureRecognizer()
    
    var imageViews = [UIImageView]()
    
    private var contentLabel = TTTAttributedLabel(frame: CGRect.zero)
    
    private var delegate: ArticleContentCellDelegate?
    
    var article: SMArticle?
    private var displayFloor: Int = 0
    
    private let blankWidth: CGFloat = 4
    private let picNumPerLine: CGFloat = 3
    
    private let replyButtonWidth: CGFloat = 40
    private let moreButtonWidth: CGFloat = 36
    private let buttonHeight: CGFloat = 26
    private let avatarWidth: CGFloat = 40
    
    private let authorFontSize: CGFloat = UIScreen.isSmallScreen() ? 16 : 18
    private let floorTimeFontSize: CGFloat = UIScreen.isSmallScreen() ? 11 : 13
    private let replyMoreFontSize: CGFloat = 15
    
    private let margin1: CGFloat = 30
    private let margin2: CGFloat = 2
    private let margin3: CGFloat = 8
    
    var leftMargin: CGFloat = 0 //get from viewcontroller to prevent bug
    var rightMargin: CGFloat = 0 //get from viewcontroller to prevent bug
    
    var isVisible: Bool = false {
        didSet {
            if isVisible {
                if let imageAtt = self.article?.imageAtt {
                    drawImagesWithInfo(imageAtt: imageAtt)
                }
            } else {
                drawImagesWithInfo(imageAtt: [ImageInfo]())
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
        self.tintColor = UIApplication.shared.keyWindow?.tintColor
        self.clipsToBounds = true
        self.selectionStyle = .none
        
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = avatarWidth / 2
        avatarImageView.layer.borderWidth = 1.0 / UIScreen.scale()
        avatarImageView.layer.borderColor = UIColor.black.withAlphaComponent(0.2).cgColor
        avatarImageView.clipsToBounds = true
        avatarTapRecognizer.addTarget(self, action: #selector(showUserInfo(recognizer:)))
        avatarTapRecognizer.numberOfTapsRequired = 1
        avatarImageView.addGestureRecognizer(avatarTapRecognizer)
        avatarImageView.isUserInteractionEnabled = true
        self.contentView.addSubview(avatarImageView)
        
        authorLabel.font = UIFont.boldSystemFont(ofSize: authorFontSize)
        authorLabel.textColor = UIColor.black
        authorTapRecognizer.addTarget(self, action: #selector(showUserInfo(recognizer:)))
        authorTapRecognizer.numberOfTapsRequired = 1
        authorLabel.addGestureRecognizer(authorTapRecognizer)
        authorLabel.isUserInteractionEnabled = true
        self.contentView.addSubview(authorLabel)
        
        floorAndTimeLabel.font = UIFont.systemFont(ofSize: floorTimeFontSize)
        floorAndTimeLabel.textColor = UIColor.gray
        self.contentView.addSubview(floorAndTimeLabel)
        
        replyLabel.text = "回复"
        replyLabel.font = UIFont.systemFont(ofSize: replyMoreFontSize)
        replyLabel.textColor = tintColor
        replyLabel.textAlignment = .center
        replyLabel.layer.cornerRadius = 4
        replyLabel.layer.borderWidth = 1
        replyLabel.layer.borderColor = tintColor.cgColor
        replyLabel.clipsToBounds = true
        replyTapRecognizer.addTarget(self, action: #selector(reply(recognizer:)))
        replyTapRecognizer.numberOfTapsRequired = 1
        replyLabel.addGestureRecognizer(replyTapRecognizer)
        replyLabel.isUserInteractionEnabled = true
        self.contentView.addSubview(replyLabel)
        
        moreLabel.text = "•••"
        moreLabel.font = UIFont.systemFont(ofSize: replyMoreFontSize)
        moreLabel.textColor = tintColor
        moreLabel.textAlignment = .center
        moreLabel.layer.cornerRadius = 4
        moreLabel.layer.borderWidth = 1
        moreLabel.layer.borderColor = tintColor.cgColor
        moreLabel.clipsToBounds = true
        moreTapRecognizer.addTarget(self, action: #selector(action(recognizer:)))
        moreTapRecognizer.numberOfTapsRequired = 1
        moreLabel.addGestureRecognizer(moreTapRecognizer)
        moreLabel.isUserInteractionEnabled = true
        self.contentView.addSubview(moreLabel)
        
        contentLabel.lineBreakMode = .byWordWrapping
        contentLabel.numberOfLines = 0
        contentLabel.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue
        contentLabel.delegate = self
        contentLabel.verticalAlignment = .top
        contentLabel.extendsLinkTouchArea = false
        contentLabel.linkAttributes = [NSForegroundColorAttributeName:tintColor]
        contentLabel.activeLinkAttributes = [NSForegroundColorAttributeName:tintColor.withAlphaComponent(0.6)]
        self.contentView.addSubview(contentLabel)
    }
    
    func setData(displayFloor floor: Int, smarticle: SMArticle, delegate: ArticleContentCellDelegate) {
        self.displayFloor = floor
        self.delegate = delegate
        self.article = smarticle
        
        avatarImageView.setImageWith(SMUser.faceURL(for: smarticle.authorID, withFaceURL: nil), placeholder: #imageLiteral(resourceName: "face_default"))
        authorLabel.text = smarticle.authorID
        let floorText = displayFloor == 0 ? "楼主" : "\(displayFloor)楼"
        floorAndTimeLabel.text = "\(floorText)  \(smarticle.timeString)"
        
        contentLabel.setText(smarticle.attributedBody)
    }
    
    //MARK: - Layout Subviews
    override func layoutSubviews() {
        super.layoutSubviews()

        avatarImageView.frame = CGRect(x: leftMargin, y: margin1 - avatarWidth / 2, width: avatarWidth, height: avatarWidth)
        
        authorLabel.sizeToFit()
        authorLabel.frame = CGRect(origin: CGPoint(x: leftMargin + margin3 + avatarWidth, y: margin1 - margin2 / 2 - authorLabel.bounds.height), size: authorLabel.bounds.size)
        floorAndTimeLabel.sizeToFit()
        floorAndTimeLabel.frame = CGRect(origin: CGPoint(x: leftMargin + margin3 + avatarWidth, y: margin1 + margin2 / 2), size: floorAndTimeLabel.bounds.size)
        replyLabel.frame = CGRect(x: UIScreen.screenWidth() - rightMargin - margin3 - replyButtonWidth - moreButtonWidth, y: margin1 - buttonHeight / 2, width: replyButtonWidth, height: buttonHeight)
        moreLabel.frame = CGRect(x: UIScreen.screenWidth() - rightMargin - moreButtonWidth, y: margin1 - buttonHeight / 2, width: moreButtonWidth, height: buttonHeight)
        
        let size = contentView.bounds.size
        var imageLength: CGFloat = 0
        if imageViews.count == 1 {
            imageLength = size.width
        } else if imageViews.count > 1 {
            let oneImageLength = (size.width - (picNumPerLine - 1) * blankWidth) / picNumPerLine
            imageLength = (oneImageLength + blankWidth) * ceil(CGFloat(imageViews.count) / picNumPerLine) - blankWidth
        }
        contentLabel.frame = CGRect(x: leftMargin, y: margin1 * 2, width: UIScreen.screenWidth() - leftMargin - rightMargin, height: size.height - margin1 * 2 - margin3 - imageLength)
        
        if imageViews.count == 1 {
            imageViews.first!.frame = CGRect(x: 0, y: size.height - size.width, width: size.width, height: size.width)
        } else {
            for (index, imageView) in imageViews.enumerated() {
                let length = (size.width - (picNumPerLine - 1) * blankWidth) / picNumPerLine
                let startY = size.height - ((length + blankWidth) * ceil(CGFloat(imageViews.count) / picNumPerLine) - blankWidth)
                let offsetY = (length + blankWidth) * CGFloat(index / Int(picNumPerLine))
                let X = 0 + CGFloat(index % Int(picNumPerLine)) * (length + blankWidth)
                imageView.frame = CGRect(x: X, y: startY + offsetY, width: length, height: length)
            }
        }
    }
    
    //MARK: - Calculate Fitting Size
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let boundingSize = CGSize(width: size.width - leftMargin - rightMargin, height: size.height)
        let rect = TTTAttributedLabel.sizeThatFitsAttributedString(article!.attributedBody, withConstraints: boundingSize, limitedToNumberOfLines: 0)
        var imageLength: CGFloat = 0
        let imageCount = article?.imageAtt.count ?? 0
        if imageCount == 1 {
            imageLength = size.width
        } else if imageCount > 1 {
            let oneImageLength = (size.width - (picNumPerLine - 1) * blankWidth) / picNumPerLine
            imageLength = (oneImageLength + blankWidth) * ceil(CGFloat(imageCount) / picNumPerLine) - blankWidth
        }
        return CGSize(width: size.width, height: margin1 * 2 + ceil(rect.height) + margin3 + imageLength)
    }
    
    private func drawImagesWithInfo(imageAtt: [ImageInfo]) {
        // remove old image views
        for imageView in imageViews {
            imageView.removeFromSuperview()
        }
        imageViews.removeAll()
        // notify the delegate
        if imageAtt.count > 0 {
            delegate?.cell(self, didLoadImageInfos: imageAtt)
        }
        // add new image views
        for imageInfo in imageAtt {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.setImageWith(imageInfo.thumbnailURL, placeholder: #imageLiteral(resourceName: "loading"))
            imageView.isUserInteractionEnabled = true
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapOnImage(recognizer:)))
            singleTap.numberOfTapsRequired = 1
            imageView.addGestureRecognizer(singleTap)
            contentView.addSubview(imageView)
            imageViews.append(imageView)
        }
    }
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        delegate?.cell(self, didClick: url)
    }
    
    //MARK: - Action
    @objc private func singleTapOnImage(recognizer: UIGestureRecognizer) {
        if
            let imageView = recognizer.view as? UIImageView,
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

protocol ArticleContentCellDelegate {
    func cell(_ cell: ArticleContentCell, didClickImageAt index: Int)
    func cell(_ cell: ArticleContentCell, didClick url: URL)
    func cell(_ cell: ArticleContentCell, didClickReply sender: UIView?)
    func cell(_ cell: ArticleContentCell, didClickMore sender: UIView?)
    func cell(_ cell: ArticleContentCell, didClickUser sender: UIView?)
    func cell(_ cell: ArticleContentCell, didLoadImageInfos infos: [ImageInfo])
}
