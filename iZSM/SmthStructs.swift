//
//  SmthStructs.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/5.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit
import YYKit
import SVProgressHUD
import SmthConnection

struct Article: Cleanable, Replyable {
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

    var imageAttachments: [ImageInfo]
    var attributedBody: NSAttributedString
    var attributedDarkBody: NSAttributedString
    var quotedRange: [NSRange]
    
    var timeString: String {
        return time.shortDateString
    }
    
    init(from article: SMArticle, floor: Int, boardID: String) {
        self.id = article.id
        self.time = article.time
        self.subject = article.subject
        self.authorID = article.authorID
        self.body = article.body
        self.effsize = article.effsize
        self.flags = article.flags
        self.attachments = article.attachments
        self.floor = floor
        self.boardID = boardID
        
        self.imageAttachments = []
        self.quotedRange = []
        self.attributedBody = NSAttributedString()
        self.attributedDarkBody = NSAttributedString()
        // make body clean
        self.body = clean(self.body)
        
        if attachments.count > 0 {
            imageAttachments += generateImageAtt()
        }
        if let extraInfos = imageAttachmentsFromBody() {
            imageAttachments += extraInfos
        }
        removeImageURLsFromBody()
        makeAttributedBody()
    }

    private mutating func makeAttributedBody() {
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
                                                       .foregroundColor: UIColor(named: "MainTextLight")!]
        let quoted : [NSAttributedString.Key : Any] = [.font: textFont,
                                                       .paragraphStyle: quotedParagraphStyle,
                                                       .foregroundColor: UIColor(named: "QuotTextLight")!]
        let quotedTitle : [NSAttributedString.Key : Any] = [.font: boldTextFont,
                                                            .paragraphStyle: quotedParagraphStyle,
                                                            .foregroundColor: UIColor(named: "QuotTextLight")!]
        
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
        
        let urlColor = UIColor(named: "URLColor")!
        let highlight = YYTextHighlight()
        highlight.setColor(urlColor)
        
        let re = try! NSRegularExpression(pattern: "\\[url=(.*?)\\](.*?)\\[/url\\]", options: .caseInsensitive)
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
                let urlString = AppSetting.shared.httpPrefix + "static.mysmth.net/nForum/att/\(self.boardID)/\(self.id)/\(attachment.pos)"
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
        
        let emoticonParser = Emoticon.shared.parser
        emoticonParser.parseText(attributeText, selectedRange: nil)
        
        self.quotedRange.removeAll()
        attributeText.enumerateAttribute(.paragraphStyle, in: NSMakeRange(0, attributeText.length)) { (value, range, stop) in
            if let value = value as? NSMutableParagraphStyle, value == quotedParagraphStyle {
                var trimRange = range
                while trimRange.length > 0 && attributeText.attributedSubstring(from: trimRange).string.last == "\n" {
                    trimRange.length -= 1
                }
                self.quotedRange.append(trimRange)
            }
        }
        attributeText.trimCharactersInSet(charSet: .whitespacesAndNewlines)
        self.attributedBody = attributeText
        let attributeDarkText = NSMutableAttributedString(attributedString: attributeText)
        attributeDarkText.enumerateAttribute(.foregroundColor, in: NSMakeRange(0, attributeDarkText.length)) { (value, range, stop) in
            if let foregroundColor = value as? UIColor {
                if foregroundColor.isEqual(UIColor(named: "MainTextLight")) {
                    attributeDarkText.addAttribute(.foregroundColor, value: UIColor(named: "MainTextDark")!, range: range)
                } else if foregroundColor.isEqual(UIColor(named: "QuotTextLight")) {
                    attributeDarkText.addAttribute(.foregroundColor, value: UIColor(named: "QuotTextDark")!, range: range)
                }
            }
        }
        self.attributedDarkBody = attributeDarkText
    }
    
    private func attachmentURL(at pos: Int) -> URL {
        let string = AppSetting.shared.httpPrefix + "static.mysmth.net/nForum/att/\(self.boardID)/\(self.id)/\(pos)"
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
        let pattern = "(?<=\\[img=).*?(?=\\])"
        let re = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        var imageInfos = [ImageInfo]()
        self.body.enumerateLines { (line, stop) in
            if line.hasPrefix(":") { return }
            let matches = re.matches(in: line, range: NSMakeRange(0, line.count))
            for match in matches {
                let range = match.range
                let urlString = (line as NSString).substring(with: range).trimmingCharacters(in: .whitespaces)
                if let url = URL(string: urlString) {
                    let fileName = url.lastPathComponent
                    imageInfos.append(ImageInfo(thumbnailURL: url, fullImageURL: url, imageName: fileName, imageSize: 0))
                }
            }
        }
        if imageInfos.count > 0 {
            return imageInfos
        }
        return nil
    }

    private mutating func removeImageURLsFromBody() {
        let pattern = "\\[img=.*?\\](\\[/img\\])?"
        let re = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        self.body = re.stringByReplacingMatches(in: self.body, range: NSMakeRange(0, self.body.count), withTemplate: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct Mail: Cleanable, Replyable {
    var subject: String
    var body: String
    var authorID: String
    var position: Int
    var time: Date
    var flags: String
    var attachments: [SMAttachment]
    var attachmentCount: Int
    
    init(from mail: SMMail) {
        subject = mail.subject
        body = mail.body
        authorID = mail.authorID
        position = mail.position
        time = mail.time
        flags = mail.flags
        attachments = mail.attachments
        attachmentCount = mail.attachmentCount
        // make body clean
        body = clean(body)
    }
    
    init(subject: String, body: String, authorID: String) {
        self.subject = subject
        self.body = body
        self.authorID = authorID
        self.position = 0
        self.time = Date()
        self.flags = ""
        self.attachments = []
        self.attachmentCount = 0
    }
}

extension SMError {
    func display() {
        if code != 0 {
            var errorMsg: String = "未知错误"
            if code == -1 {
                errorMsg = "网络错误"
            } else if code == 10014 || code == 10010 {
                errorMsg = "token失效，请刷新"
                AppSetting.shared.accessToken = nil // clear expired access token
            } else if code == 10417 {
                errorMsg = "您还没有驻版"
            } else if !desc.isEmpty {
                errorMsg = desc
            } else if code < 0 {
                errorMsg = "服务器错误"
            } else if code < 11000 {
                errorMsg = "系统错误"
            }
            SVProgressHUD.showInfo(withStatus: errorMsg)
            dPrint(self)
        }
    }
}

protocol Replyable {
    var subject: String { get }
    var authorID: String { get }
    var body: String { get }
}

extension Replyable {
    var replySubject: String {
        var subject = self.subject
        while subject.lowercased().hasPrefix("re:") || subject.hasPrefix("主题:") {
            subject = subject.dropFirst(3).trimmingCharacters(in: .whitespaces)
        }
        return "Re: " + subject
    }
    
    var quotBody: String {
        let lines = body.components(separatedBy: .newlines).map {
            $0.trimmingCharacters(in: .whitespaces)
        }.filter {
            $0.range(of: "- 来自「最水木 for .*」", options: .regularExpression) == nil
        }
        let type = (self is Mail) ? "来信" : "大作"
        var tmpBody = "\n【 在 \(authorID) 的\(type)中提到: 】\n"
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
}

protocol Cleanable {
    func clean(_ content: String) -> String
}

extension Cleanable {
    func clean(_ content: String) -> String {
        // 去除头尾多余的空格和回车
        var lines = content.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        // 去除末尾的--
        // 以及多余的空格和回车
        if lines.last == "--" {
            lines.removeLast()
            while lines.last == "" {
                lines.removeLast()
            }
        }
        // 除去签名档，可选
        if !AppSetting.shared.showSignature {
            if let index = lines.firstIndex(of: "--") {
                var i = lines.count
                while i > index {
                    lines.removeLast()
                    i -= 1
                }
                while lines.last == "" {
                    lines.removeLast()
                }
            }
        }
        // 去除ANSI控制字符
        let ansiRE = try! NSRegularExpression(pattern: "\\[(\\d{1,2};?)*m|\\[([ABCDsuKH]|2J)(?![a-zA-Z])|\\[\\d{1,2}[ABCD]|\\[\\d{1,2};\\d{1,2}H")
        // 去除图片标志[upload=1][/upload]之类
        let pictRE = try! NSRegularExpression(pattern: "\\[upload(=\\d{1,2})?\\].*?\\[/upload\\]")
        lines = lines.map { line in
            var cleaned = ansiRE.stringByReplacingMatches(in: line, range: NSMakeRange(0, line.count), withTemplate: "")
            cleaned = pictRE.stringByReplacingMatches(in: cleaned, range: NSMakeRange(0, cleaned.count), withTemplate: "")
            return cleaned
        }
        // 过滤掉部分未过滤的来源信息
        lines = lines.filter { !$0.contains("※ 来源:·") && !$0.contains("※ 修改:·") }
        return lines.joined(separator: "\n")
    }
}

struct Emoticon {
    
    static let shared = Emoticon()
    
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
