//
//  SmthAPI.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/5.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import Foundation

class SmthAPI {
    init() {
        api.init_smth()
    }

    private let setting = AppSetting.shared

    // MARK: - Properties
    // error code and error description
    // after each api call, error code and description will be set
    var errorCode: Int { return Int(api.net_error) }
    var errorDescription: String? { return api.net_error_desc }

    // the access token
    var accessToken: String? {
        get { return apiGetAccessToken() }
        set { apiSetAccessToken(newValue) }
    }
    
    func cancel() {
        api.cancel()
    }
    
    //MARK: - Attachments
    //if upload succeed, return attachment array, otherwise, nil
    @discardableResult
    func uploadAttImage(image: UIImage, baseFileName: String) -> [SMAttachment]? {
        let data = convertedAttData(from: image)
        return upload(data: data, name: "\(baseFileName).jpg")
    }
    
    @discardableResult
    func upload(data: Data, name: String) -> [SMAttachment]? {
        api.reset_status()
        if let rawAttachments = api.net_AddAttachment(data, name) as? [[String:Any]] {
            var attachments = [SMAttachment]()
            for rawAttachment in rawAttachments {
                if
                    let name = rawAttachment["name"] as? String,
                    let size = rawAttachment["size"] as? Int
                {
                    attachments.append(SMAttachment(name: name, pos: -1, size: size))
                }
            }
            if !attachments.isEmpty {
                return attachments
            }
        }
        return nil
    }
    
    func getAttList() -> [SMAttachment]? {
        api.reset_status()
        if let rawAttachments = api.net_GetAttachmentList() as? [[String:Any]] {
            var attachments = [SMAttachment]()
            for rawAttachment in rawAttachments {
                if
                    let name = rawAttachment["name"] as? String,
                    let size = rawAttachment["size"] as? Int
                {
                    attachments.append(SMAttachment(name: name, pos: -1, size: size))
                }
            }
            if !attachments.isEmpty {
                return attachments
            }
        }
        return nil
    }

    //MARK: - Thread
    // get the thread count of a board
    func getThreadCountForBoard(boardID: String) -> Int {
        api.reset_status()
        return api.net_GetThreadCnt(boardID)
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
            request.setValue("https://www.newsmth.net", forHTTPHeaderField: "Origin")
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
    
    private func bbsSilentLogin(id: String, pass: String) {
        let url = URL(string: "https://www.newsmth.net/bbslogin.php")!
        _ = httpRequest(url: url, method: .post, params: "id=\(id.percent)&passwd=\(pass.percent)&kick_multi=1")
    }

    // get thread list in origin mode
    private func _getOriginThreadList(for boardID: String, page: Int) -> (page: Int, threads: [SMThread]) {
        var url = "https://www.newsmth.net/bbsdoc.php?board=\(boardID)&ftype=6"
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
            return SMThread(id: id, time: time, subject: title, authorID: author, lastReplyAuthorID: "", lastReplyThreadID: 0, boardID: "", boardName: "", flags: flag, count: 0, lastReplyTime: Date(timeIntervalSince1970: 0))
        }
        
        if threads.count > 0 {
            return (page, threads)
        }
        return (0, [])
    }
    
    func getOriginThreadList(for boardID: String, page: Int) -> (page: Int, threads: [SMThread]) {
        let result = _getOriginThreadList(for: boardID, page: page)
        if result.page == -2, let user = setting.username, let pass = setting.password { // 可能是因为权限导致无法获取数据，登录后再试一次
            bbsSilentLogin(id: user, pass: pass)
            return _getOriginThreadList(for: boardID, page: page)
        }
        return result
    }
    
    enum ClearUnreadMode: Int32 {
        case ClearAll = 0, ClearLast, NotClear
    }

    // get the thread list
    func getThreadListForBoard(boardID: String, inRange: NSRange, brcmode: ClearUnreadMode) -> [SMThread]? {
        api.reset_status()
        var threadList = [SMThread]()
        let rawResults = api.net_LoadThreadList(boardID, inRange.location, inRange.length, brcmode.rawValue)
        if let results = rawResults as? [[String:Any]] {
            for result in results {
                if let thread = threadFromDictionary(dict: result) {
                    threadList.append(thread)
                }
            }
            if threadList.count > 0 {
                return threadList
            }
        }
        return nil
    }

    enum SortMode: Int32 {
        case LaterPostFirst = 0, Normal
    }
    
    // get thread content in board with article id, if assess_token failed, try again
    func getThreadContentInBoard(boardID: String, articleID: Int, threadRange: NSRange, replyMode: SortMode) -> [SMArticle]? {
        if let articles = _getThreadContentInBoard(boardID, articleID, threadRange, replyMode) {
            return articles
        }
        // invalid access_token or access_token expired, try to silent login and get data again
        if errorCode == 10010 || errorCode == 10014, let user = setting.username, let pass = setting.password {
            api.reset_status()
            let loginSuccess = loginBBS(username: user, password: pass) != 0
            if loginSuccess && errorCode == 0 {
                setting.accessToken = accessToken
                return _getThreadContentInBoard(boardID, articleID, threadRange, replyMode)
            }
        }
        return nil
    }
    
    // get thread content in board with article id
    private func _getThreadContentInBoard(_ boardID: String, _ articleID: Int, _ threadRange: NSRange, _ replyMode: SortMode) -> [SMArticle]? {
        api.reset_status()
        var articleList = [SMArticle]()
        let rawResults = api.net_GetThread(boardID, articleID, threadRange.location, threadRange.length, replyMode.rawValue)
        if let results = rawResults as? [[String:Any]] {
            for (index, result) in results.enumerated() {
                if let article = article(from: result, floor: threadRange.location + index, boardID: boardID) {
                    articleList.append(article)
                }
            }
            if articleList.count > 0 {
                return articleList
            }
        }
        return nil
    }

    // call this after getThreadContentInBoard to get the last thread articles count
    func getLastThreadCount() -> Int {
        return api.net_GetLastThreadCnt()
    }

    // MARK: - Article
    // search article in board using keyword in title, if title is nil, then search article posted by user
    func searchArticleInBoard(boardID: String, title: String?, user: String?, inRange: NSRange) -> [SMThread]? {
        api.reset_status()
        var threadList = [SMThread]()
        let rawResults = api.net_SearchArticle(boardID, title, user, inRange.location, inRange.length)
        if let results = rawResults as? [[String:Any]] {
            for result in results {
                if let thread = threadFromDictionary(dict: result) {
                    threadList.append(thread)
                }
            }
            if threadList.count > 0 {
                return threadList
            }
        }
        return nil
    }

    // get article count of board
    func getArticleCountOfBoard(boardID: String) -> Int {
        api.reset_status()
        return api.net_GetArticleCnt(boardID)
    }
    
    // get article in board with article id
    func getArticleInBoard(boardID: String, articleID: Int) -> SMArticle? {
        api.reset_status()
        if let rawValue = api.net_GetArticle(boardID, articleID) as? [String:Any],
            let article = article(from: rawValue, floor: -1, boardID: boardID) {
            return article
        }
        return nil
    }

    // post article in board
    func postArticle(title: String, content: String, inBoard boardID: String) -> Int {
        api.reset_status()
        return api.net_PostArticle(boardID, title, content)
    }

    // forward article to user
    func forwardArticle(articleID: Int, inBoard boardID: String, toUser userID: String) -> Int {
        api.reset_status()
        return api.net_ForwardArticle(boardID, articleID, userID)
    }

    // reply article
    func replyArticle(articleID: Int, title: String, content: String, inBoard boardID: String) -> Int {
        api.reset_status()
        return api.net_ReplyArticle(boardID, articleID, title, content)
    }

    // cross article
    func crossArticle(articleID: Int, fromBoard: String, toBoard: String) -> Int {
        api.reset_status()
        return api.net_CrossArticle(fromBoard, articleID, toBoard)
    }
    
    // modify article
    func modifyArticle(articleID: Int, title: String, content: String, inBoard boardID: String) -> Int {
        api.reset_status()
        return api.net_ModifyArticle(boardID, articleID, title, content)
    }
    
    // delete article
    func deleteArticle(articleID: Int, inBoard boardID: String) -> Int {
        api.reset_status()
        return api.net_DeleteArticle(boardID, articleID)
    }

    // MARK: - Mail
    // get sent mail count
    func getMailSentCount() -> Int {
        api.reset_status()
        return Int(api.net_GetMailCountSent())
    }

    // get mail status
    func getMailStatus() -> SMMailStatus? {
        api.reset_status()
        if
            let rawValue = api.net_GetMailCount() as? [String:Any],
            let is_full = rawValue["is_full"] as? Bool,
            let error_description = rawValue["error_description"] as? String,
            let total_count = rawValue["total_count"] as? Int,
            let error = rawValue["error"] as? Int,
            let new_count = rawValue["new_count"] as? Int
        {
            return SMMailStatus(isFull: is_full, totalCount: total_count, newCount: new_count, error: error, errorDescription: error_description)
        }
        return nil
    }

    // get sent mail list
    func getMailSentList(inRange: NSRange) -> [SMMail]? {
        api.reset_status()
        var mailList = [SMMail]()
        if let rawValues = api.net_LoadMailSentList(inRange.location, inRange.length) as? [[String:Any]] {
            for rawValue in rawValues {
                if let mail = mailFromDictionary(dict: rawValue) {
                    mailList.append(mail)
                }
            }
            if mailList.count > 0 {
                return mailList
            }
        }
        return nil
    }

    // get mail list
    func getMailList(inRange: NSRange) -> [SMMail]? {
        api.reset_status()
        var mailList = [SMMail]()
        if let rawValues = api.net_LoadMailList(inRange.location, inRange.length) as? [[String:Any]] {
            for rawValue in rawValues {
                if let mail = mailFromDictionary(dict: rawValue) {
                    mailList.append(mail)
                }
            }
            if mailList.count > 0 {
                return mailList
            }
        }
        return nil
    }

    // get sent mail at position
    func getMailSentAtPosition(position: Int) -> SMMail? {
        api.reset_status()
        if let rawValue = api.net_GetMailSent(Int32(position)) as? [String:Any] {
            return mailFromDictionary(dict: rawValue)
        }
        return nil
    }

    // get mail at position
    func getMailAtPosition(position: Int) -> SMMail? {
        api.reset_status()
        if let rawValue = api.net_GetMail(Int32(position)) as? [String:Any] {
            return mailFromDictionary(dict: rawValue)
        }
        return nil
    }

    // reply mail
    func replyToMailAtPosition(position: Int, withTitle: String, content: String) -> Int {
        api.reset_status()
        return Int(api.net_ReplyMail(Int32(position), withTitle, content))
    }

    // forward mail
    func forwardMailAtPosition(position: Int, toUser: String) -> Int {
        api.reset_status()
        return api.net_ForwardMail(Int32(position), toUser)
    }

    // send mail
    func sendMailTo(user: String, withTitle: String, content: String) -> Int {
        api.reset_status()
        return Int(api.net_PostMail(user, withTitle, content))
    }
    

    // MARK: - Reference
    enum ReferMode: Int32 {
        case AtMe = 1, ReplyToMe
    }
    // get reference count
    func getReferCount(mode: ReferMode) -> SMReferenceStatus? {
        api.reset_status()
        if
            let dict = api.net_GetReferCount(mode.rawValue) as? [String:Any],
            let error_description = dict["error_description"] as? String,
            let total_count = dict["total_count"] as? Int,
            let error = dict["error"] as? Int,
            let new_count = dict["new_count"] as? Int
        {
            return SMReferenceStatus(totalCount: total_count, newCount: new_count, error: error, errorDescription: error_description)
        }
        return nil
    }

    // get reference list
    func getReferList(mode: ReferMode, inRange: NSRange) -> [SMReference]? {
        api.reset_status()
        var referList = [SMReference]()
        if let references = api.net_LoadRefer(mode.rawValue, inRange.location, inRange.length) as? [[String:Any]] {
            for refer in references {
                if let refer = referenceFromDictionary(dict: refer) {
                    referList.append(refer)
                }
            }
            if referList.count > 0 {
                return referList
            }
        }
        return nil
    }

    // set reference read
    func setReferRead(mode: ReferMode, atPosition: Int) -> Int {
        api.reset_status()
        return Int(api.net_SetReferRead(mode.rawValue, Int32(atPosition)))
    }

    // MARK: - Favorite
    // get favorite board list
    func getFavBoardList(group: Int) -> [SMBoard]? {
        api.reset_status()
        var boardList = [SMBoard]()
        if let rawList = api.net_LoadFavorites(group) as? [[String:Any]] {
            for rawBoard in rawList {
                if let board = boardFromDictionary(dict: rawBoard) {
                    boardList.append(board)
                }
            }
            if boardList.count > 0 {
                return boardList
            }
        }
        return nil
    }

    // add favorite board
    func addFavorite(boardID: String, group: Int) {
        api.reset_status()
        api.net_AddFav(boardID, group)
    }

    // del favorite board
    func delFavorite(boardID: String, group: Int) {
        api.reset_status()
        api.net_DelFav(boardID, group)
    }
    
    // add favorite directory
    func addFavoriteDirectory(_ name: String, in group: Int, user: String, pass: String) -> Bool {
        let error = addFavoriteDirectory(name, in: group)
        if error == 0 {
            return true
        } else if error == -3 {
            bbsSilentLogin(id: user, pass: pass)
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
            bbsSilentLogin(id: user, pass: pass)
            return delFavoriteDirectory(index, in: group) == 0
        }
        return false
    }
    
    private func addFavoriteDirectory(_ name: String, in group: Int) -> Int {
        let url = URL(string: "https://www.newsmth.net/bbsfav.php?dname=\(name.percentEncodingWithGBK)&select=\(group)")!
        let referer = "https://www.newsmth.net/bbsfav.php?select=\(group)"
        guard let data = httpRequest(url: url, referer: referer) else { return -1 } // 无法加载数据
        let enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
        guard let result = String(data: data, encoding: String.Encoding(rawValue: enc)) else { return -2 } // 解码错误
        if result.contains("您还没有登录，或者长时间没有动作，请您重新登录。") {
            return -3 // 未登录
        }
        return 0 // 正确
    }
    
    private func delFavoriteDirectory(_ index: Int, in group: Int) -> Int {
        let url = URL(string: "https://www.newsmth.net/bbsfav.php?select=\(group)&deldir=\(index)")!
        let referer = "https://www.newsmth.net/bbsfav.php?select=\(group)"
        guard let data = httpRequest(url: url, referer: referer) else { return -1 } // 无法加载数据
        let enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
        guard let result = String(data: data, encoding: String.Encoding(rawValue: enc)) else { return -2 } // 解码错误
        if result.contains("您还没有登录，或者长时间没有动作，请您重新登录。") {
            return -3 // 未登录
        }
        return 0 // 正确
    }

    // MARK: - Board
    // get board list
    func getBoardList(group: Int) -> [SMBoard]? {
        api.reset_status()
        var boardList = [SMBoard]()
        if let rawList = api.net_LoadBoards(group) as? [[String:Any]] {
            for rawBoard in rawList {
                if let board = boardFromDictionary(dict: rawBoard) {
                    boardList.append(board)
                }
            }
            if boardList.count > 0 {
                return boardList
            }
        }
        return nil
    }

    // get board list in section
    func getBoardListInSection(section: Int, group: Int) -> [SMBoard]? {
        api.reset_status()
        var boardList = [SMBoard]()
        if let rawList = api.net_ReadSection(section, group) as? [[String:Any]] {
            for rawBoard in rawList {
                if let board = boardFromDictionary(dict: rawBoard) {
                    boardList.append(board)
                }
            }
            if boardList.count > 0 {
                return boardList
            }
        }
        return nil
    }

    // search board
    func queryBoard(query: String) -> [SMBoard]? {
        api.reset_status()
        var boardList = [SMBoard]()
        if let rawList = api.net_QueryBoard(query) as? [[String:Any]] {
            for rawBoard in rawList {
                if let board = boardFromDictionary(dict: rawBoard) {
                    boardList.append(board)
                }
            }
            if boardList.count > 0 {
                return boardList
            }
        }
        return nil
    }

    // MARK: - Section
    // get all sections
    func getSectionList() -> [SMSection]? {
        api.reset_status()
        var sectionList = [SMSection]()
        if let rawList = api.net_LoadSection() as? [[String:Any]] {
            for raw in rawList {
                if
                    let code = raw["code"] as? String,
                    let desc = raw["desc"] as? String,
                    let name = raw["name"] as? String,
                    let id = raw["id"] as? Int
                {
                    sectionList.append(SMSection(code: code, description: desc, name: name, id: id))
                }
            }
            if sectionList.count > 0 {
                return sectionList
            }
        }
        return nil
    }

    // get hot thread in section
    func getHotThreadListInSection(section: Int) -> [SMHotThread]? {
        api.reset_status()
        var hotThreadList = [SMHotThread]()
        if let rawThreads = api.net_LoadSectionHot(section) as? [[String: Any]] {
            for rawThread in rawThreads {
                if let hotThread = hotThreadFromDictionary(dict: rawThread) {
                    hotThreadList.append(hotThread)
                }
            }
            if hotThreadList.count > 0 {
                return hotThreadList
            }
        }
        return nil
    }

    // MARK: - User Related
    // get user info
    func getUserInfo(userID: String) -> SMUser? {
        api.reset_status()
        if let rawData = api.net_QueryUser(userID) as? [String:Any] {
            return userFromDictionary(dict: rawData)
        }
        return nil
    }

    // get user friend list
    func getUserFriendList(userID: String) -> [String]? {
        api.reset_status()
        var friendList = [String]()
        if let rawList = api.net_LoadUserAllFriends(userID) as? [[String:Any]] {
            for raw in rawList {
                if let userID = raw["ID"] as? String {
                    friendList.append(userID)
                }
            }
            if friendList.count > 0 {
                return friendList
            }
        }
        return nil
    }

    // get user friend list refresh time stamp
    func getFriendListRefreshStamp(userID: String) -> Int {
        api.reset_status()
        return Int(api.net_LoadUserFriendsTS(userID))
    }

    // add friend
    func addFriend(friendID: String) -> Int {
        api.reset_status()
        return Int(api.net_AddUserFriend(friendID))
    }

    // delete friend
    func delFriend(friendID: String) -> Int {
        api.reset_status()
        return Int(api.net_DelUserFriend(friendID))
    }

    // modify user face image
    func modifyFaceImage(image: UIImage) -> SMUser? {
        let data = convertedFaceData(from: image)
        api.reset_status()
        if let rawData = api.net_ModifyUserFace(data) as? [String: Any] {
            return userFromDictionary(dict: rawData)
        }
        return nil
    }

    // login to the bbs
    func loginBBS(username: String, password: String) -> Int {
        api.reset_status()
        return Int(api.net_LoginBBS(username, password))
    }

    // logout
    func logoutBBS() {
        api.reset_status()
        api.net_LogoutBBS()
    }

    // get user membership board list
    func getUserMemberList(userID: String) -> [SMMember]? {
        api.reset_status()
        var memberList = [SMMember]()
        if let rawList = api.net_LoadMember(userID, 0, 100) as? [[String:Any]] {
            for raw in rawList {
                if let member = memberFromDictionary(dict: raw) {
                    memberList.append(member)
                }
            }
            if memberList.count > 0 {
                return memberList
            }
        }
        return nil
    }

    // join membership of a board
    func joinMemberOfBoard(boardID: String) -> Int {
        api.reset_status()
        return Int(api.net_JoinMember(boardID))
    }

    // quit membership of a board
    func quitMemberOfBoard(boardID: String) -> Int {
        api.reset_status()
        return Int(api.net_QuitMember(boardID))
    }


    // MARK: - Private Implementation
    private let api = SMTHURLConnection()

    // private implementation of smth API
    private func threadFromDictionary(dict: [String:Any]) -> SMThread? {
        if
            let id = dict["id"] as? Int,
            let count = dict["count"] as? Int,
            let last_reply_id = dict["last_reply_id"] as? Int,

            let subject = dict["subject"] as? String,
            let author_id = dict["author_id"] as? String,
            let board_id = dict["board_id"] as? String,
            let flags = dict["flags"] as? String,
            let last_user_id = dict["last_user_id"] as? String,
            let board_name = dict["board_name"] as? String,

            let timeInterval = dict["time"] as? Double,
            let lastTimeInterval = dict["last_time"] as? Double

        {
            let time = Date(timeIntervalSince1970: timeInterval)
            let last_time = Date(timeIntervalSince1970: lastTimeInterval)

            return SMThread(id: id, time: time, subject: subject, authorID: author_id, lastReplyAuthorID: last_user_id, lastReplyThreadID: last_reply_id, boardID: board_id, boardName: board_name, flags: flags, count: count, lastReplyTime: last_time)
        }
        return nil
    }

    private func article(from dict: [String:Any], floor: Int, boardID: String) -> SMArticle? {
        if
            let id = dict["id"] as? Int,
            let subject = dict["subject"] as? String,
            let rawBody = dict["body"] as? String,
            let author_id = dict["author_id"] as? String,
            let effsize = dict["effsize"] as? Int,
            let flags = dict["flags"] as? String,
            let timeInterval = dict["time"] as? Double
        {
            let body = cleanedString(from: rawBody)
            let time = Date(timeIntervalSince1970: timeInterval)
            var attachments = [SMAttachment]()
            if let rawAttachments = dict["attachment_list"] as? [[String:Any]] {
                for rawAttachment in rawAttachments {
                    if
                        let name = rawAttachment["name"] as? String,
                        let pos = rawAttachment["pos"] as? Int,
                        let size = rawAttachment["size"] as? Int
                    {
                        attachments.append(SMAttachment(name: name, pos: pos, size: size))
                    }
                }
            }
            return SMArticle(id: id, time: time, subject: subject, authorID: author_id, body: body, effsize: effsize, flags: flags, attachments: attachments, floor: floor, boardID: boardID)
        }
        return nil
    }

    private func mailFromDictionary(dict: [String:Any]) -> SMMail? {
        if
            let author_id = dict["author_id"] as? String,
            let rawBody = dict["body"] as? String,
            let flags = dict["flags"] as? String,
            let subject = dict["subject"] as? String,
            let timeInterval = dict["time"] as? Double
        {
            let time = Date(timeIntervalSince1970: timeInterval)
            var position = 0
            if let rawPosition = dict["position"] as? Int {
                position = rawPosition
            } else if let rawPosition = dict["position"] as? String {
                position = Int(rawPosition) ?? 0
            }
            let body = cleanedString(from: rawBody)
            var attachments = [SMAttachment]()
            if let rawAttachments = dict["attachment_list"] as? [[String:Any]] {
                for rawAttachment in rawAttachments {
                    if
                        let name = rawAttachment["name"] as? String,
                        let pos = rawAttachment["pos"] as? Int,
                        let size = rawAttachment["size"] as? Int
                    {
                        attachments.append(SMAttachment(name: name, pos: pos, size: size))
                    }
                }
            }
            return SMMail(subject: subject, body: body, authorID: author_id, position: position, time: time, flags: flags, attachments: attachments)

        }
        return nil
    }

    private func referenceFromDictionary(dict: [String:Any]) -> SMReference? {
        if
            let subject = dict["subject"] as? String,
            let flag = dict["flag"] as? Int,
            let re_id = dict["re_id"] as? Int,
            let rawMode = dict["mode"] as? Int32,
            let mode = SmthAPI.ReferMode(rawValue: rawMode),
            let id = dict["id"] as? Int,
            let board_id = dict["board_id"] as? String,
            let user_id = dict["user_id"] as? String,
            let group_id = dict["group_id"] as? Int,
            let timeInterval = dict["time"] as? Double
        {
            let time = Date(timeIntervalSince1970: timeInterval)
            var position = 0
            if let rawPosition = dict["position"] as? Int {
                position = rawPosition
            } else if let rawPosition = dict["position"] as? String {
                position = Int(rawPosition) ?? 0
            }
            return SMReference(subject: subject, flag: flag, replyID: re_id, mode: mode, id: id, boardID: board_id, time: time, userID: user_id, groupID: group_id, position: position)
        }
        return nil
    }

    private func hotThreadFromDictionary(dict: [String:Any]) -> SMHotThread? {
        if
            let rawSubject = dict["subject"] as? String,
            let author_id = dict["author_id"] as? String,
            let rawBoard_id = dict["board"] as? String,
            let timeInterval = (dict["time"] as? NSString)?.doubleValue,
            let count = (dict["count"] as? NSString)?.integerValue,
            let id = (dict["id"] as? NSString)?.integerValue
        {
            let subject = rawSubject.unescapingFromHTML()
            let board_id = htmlDotDecode(string: rawBoard_id)
            let time = Date(timeIntervalSince1970: timeInterval)
            return SMHotThread(subject: subject, authorID: author_id, id: id, time: time, boardID: board_id, count: count)
        }
        return nil
    }

    private func htmlDotDecode(string: String) -> String {
        return string.replacingOccurrences(of: "%2E", with: ".")
    }

    private func boardFromDictionary(dict: [String:Any]) -> SMBoard? {
        if
            let level = dict["level"] as? Int,
            let unread = dict["unread"] as? Bool,
            let current_users = dict["current_users"] as? Int,
            let max_online = dict["max_online"] as? Int,
            let score_level = dict["score_level"] as? Int,
            let total = dict["total"] as? Int,
            let position = dict["position"] as? Int,
            let last_post = dict["last_post"] as? Int,
            let manager = dict["manager"] as? String,
            let type = dict["type"] as? String,
            let flag = dict["flag"] as? Int,
            let bid = dict["bid"] as? Int,
            let max_timeInterval = dict["max_time"] as? Double,
            let id = dict["id"] as? String,
            let name = dict["name"] as? String,
            let score = dict["score"] as? Int,
            let group = dict["group"] as? Int
        {
            var section: Int = 0
            if let sectionInt = dict["section"] as? Int {
                section = sectionInt
            } else if let sectionStr = dict["section"] as? String {
                section = Int(sectionStr) ?? 10 // 10 means "A", aborted section
            }
            let max_time = Date(timeIntervalSince1970: max_timeInterval)
            return SMBoard(bid: bid, boardID: id, level: level, unread: unread, currentUsers: current_users, maxOnline: max_online, scoreLevel: score_level, section: section, total: total, position: position, lastPost: last_post, manager: manager, type: type, flag: flag, maxTime: max_time, name: name, score: score, group: group)
        }
        return nil
    }

    private func userFromDictionary(dict:[String:Any]) -> SMUser? {
        if
            let title = dict["title"] as? String,
            let level = dict["level"] as? Int,
            let logins = dict["logins"] as? Int,
            let first_login_timeInterval = dict["first_login"] as? Double,
            let last_login_timeInterval = dict["last_login"] as? Double,
            let age = dict["age"] as? Int,
            let uid = dict["uid"] as? Int,
            let life = dict["life"] as? String,
            let id = dict["id"] as? String,
            let faceurl = dict["faceurl"] as? String,
            let nick = dict["nick"] as? String,
            let gender = dict["gender"] as? Int,
            let score = dict["score"] as? Int,
            let posts = dict["posts"] as? Int
        {
            let first_login = Date(timeIntervalSince1970: first_login_timeInterval)
            let last_login = Date(timeIntervalSince1970: last_login_timeInterval)
            return SMUser(title: title, level: level, loginCount: logins, firstLoginTime: first_login, age: age, lastLoginTime: last_login, uid: uid, life: life, id: id, gender: gender, score: score, posts: posts, faceURL: faceurl, nick: nick)
        }
        return nil
    }

    private func memberFromDictionary(dict:[String:Any]) -> SMMember? {
        if
            let rawBoard = dict["board"] as? [String:Any],
            let board = boardFromDictionary(dict: rawBoard),
            let board_id = dict["board_id"] as? String,
            let flag = dict["flag"] as? Int,
            let score = dict["score"] as? Int,
            let status = dict["status"] as? Int,
            let timeInterval = dict["time"] as? Double,
            let title = dict["title"] as? String,
            let user_id = dict["user_id"] as? String

        {
            let time = Date(timeIntervalSince1970: timeInterval)
            return SMMember(board: board, boardID: board_id, flag: flag, score: score, status: status, time: time, title: title, userID: user_id)
        }
        return nil
    }

    private func cleanedString(from string: String) -> String {
        // 去除头尾多余的空格和回车
        var lines = string.trimmingCharacters(in: .whitespacesAndNewlines)
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
        if !setting.showSignature {
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
        let pictRE = try! NSRegularExpression(pattern: "\\[upload=(\\d){1,2}\\].*?\\[/upload\\]")
        lines = lines.map { line in
            var cleaned = ansiRE.stringByReplacingMatches(in: line, range: NSMakeRange(0, line.count), withTemplate: "")
            cleaned = pictRE.stringByReplacingMatches(in: cleaned, range: NSMakeRange(0, cleaned.count), withTemplate: "")
            return cleaned
        }
        // 过滤掉部分未过滤的来源信息
        lines = lines.filter { !$0.contains("※ 来源:·") && !$0.contains("※ 修改:·") }
        return lines.joined(separator: "\n")
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
