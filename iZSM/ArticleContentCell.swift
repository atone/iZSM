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
    
    private var authorButton = UIButton(type: .system)
    private var floorAndTimeLabel = UILabel(frame: CGRect.zero)
    private var replyButton = UIButton(type: .system)
    private var moreButton = UIButton(type: .system)
    var imageViews = [UIImageView]()
    
    private var contentLabel = TTTAttributedLabel(frame: CGRect.zero)
    
    private var separatorView = UIView()
    
    private var delegate: ArticleContentCellDelegate?
    
    var article: SMArticle?
    private var displayFloor: Int = 0
    
    private let blankWidth: CGFloat = 4
    private let picNumPerLine: CGFloat = 3
    private let separatorHeight: CGFloat = 6
    private let contentInset: CGFloat = 8
    
    private let replyButtonWidth: CGFloat = 40
    private let moreButtonWidth: CGFloat = 36
    private let buttonHeight: CGFloat = 26
    
    private let fontSize: CGFloat = 15
    
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
        self.separatorInset = .zero
        
        authorButton.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        self.contentView.addSubview(authorButton)
        
        floorAndTimeLabel.font = UIFont.systemFont(ofSize: fontSize)
        self.contentView.addSubview(floorAndTimeLabel)
        
        replyButton.setTitle("回复", for: .normal)
        replyButton.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        replyButton.layer.cornerRadius = 4
        replyButton.layer.borderWidth = 1
        replyButton.layer.borderColor = tintColor.cgColor
        replyButton.clipsToBounds = true
        replyButton.addTarget(self, action: #selector(reply(sender:)), for: .touchUpInside)
        self.contentView.addSubview(replyButton)
        
        moreButton.setTitle("•••", for: .normal)
        moreButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: fontSize)
        moreButton.layer.cornerRadius = 4
        moreButton.layer.borderWidth = 1
        moreButton.layer.borderColor = tintColor.cgColor
        moreButton.addTarget(self, action: #selector(action(sender:)), for: .touchUpInside)
        self.contentView.addSubview(moreButton)
        
        contentLabel.lineBreakMode = .byWordWrapping
        contentLabel.numberOfLines = 0
        contentLabel.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue
        contentLabel.delegate = self
        contentLabel.verticalAlignment = .top
        contentLabel.extendsLinkTouchArea = false
        contentLabel.linkAttributes = [NSForegroundColorAttributeName:tintColor]
        contentLabel.activeLinkAttributes = [NSForegroundColorAttributeName:tintColor.withAlphaComponent(0.6)]
        self.contentView.addSubview(contentLabel)
        
        separatorView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        self.contentView.addSubview(separatorView)
    }
    
    func setData(displayFloor floor: Int, smarticle: SMArticle, delegate: ArticleContentCellDelegate) {
        self.displayFloor = floor
        self.delegate = delegate
        self.article = smarticle
        
        UIView.performWithoutAnimation {
            self.authorButton.setTitle(smarticle.authorID, for: .normal)
            self.authorButton.layoutIfNeeded()
        }
        let floorText = displayFloor == 0 ? "楼主" : "\(displayFloor)楼"
        floorAndTimeLabel.text = "\(floorText)  \(smarticle.timeString)"
        
        contentLabel.setText(smarticle.attributedBody)
        
        drawImagesWithInfo(imageAtt: smarticle.imageAtt)
    }
    
    //MARK: - Layout Subviews
    override func layoutSubviews() {
        super.layoutSubviews()
        
        authorButton.sizeToFit()
        authorButton.frame = CGRect(origin: CGPoint(x: contentInset, y: 0), size: authorButton.bounds.size)
        floorAndTimeLabel.sizeToFit()
        floorAndTimeLabel.frame = CGRect(origin: CGPoint(x: contentInset, y: buttonHeight), size: floorAndTimeLabel.bounds.size)
        replyButton.frame = CGRect(x: CGFloat(UIScreen.screenWidth()) - contentInset * 2 - replyButtonWidth - moreButtonWidth, y: buttonHeight / 2, width: replyButtonWidth, height: buttonHeight)
        moreButton.frame = CGRect(x: CGFloat(UIScreen.screenWidth()) - contentInset - moreButtonWidth, y: buttonHeight / 2, width: moreButtonWidth, height: buttonHeight)
        
        let size = contentView.bounds.size
        var imageLength: CGFloat = 0
        if imageViews.count == 1 {
            imageLength = size.width
        } else if imageViews.count > 1 {
            let oneImageLength = (size.width - (picNumPerLine - 1) * blankWidth) / picNumPerLine
            imageLength = (oneImageLength + blankWidth) * ceil(CGFloat(imageViews.count) / picNumPerLine) - blankWidth
        }
        contentLabel.frame = CGRect(x: contentInset, y: buttonHeight * 2, width: CGFloat(UIScreen.screenWidth()) - 2 * contentInset, height: size.height - buttonHeight * 2 - contentInset - imageLength - separatorHeight + 1)
        
        if imageViews.count == 1 {
            imageViews.first!.frame = CGRect(x: 0, y: size.height - separatorHeight - size.width, width: size.width, height: size.width)
        } else {
            for (index, imageView) in imageViews.enumerated() {
                let length = (size.width - (picNumPerLine - 1) * blankWidth) / picNumPerLine
                let startY = size.height - separatorHeight - ((length + blankWidth) * ceil(CGFloat(imageViews.count) / picNumPerLine) - blankWidth)
                let offsetY = (length + blankWidth) * CGFloat(index / Int(picNumPerLine))
                let X = 0 + CGFloat(index % Int(picNumPerLine)) * (length + blankWidth)
                imageView.frame = CGRect(x: X, y: startY + offsetY, width: length, height: length)
            }
        }
        separatorView.frame = CGRect(x: 0, y: size.height - separatorHeight, width: size.width, height: separatorHeight)
    }
    
    //MARK: - Calculate Fitting Size
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let boundingSize = CGSize(width: size.width - 2 * contentInset, height: size.height)
        let rect = TTTAttributedLabel.sizeThatFitsAttributedString(article!.attributedBody, withConstraints: boundingSize, limitedToNumberOfLines: 0)
        var imageLength: CGFloat = 0
        if imageViews.count == 1 {
            imageLength = size.width
        } else if imageViews.count > 1 {
            let oneImageLength = (size.width - (picNumPerLine - 1) * blankWidth) / picNumPerLine
            imageLength = (oneImageLength + blankWidth) * ceil(CGFloat(imageViews.count) / picNumPerLine) - blankWidth
        }
        return CGSize(width: size.width, height: buttonHeight * 2 + ceil(rect.height) + contentInset + imageLength + separatorHeight)
    }
    
    private func drawImagesWithInfo(imageAtt: [ImageInfo]) {
        // remove old image views
        for imageView in imageViews {
            imageView.removeFromSuperview()
        }
        imageViews.removeAll()
        
        // add new image views
        for imageInfo in imageAtt {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.imageURL = imageInfo.thumbnailURL
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
    
    @objc private func reply(sender: UIButton) {
        delegate?.cell(self, didClickReply: sender)
    }
    
    @objc private func action(sender: UIButton) {
        delegate?.cell(self, didClickMore: sender)
    }
    
}

protocol ArticleContentCellDelegate {
    func cell(_ cell: ArticleContentCell, didClickImageAt index: Int)
    func cell(_ cell: ArticleContentCell, didClick url: URL)
    func cell(_ cell: ArticleContentCell, didClickReply button: UIButton)
    func cell(_ cell: ArticleContentCell, didClickMore button: UIButton)
}
