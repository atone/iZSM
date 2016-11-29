//
//  SmthStructs.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/5.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

struct SMThread {
    var id: Int
    var time: Date
    var subject: String
    var authorID: String

    var lastReplyAuthorID: String
    var lastReplyThreadID: Int

    var boardID: String
    var boardName: String

    var flags: String
    
    var count: Int
    var lastReplyTime: Date
}

struct SMArticle {
    var id: Int
    var time: Date
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

    init(id: Int, time: Date, subject: String, authorID: String, body: String, effsize: Int, flags: String, attachments: [SMAttachment]) {
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
        let attributeText = NSMutableAttributedString()

        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let textFont = UIFont(name: "HYXinRenWenSongW", size: fontDescriptor.pointSize)!
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = .natural
        paragraphStyle.minimumLineHeight = textFont.pointSize
        paragraphStyle.maximumLineHeight = textFont.pointSize
        paragraphStyle.lineBreakMode = .byWordWrapping

        let normal : [String : Any] = [NSFontAttributeName: textFont,
            NSParagraphStyleAttributeName: paragraphStyle,
            NSForegroundColorAttributeName: UIColor.black]
        let quoted : [String : Any] = [NSFontAttributeName: textFont,
            NSParagraphStyleAttributeName: paragraphStyle,
            NSForegroundColorAttributeName: UIColor.gray]

        self.body.enumerateLines { (line, stop) -> () in
            if line.hasPrefix(": ") {
                attributeText.append(NSAttributedString(string: "\(line)\n", attributes: quoted))
            } else {
                attributeText.append(NSAttributedString(string: "\(line)\n", attributes: normal))
            }
        }

        return attributeText
    }

    private func generateImageAtt() -> [ImageInfo] {
        var imageAtt = [ImageInfo]()

        for attachment in self.attachments {
            let fileName = attachment.name.lowercased()
            if fileName.hasSuffix(".jpg") || fileName.hasSuffix(".jpeg")
                || fileName.hasSuffix(".gif") || fileName.hasSuffix(".bmp")
                || fileName.hasSuffix(".png") {
                    let baseURLString = "http://att.newsmth.net/nForum/att/\(self.boardID)/\(self.id)/\(attachment.pos)"
                    let thumbnailURL = URL(string: baseURLString + (attachments.count==1 ? "" : "/middle"))!
                    let fullImageURL = URL(string: baseURLString)!
                    let imageName = attachment.name
                    let imageSize = attachment.size
                    let imageInfo = ImageInfo(thumbnailURL: thumbnailURL, fullImageURL: fullImageURL, imageName: imageName, imageSize: imageSize)
                    imageAtt.append(imageInfo)
            }
        }
        return imageAtt
    }

    private func imageAttachmentsFromBody() -> [ImageInfo]? {
        let pattern = "(?<=\\[img=).*(?=\\]\\[/img\\])"
        let regularExpression = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let matches = regularExpression.matches(in: self.body, range: NSMakeRange(0, self.body.characters.count))
        let nsstring = self.body as NSString
        if matches.count > 0 {
            var imageInfos = [ImageInfo]()
            for match in matches {
                let range = match.range
                let urlString = nsstring.substring(with: range)
                let url = URL(string: urlString)!
                let fileName = url.lastPathComponent
                imageInfos.append(ImageInfo(thumbnailURL: url, fullImageURL: url, imageName: fileName, imageSize: 0))
            }
            return imageInfos
        } else {
            return nil
        }
    }

    private mutating func removeImageURLsFromBody() {
        let pattern = "\\[img=.*\\]\\[/img\\]"
        let regularExpression = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        self.body = regularExpression.stringByReplacingMatches(in: self.body, range: NSMakeRange(0, self.body.characters.count), withTemplate: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ImageInfo {
    var thumbnailURL: URL
    var fullImageURL: URL
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
    var time: Date
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
    var time: Date
    var userID: String
    var groupID: Int
    var position: Int
}

struct SMHotThread {
    var subject: String
    var authorID: String
    var id: Int
    var time: Date
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
    var maxTime: Date
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
    var firstLoginTime: Date
    var age: Int
    var lastLoginTime: Date
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
    var time: Date
    var title: String
    var userID: String
}

