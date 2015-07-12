//
//  SmthStructs.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/5.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import Foundation

struct SMThread {
    var id: Int
    var time: NSDate
    var subject: String
    var authorID: String

    var lastReplyAuthorID: String
    var lastReplyThreadID: Int

    var boardID: String
    var boardName: String

    var flags: String
    
    var count: Int
    var lastReplyTime: NSDate
}

struct SMArticle {
    var id: Int
    var time: NSDate
    var subject: String
    var authorID: String
    var body: String

    var effsize: Int //unknown use
    var flags: String
    var attachments: [SMAttachment]

    var floor: Int
    var boardID: String

    //一些用于cell显示的计算属性，但是为了加载速度，需要提前计算
    var timeString: String
    var attributedBody: NSAttributedString
    var imageAtt: [ImageInfo]

    init(id: Int, time: NSDate, subject: String, authorID: String, body: String, effsize: Int, flags: String, attachments: [SMAttachment]) {
        self.id = id
        self.time = time
        self.subject = subject
        self.authorID = authorID
        self.body = body
        self.effsize = effsize
        self.flags = flags
        self.attachments = attachments

        self.floor = 0
        self.boardID = ""
        self.timeString = time.shortDateString
        self.attributedBody = NSAttributedString()
        self.imageAtt = [ImageInfo]()
    }

    mutating func extraConfigure() {
        // configure
        if attachments.count > 0 {
            imageAtt += generateImageAtt()
        }
        if let extraInfos = imageAttachmentsFromBody() {
            imageAtt += extraInfos
            removeImageURLsFromBody()
        }
        attributedBody = generateAttributedString()
    }

    private func generateAttributedString() -> NSAttributedString {
        var attributeText = NSMutableAttributedString()

        let textFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = .Natural
        paragraphStyle.minimumLineHeight = textFont.pointSize
        paragraphStyle.maximumLineHeight = textFont.pointSize
        paragraphStyle.lineBreakMode = .ByWordWrapping

        let normal = [NSFontAttributeName: textFont,
            NSParagraphStyleAttributeName: paragraphStyle,
            NSForegroundColorAttributeName: UIColor.blackColor()]
        let quoted = [NSFontAttributeName: textFont,
            NSParagraphStyleAttributeName: paragraphStyle,
            NSForegroundColorAttributeName: UIColor.grayColor()]

        self.body.enumerateLines { (line, stop) -> () in
            if line.hasPrefix(": ") {
                attributeText.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: quoted))
            } else {
                attributeText.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: normal))
            }
        }

        return attributeText
    }

    private func generateImageAtt() -> [ImageInfo] {
        var imageAtt = [ImageInfo]()

        for attachment in self.attachments {
            let fileName = attachment.name.lowercaseString
            if fileName.hasSuffix(".jpg") || fileName.hasSuffix(".jpeg")
                || fileName.hasSuffix(".gif") || fileName.hasSuffix("bmp")
                || fileName.hasSuffix("png") {
                    let baseURLString = "http://att.newsmth.net/nForum/att/\(self.boardID)/\(self.id)/\(attachment.pos)"
                    let thumbnailURL = NSURL(string: baseURLString + (attachments.count==1 ? "" : "/middle"))!
                    let fullImageURL = NSURL(string: baseURLString)!
                    let imageName = attachment.name
                    let imageSize = attachment.size
                    var imageInfo = ImageInfo(thumbnailURL: thumbnailURL, fullImageURL: fullImageURL, imageName: imageName, imageSize: imageSize)
                    imageAtt.append(imageInfo)
            }
        }
        return imageAtt
    }

    private func imageAttachmentsFromBody() -> [ImageInfo]? {
        let pattern = "(?<=\\[img=).*(?=\\]\\[/img\\])"
        let regularExpression = NSRegularExpression(pattern: pattern, options: .CaseInsensitive, error: nil)!
        let matches = regularExpression.matchesInString(self.body, options: .allZeros, range: NSMakeRange(0, count(self.body)))
        let nsstring = self.body as NSString
        if matches.count > 0 {
            var imageInfos = [ImageInfo]()
            for match in matches as! [NSTextCheckingResult] {
                let range = match.range
                let urlString = nsstring.substringWithRange(range)
                let fileName = urlString.lastPathComponent
                let url = NSURL(string: urlString)!
                imageInfos.append(ImageInfo(thumbnailURL: url, fullImageURL: url, imageName: fileName, imageSize: 0))
            }
            return imageInfos
        } else {
            return nil
        }
    }

    private mutating func removeImageURLsFromBody() {
        let pattern = "\\[img=.*\\]\\[/img\\]"
        let regularExpression = NSRegularExpression(pattern: pattern, options: .CaseInsensitive, error: nil)!
        self.body = regularExpression.stringByReplacingMatchesInString(self.body, options: .allZeros, range: NSMakeRange(0, count(self.body)), withTemplate: "").stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
}

struct ImageInfo {
    var thumbnailURL: NSURL
    var fullImageURL: NSURL
    var imageName: String
    var imageSize: Int
}

struct SMAttachment {
    var name: String
    var pos: Int
    var size: Int
}

struct SMMailStatus {
    var isFull: Bool
    var totalCount: Int
    var newCount: Int
    var error: Int
    var errorDescription: String
}

struct SMMail {
    var subject: String
    var body: String
    var authorID: String
    var position: Int
    var time: NSDate
    var flags: String
    var attachments: [SMAttachment]
}

struct SMReferenceStatus {
    var totalCount: Int
    var newCount: Int
    var error: Int
    var errorDescription: String
}

struct SMReference {
    var subject: String
    var flag: Int
    var replyID: Int
    var mode: SmthAPI.ReferMode
    var id: Int
    var boardID: String
    var time: NSDate
    var userID: String
    var groupID: Int
    var position: Int
}

struct SMHotThread {
    var subject: String
    var authorID: String
    var id: Int
    var time: NSDate
    var boardID: String
    var count: Int

}

struct SMBoard {
    var bid: Int
    var boardID: String
    var level: Int
    var unread: Bool
    var currentUsers: Int
    var maxOnline: Int
    var scoreLevel: Int
    var section: Int
    var total: Int
    var position: Int
    var lastPost: Int
    var manager: String
    var type: String
    var flag: Int
    var maxTime: NSDate
    var name: String
    var score: Int
    var group: Int
}

struct SMSection {
    var code: String
    var description: String
    var name: String
    var id: Int
}

struct SMUser {
    var title: String
    var level: Int
    var loginCount: Int
    var firstLoginTime: NSDate
    var age: Int
    var lastLoginTime: NSDate
    var uid: Int
    var life: String
    var id: String
    var gender: Int
    var score: Int
    var posts: Int
    var faceURL: String
    var nick: String
}

struct SMMember {
    var board: SMBoard
    var boardID: String
    var flag: Int
    var score: Int
    var status: Int
    var time: NSDate
    var title: String
    var userID: String
}

