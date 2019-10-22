//
//  SmthStructs.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/5.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit
import YYKit

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

    var imageAtt: [ImageInfo]
    var timeString: String
    var attributedBody: NSAttributedString
    var quotedAttributedRange: [NSRange]
    
    var replySubject: String {
        if subject.lowercased().hasPrefix("re:") {
            return subject
        } else {
            return "Re: " + subject
        }
    }
    
    var quotBody: String {
        let lines = body.components(separatedBy: .newlines).map {
            $0.trimmingCharacters(in: .whitespaces)
        }.filter {
            $0.range(of: "- 来自「最水木 for .*」", options: .regularExpression) == nil
        }
        var tmpBody = "\n【 在 \(authorID) 的大作中提到: 】\n"
        for idx in 0..<min(lines.count, 3) {
            tmpBody.append(": \(lines[idx])\n")
        }
        if lines.count > 3 {
            tmpBody.append(": ....................\n")
        }
        return tmpBody
    }
    
    var filterSignatureBody: String {
        return body.components(separatedBy: .newlines).map {
            $0.trimmingCharacters(in: .whitespaces)
        }.filter {
            $0.range(of: "- 来自「最水木 for .*」", options: .regularExpression) == nil
        }.joined(separator: "\n")
    }

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
        self.imageAtt = [ImageInfo]()
        self.timeString = time.shortDateString
        self.attributedBody = NSAttributedString()
        self.quotedAttributedRange = []
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
        self.attributedBody = makeAttributedBody()
    }

    private mutating func makeAttributedBody() -> NSAttributedString {
        let attributeText = NSMutableAttributedString()
        
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let textFont = UIFont.systemFont(ofSize: fontDescriptor.pointSize * AppSetting.shared.fontScale)
        let boldTextFont = UIFont.boldSystemFont(ofSize: fontDescriptor.pointSize * AppSetting.shared.fontScale)
        let paragraphStyle = NSParagraphStyle.default
        
        let quotedParagraphStyle = NSMutableParagraphStyle()
        quotedParagraphStyle.setParagraphStyle(paragraphStyle)
        quotedParagraphStyle.firstLineHeadIndent = 12
        quotedParagraphStyle.headIndent = 12
        
        let normal : [NSAttributedString.Key : Any] = [.font: textFont,
                                                       .paragraphStyle: paragraphStyle,
                                                       .foregroundColor: UIColor(named: "MainText")!]
        let quoted : [NSAttributedString.Key : Any] = [.font: textFont,
                                                       .paragraphStyle: quotedParagraphStyle,
                                                       .foregroundColor: UIColor.secondaryLabel]
        let quotedTitle : [NSAttributedString.Key : Any] = [.font: boldTextFont,
                                                            .paragraphStyle: quotedParagraphStyle,
                                                            .foregroundColor: UIColor.secondaryLabel]
        
        let regex = try! NSRegularExpression(pattern: "在.*的(?:大作|邮件)中提到")
        
        self.body.enumerateLines { (line, stop) -> () in
            if line.hasPrefix(":") {
                let line = line.dropFirst().trimmingCharacters(in: .whitespaces)
                attributeText.append(NSAttributedString(string: "\(line)\n", attributes: quoted))
            } else if regex.numberOfMatches(in: line, range: NSMakeRange(0, line.count)) > 0 {
                var line = line.trimmingCharacters(in: .whitespaces)
                if line.first != "【" {
                    if let idx = line.firstIndex(of: "【") {
                        let text = line[..<idx].trimmingCharacters(in: .whitespaces)
                        attributeText.append(NSAttributedString(string: "\(text)\n", attributes: normal))
                        line = line[idx...].trimmingCharacters(in: .whitespaces)
                    }
                }
                if line.first == "【" && line.last == "】" {
                    line = line.dropFirst().dropLast().trimmingCharacters(in: .whitespaces)
                    attributeText.append(NSAttributedString(string: "\(line)\n", attributes: quotedTitle))
                } else {
                    attributeText.append(NSAttributedString(string: "\(line)\n", attributes: normal))
                }
            } else {
                attributeText.append(NSAttributedString(string: "\(line)\n", attributes: normal))
            }
        }
        
        let bgColor = UIColor.secondarySystemBackground
        let urlColor = UIColor(red: 0/255.0, green: 139/255.0, blue: 203/255.0, alpha: 1)
        let border = YYTextBorder(fill: bgColor, cornerRadius: 3)
        let highlight = YYTextHighlight()
        highlight.setColor(urlColor)
        highlight.setBackgroundBorder(border)
        
        let re = try! NSRegularExpression(pattern: "\\[url=(.*)\\](.*)\\[/url\\]", options: .caseInsensitive)
        let reMatches = re.matches(in: attributeText.string, range: NSMakeRange(0, attributeText.length))
        for match in reMatches.reversed() {
            let url = attributeText.attributedSubstring(from: match.range(at: 1))
            let content = attributeText.attributedSubstring(from: match.range(at: 2))
            let contentLength = content.string.trimmingCharacters(in: .whitespaces).count
            let mutable = NSMutableAttributedString(attributedString: contentLength > 0 ? content : url)
            mutable.setLink(url.string, range: NSMakeRange(0, mutable.length))
            mutable.setTextHighlight(highlight, range: NSMakeRange(0, mutable.length))
            mutable.setColor(urlColor, range: NSMakeRange(0, mutable.length))
            attributeText.replaceCharacters(in: match.range, with: mutable)
        }
        
        let types: NSTextCheckingResult.CheckingType = .link
        let detector = try! NSDataDetector(types: types.rawValue)
        let matches = detector.matches(in: attributeText.string, range: NSMakeRange(0, attributeText.length))
        for match in matches {
            attributeText.setTextHighlight(highlight, range: match.range)
            attributeText.setColor(urlColor, range: match.range)
            attributeText.setLink(attributeText.attributedSubstring(from: match.range).string, range: match.range)
        }
        
        for attachment in self.attachments {
            let fileName = attachment.name.lowercased()
            if !isPicture(fileName) {
                let urlString = "https://att.newsmth.net/nForum/att/\(self.boardID)/\(self.id)/\(attachment.pos)"
                let mutable = NSMutableAttributedString(string: fileName)
                mutable.setLink(urlString, range: NSMakeRange(0, mutable.length))
                mutable.setTextHighlight(highlight, range: NSMakeRange(0, mutable.length))
                mutable.setColor(urlColor, range: NSMakeRange(0, mutable.length))
                mutable.setFont(textFont, range: NSMakeRange(0, mutable.length))
                mutable.setParagraphStyle(paragraphStyle, range: NSMakeRange(0, mutable.length))
                attributeText.appendString("\n")
                attributeText.append(mutable)
            }
        }
        
        let emoticonParser = SMEmoticon.shared.parser
        emoticonParser.parseText(attributeText, selectedRange: nil)
        
        self.quotedAttributedRange.removeAll()
        attributeText.enumerateAttribute(.paragraphStyle, in: NSMakeRange(0, attributeText.length)) { (value, range, stop) in
            if let value = value as? NSMutableParagraphStyle, value == quotedParagraphStyle {
                var trimRange = range
                while trimRange.length > 0
                    && attributeText.attributedSubstring(from: NSMakeRange(trimRange.location + trimRange.length - 1, 1)).string == "\n" {
                    trimRange.length -= 1
                }
                self.quotedAttributedRange.append(trimRange)
            }
        }
        attributeText.trimCharactersInSet(charSet: .whitespacesAndNewlines)
        return attributeText
    }
    
    func attachmentURL(at pos: Int) -> URL {
        let string = "https://att.newsmth.net/nForum/att/\(self.boardID)/\(self.id)/\(pos)"
        return URL(string: string)!
    }

    private func generateImageAtt() -> [ImageInfo] {
        var imageAtt = [ImageInfo]()

        for attachment in self.attachments {
            let fileName = attachment.name.lowercased()
            if isPicture(fileName)  {
                let thumbnailURL = attachmentURL(at: attachment.pos)
                let fullImageURL = attachmentURL(at: attachment.pos)
                let imageName = attachment.name
                let imageSize = attachment.size
                let imageInfo = ImageInfo(thumbnailURL: thumbnailURL, fullImageURL: fullImageURL, imageName: imageName, imageSize: imageSize)
                imageAtt.append(imageInfo)
            }
        }
        return imageAtt
    }
    
    private func isPicture(_ fileName: String) -> Bool {
        return fileName.hasSuffix(".jpg") || fileName.hasSuffix(".jpeg")
            || fileName.hasSuffix(".gif") || fileName.hasSuffix(".bmp")
            || fileName.hasSuffix(".png")
    }

    private func imageAttachmentsFromBody() -> [ImageInfo]? {
        let pattern = "(?<=\\[img=).*(?=\\])"
        let re = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let matches = re.matches(in: self.body, range: NSMakeRange(0, self.body.count))
        let nsbody = self.body as NSString
        var imageInfos = [ImageInfo]()
        for match in matches {
            let range = match.range
            let urlString = nsbody.substring(with: range).trimmingCharacters(in: .whitespaces)
            if let url = URL(string: urlString) {
                let fileName = url.lastPathComponent
                imageInfos.append(ImageInfo(thumbnailURL: url, fullImageURL: url, imageName: fileName, imageSize: 0))
            }
        }
        if imageInfos.count > 0 {
            return imageInfos
        }
        return nil
    }

    private mutating func removeImageURLsFromBody() {
        let pattern = "\\[img=.*\\](\\[/img\\])?"
        let re = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        self.body = re.stringByReplacingMatches(in: self.body, range: NSMakeRange(0, self.body.count), withTemplate: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct SMEmoticon {
    
    static let shared = SMEmoticon()
    
    public let parser: YYTextSimpleEmoticonParser
    
    private init() {
        
        parser = YYTextSimpleEmoticonParser()
        
        var mapper = [String: UIImage]()
        
        for i in 1...73 {
            let name = "em\(i)"
            mapper["[\(name)]"] = YYImage(named: "\(name).gif")
        }
        
        for i in 0...41 {
            let name = "ema\(i)"
            mapper["[\(name)]"] = YYImage(named: "\(name).gif")
        }
        
        for i in 0...24 {
            let name = "emb\(i)"
            mapper["[\(name)]"] = YYImage(named: "\(name).gif")
        }
        
        for i in 0...58 {
            let name = "emc\(i)"
            mapper["[\(name)]"] = YYImage(named: "\(name).gif")
        }
        
        parser.emoticonMapper = mapper
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
    
    var replySubject: String {
        if subject.lowercased().hasPrefix("re:") {
            return subject
        } else {
            return "Re: " + subject
        }
    }
    
    var quotBody: String {
        let lines = body.components(separatedBy: .newlines).map {
            $0.trimmingCharacters(in: .whitespaces)
        }.filter {
            $0.range(of: "- 来自「最水木 for .*」", options: .regularExpression) == nil
        }
        var tmpBody = "\n【 在 \(authorID) 的来信中提到: 】\n"
        for idx in 0..<min(lines.count, 3) {
            tmpBody.append(": \(lines[idx])\n")
        }
        if lines.count > 3 {
            tmpBody.append(": ....................\n")
        }
        return tmpBody
    }
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
    
    static func faceURL(for userID: String, withFaceURL faceURL: String?) -> URL {
        let prefix = String(userID[userID.startIndex]).uppercased()
        var faceString: String
        if let faceURL = faceURL, faceURL.count > 0 {
            faceString = faceURL
        } else if userID.contains(".") {
            faceString = userID
        } else {
            faceString = "\(userID).jpg"
        }
        faceString = faceString.addingPercentEncoding(withAllowedCharacters: .smURLQueryAllowed)!
        return URL(string: "https://images.newsmth.net/nForum/uploadFace/\(prefix)/\(faceString)")!
    }
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

extension NSMutableAttributedString {
     public func trimCharactersInSet(charSet: CharacterSet) {
        var range = (string as NSString).rangeOfCharacter(from: charSet)

         // Trim leading characters from character set.
         while range.length != 0 && range.location == 0 {
            replaceCharacters(in: range, with: "")
            range = (string as NSString).rangeOfCharacter(from: charSet)
         }
        // Trim trailing characters from character set.
        range = (string as NSString).rangeOfCharacter(from: charSet, options: .backwards)
        while range.length != 0 && NSMaxRange(range) == length {
            replaceCharacters(in: range, with: "")
            range = (string as NSString).rangeOfCharacter(from: charSet, options: .backwards)
        }
    }
}
