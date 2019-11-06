//
//  SmthAPI.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/5.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import Foundation
import SmthConnection

class SmthAPI: SmthConnection {
    static let shared = SmthAPI()
    
    private let setting = AppSetting.shared
    
    private override init() {
        super.init()
        if let accessToken = setting.accessToken {
            self.accessToken = accessToken
        }
    }
    
    func getHotThreadList(in section: Int) throws -> [SMHotThread] {
        let semaphore = DispatchSemaphore(value: 0)
        var response: Response<[SMHotThread]>!
        getHotThreadList(in: section) { (result) in
            response = result
            semaphore.signal()
        }
        semaphore.wait()
        return try response.get()
    }
    
    func getBoard(id boardID: String) throws -> SMBoard {
        func first(_ boards: [SMBoard]) -> Response<SMBoard> {
            if let result = boards.first(where: { $0.boardID == boardID }) {
                return .success(result)
            } else {
                return .failure(SMError(code: -1001, desc: "版面不存在"))
            }
        }
        let semaphore = DispatchSemaphore(value: 0)
        var response: Response<SMBoard>!
        searchBoard(query: boardID) { (result) in
            response = result.flatMap { first($0) }
            semaphore.signal()
        }
        semaphore.wait()
        return try response.get()
    }
    
    func getThreadList(in boardID: String, range: NSRange, brcmode: SMThread.ClearUnreadMode = .none) throws -> [SMThread] {
        let semaphore = DispatchSemaphore(value: 0)
        var response: Response<[SMThread]>!
        getThreadList(in: boardID, range: range, brcmode: brcmode) { (result) in
            response = result
            semaphore.signal()
        }
        semaphore.wait()
        return try response.get()
    }
    
    func getThreadCount(in boardID: String) throws -> Int {
        let semaphore = DispatchSemaphore(value: 0)
        var response: Response<Int>!
        getThreadCount(in: boardID) { (result) in
            response = result
            semaphore.signal()
        }
        semaphore.wait()
        return try response.get()
    }
    
    func getThread(_ articleID: Int, in boardID: String, range: NSRange, sort: SMThread.ReplySortMode) throws -> (articles: [Article], total: Int) {
        let semaphore = DispatchSemaphore(value: 0)
        var response: Response<([Article], Int)>!
        getThread(articleID, in: boardID, range: range, sort: sort) { (result) in
            response = result.map({ ($0.0.enumerated().map({ Article(from: $0.element, floor: range.location + $0.offset, boardID: boardID) }), $0.1) })
            semaphore.signal()
        }
        semaphore.wait()
        return try response.get()
    }
    
    func getThreadWithRetry(_ articleID: Int, in boardID: String, range: NSRange, sort: SMThread.ReplySortMode) throws -> (articles: [Article], total: Int) {
        do {
            return try getThread(articleID, in: boardID, range: range, sort: sort)
        } catch {
            if let error = error as? SMError, error.code == 10010 || error.code == 10014, let user = setting.username, let pass = setting.password {
                let semaphore = DispatchSemaphore(value: 0)
                var loginSuccess = false
                login(username: user, password: pass) { (success) in
                    loginSuccess = success
                    semaphore.signal()
                }
                semaphore.wait()
                if loginSuccess {
                    setting.accessToken = accessToken
                    return try getThread(articleID, in: boardID, range: range, sort: sort)
                } else {
                    throw SMError(code: -1002, desc: "尝试登录失败")
                }
                
            } else {
                throw error
            }
        }
    }
    
    func searchArticle(user: String, in boardID: String, range: NSRange) throws -> [SMThread] {
        let semaphore = DispatchSemaphore(value: 0)
        var response: Response<[SMThread]>!
        searchArticle(user: user, in: boardID, range: range) { (result) in
            response = result
            semaphore.signal()
        }
        semaphore.wait()
        return try response.get()
    }
    
    func searchArticle(title: String, in boardID: String, range: NSRange) throws -> [SMThread] {
        let semaphore = DispatchSemaphore(value: 0)
        var response: Response<[SMThread]>!
        searchArticle(title: title, in: boardID, range: range) { (result) in
            response = result
            semaphore.signal()
        }
        semaphore.wait()
        return try response.get()
    }
    
    func getArticle(_ articleID: Int, in boardID: String) throws -> SMArticle {
        let semaphore = DispatchSemaphore(value: 0)
        var response: Response<SMArticle>!
        getArticle(articleID, in: boardID) { (result) in
            response = result
            semaphore.signal()
        }
        semaphore.wait()
        return try response.get()
    }
    
    func queryUser(with userID: String) throws -> SMUser {
        let semaphore = DispatchSemaphore(value: 0)
        var response: Response<SMUser>!
        queryUser(with: userID) { (result) in
            response = result
            semaphore.signal()
        }
        semaphore.wait()
        return try response.get()
    }
    
    func getMailCount() throws -> (totalCount: Int, newCount: Int, isFull: Bool) {
        let semaphore = DispatchSemaphore(value: 0)
        var response: Response<(Int, Int, Bool)>!
        getMailCount { result in
            response = result
            semaphore.signal()
        }
        semaphore.wait()
        return try response.get()
    }
    
    func getMailCountSent() throws -> Int {
        let semaphore = DispatchSemaphore(value: 0)
        var response: Response<Int>!
        getMailCountSent { result in
            response = result
            semaphore.signal()
        }
        semaphore.wait()
        return try response.get()
    }
    
    func getReferCount(mode: SMReference.ReferMode) throws -> (totalCount: Int, newCount: Int) {
        let semaphore = DispatchSemaphore(value: 0)
        var response: Response<(Int, Int)>!
        getReferCount(mode: mode) { result in
            response = result
            semaphore.signal()
        }
        semaphore.wait()
        return try response.get()
    }
    
    enum HTTPMethod {
        case get
        case post
    }
    
    private func httpRequest(url: URL, method: HTTPMethod = .get, params: String? = nil, referer: String? = nil) -> Data? {
        var request = URLRequest(url: url)
        switch method {
        case .post:
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.setValue(setting.httpPrefix + "www.newsmth.net", forHTTPHeaderField: "Origin")
            request.httpBody = params?.data(using: .utf8)
        case .get:
            request.httpMethod = "GET"
        }
        if let referer = referer {
            request.setValue(referer, forHTTPHeaderField: "Referer")
        } else {
            request.setValue(url.absoluteString, forHTTPHeaderField: "Referer")
        }
        let semaphore = DispatchSemaphore(value: 0)
        var returnData: Data?
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            returnData = data
            semaphore.signal()
        }.resume()
        semaphore.wait()
        return returnData
    }
    
    private func www2Login(id: String, pass: String) {
        let url = URL(string: setting.httpPrefix + "www.newsmth.net/bbslogin.php")!
        _ = httpRequest(url: url, method: .post, params: "id=\(id.percent)&passwd=\(pass.percent)&kick_multi=1")
    }

    // get thread list in origin mode
    private func _getOriginThreadList(for boardID: String, page: Int) -> (page: Int, threads: [SMThread]) {
        var url = setting.httpPrefix + "www.newsmth.net/bbsdoc.php?board=\(boardID)&ftype=6"
        if page > 0 {
            url.append(contentsOf: "&page=\(page)")
        }
        guard let data = httpRequest(url: URL(string: url)!) else { return (0, []) } // 无法加载数据，直接返回空
        let enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
        guard let result = String(data: data, encoding: String.Encoding(rawValue: enc)) else { return (-1, []) } // 解码错误
        if result.contains("<tr><td>错误的讨论区</td></tr>") { return (-2, []) } // 没有权限？
        let lines = result.components(separatedBy: .newlines)
        guard let writerLine = lines.filter({ $0.hasPrefix("var c = new docWriter(")}).first else { return (0, []) }
        let writerComponents = writerLine.split(separator: ",")
        guard writerComponents.count == 10 else { return (0, []) }
        guard let page = Int(writerComponents[5]) else { return (0, []) }
        
        let threads: [SMThread] = lines.filter({ $0.hasPrefix("c.o(") }).map { (line) -> SMThread in
            let start = line.index(line.startIndex, offsetBy: 4)
            let end = line.index(line.endIndex, offsetBy: -2)
            let cleanLine = line[start..<end]
            let components = cleanLine.split(separator: ",")
            let id = Int(components[1]) ?? 0
            let author = String(components[2]).trimmingCharacters(in: CharacterSet(charactersIn: "'"))
            let flag = String(components[3]).trimmingCharacters(in: CharacterSet(charactersIn: "'"))
            let time = Date(timeIntervalSince1970: TimeInterval(components[4]) ?? 0)
            let title = String(components[5]).trimmingCharacters(in: CharacterSet(charactersIn: "'").union(.whitespaces)).unescapingFromHTML()
            return SMThread(id: id, time: time, subject: title, authorID: author, flags: flag)
        }
        
        if threads.count > 0 {
            return (page, threads)
        }
        return (0, [])
    }
    
    func getOriginThreadList(for boardID: String, page: Int) -> (page: Int, threads: [SMThread]) {
        let result = _getOriginThreadList(for: boardID, page: page)
        if result.page == -2, let user = setting.username, let pass = setting.password { // 可能是因为权限导致无法获取数据，登录后再试一次
            www2Login(id: user, pass: pass)
            return _getOriginThreadList(for: boardID, page: page)
        }
        return result
    }
    
    // add favorite directory
    func addFavoriteDirectory(_ name: String, in group: Int, user: String, pass: String) -> Bool {
        let error = addFavoriteDirectory(name, in: group)
        if error == 0 {
            return true
        } else if error == -3 {
            www2Login(id: user, pass: pass)
            return addFavoriteDirectory(name, in: group) == 0
        }
        return false
    }
    
    // del favorite directory
    func delFavoriteDirectory(_ index: Int, in group: Int, user: String, pass: String) -> Bool {
        let error = delFavoriteDirectory(index, in: group)
        if error == 0 {
            return true
        } else if error == -3 {
            www2Login(id: user, pass: pass)
            return delFavoriteDirectory(index, in: group) == 0
        }
        return false
    }
    
    private func addFavoriteDirectory(_ name: String, in group: Int) -> Int {
        let url = URL(string: setting.httpPrefix + "www.newsmth.net/bbsfav.php?dname=\(name.percentEncodingWithGBK)&select=\(group)")!
        let referer = setting.httpPrefix + "www.newsmth.net/bbsfav.php?select=\(group)"
        guard let data = httpRequest(url: url, referer: referer) else { return -1 } // 无法加载数据
        let enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
        guard let result = String(data: data, encoding: String.Encoding(rawValue: enc)) else { return -2 } // 解码错误
        if result.contains("您还没有登录，或者长时间没有动作，请您重新登录。") {
            return -3 // 未登录
        }
        return 0 // 正确
    }
    
    private func delFavoriteDirectory(_ index: Int, in group: Int) -> Int {
        let url = URL(string: setting.httpPrefix + "www.newsmth.net/bbsfav.php?select=\(group)&deldir=\(index)")!
        let referer = setting.httpPrefix + "www.newsmth.net/bbsfav.php?select=\(group)"
        guard let data = httpRequest(url: url, referer: referer) else { return -1 } // 无法加载数据
        let enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
        guard let result = String(data: data, encoding: String.Encoding(rawValue: enc)) else { return -2 } // 解码错误
        if result.contains("您还没有登录，或者长时间没有动作，请您重新登录。") {
            return -3 // 未登录
        }
        return 0 // 正确
    }
    
    func faceURL(for userID: String, withFaceURL faceURL: String?) -> URL {
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
        return URL(string: setting.httpPrefix + "images.newsmth.net/nForum/uploadFace/\(prefix)/\(faceString)")!
    }
    
    @discardableResult
    func uploadAttachImage(_ image: UIImage, baseFileName: String) throws -> [SMAttachment] {
        let data = convertedAttData(from: image)
        let semaphore = DispatchSemaphore(value: 0)
        var response: Response<[SMAttachment]>!
        addAttachment(data, name: "\(baseFileName).jpg") { (result) in
            response = result
            semaphore.signal()
        }
        semaphore.wait()
        return try response.get()
    }
    
    func modifyUserFaceImage(_ image: UIImage, completion: @escaping SmthCompletion<SMUser>) {
        let data = convertedFaceData(from: image)
        modifyUserFace(with: data, completion: completion)
    }
    
    private func image(with image: UIImage, scaledTo newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(newSize)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? UIImage()
    }

    private func resizedAttImage(from attImage: UIImage) -> UIImage {
        let width: CGFloat = 1280
        let currentWidth = attImage.size.width
        if currentWidth <= width {
            return attImage
        }
        let height = attImage.size.height * width / currentWidth
        let newImageSize = CGSize(width: width, height: height)
        return image(with: attImage, scaledTo: newImageSize)
    }

    private func convertedAttData(from image: UIImage) -> Data {
        let newImage = resizedAttImage(from: image)
        var compressionQuality: CGFloat = 1
        var data = newImage.jpegData(compressionQuality: compressionQuality)!
        let maxSize = 1 * 1024 * 1024
        while data.count > maxSize && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            data = newImage.jpegData(compressionQuality: compressionQuality)!
        }
        return data
    }
    
    private func resizedFaceImage(from faceImage: UIImage) -> UIImage {
        let width: CGFloat = 120
        let height: CGFloat = 120
        let currentWidth = faceImage.size.width
        if currentWidth <= width {
            return faceImage
        }
        let newImageSize = CGSize(width: width, height: height)
        return image(with: faceImage, scaledTo: newImageSize)
    }
    
    private func convertedFaceData(from image: UIImage) -> Data {
        let newImage = resizedFaceImage(from: image)
        var compressionQuality: CGFloat = 1
        var data = newImage.jpegData(compressionQuality: compressionQuality)!
        let maxSize = 50 * 1024
        while data.count > maxSize && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            data = newImage.jpegData(compressionQuality: compressionQuality)!
        }
        return data
    }
}

extension CharacterSet {
    public static let smURLQueryAllowed: CharacterSet = {
        let encodableDelimiters = CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]")
        return CharacterSet.urlQueryAllowed.subtracting(encodableDelimiters)
    }()
}

extension String {
    var percent: String {
        return self.addingPercentEncoding(withAllowedCharacters: .smURLQueryAllowed)!
    }
    
    var percentEncodingWithGBK: String {
        var result = String()
        for char in self.unicodeScalars {
            if CharacterSet.smURLQueryAllowed.contains(char) {
                result.unicodeScalars.append(char)
            } else {
                if let encoded = gbkEncode(String(char)) {
                    result.append(encoded)
                }
            }
        }
        return result
    }
    
    func gbkEncode(_ str: String) -> String? {
        let enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
        if let gbkData = str.data(using: String.Encoding(rawValue: enc)) {
            return gbkData.reduce("") { (substring, uint) -> String in
                substring + String(format: "%%%X", uint)
            }
        }
        return nil
    }
}
