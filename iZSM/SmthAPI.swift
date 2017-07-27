//
//  SmthAPI.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/5.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import Foundation
import SVProgressHUD

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

    func displayErrorIfNeeded() {
        if errorCode != 0 {
            var errorMsg: String = "未知错误"
            if errorCode == -1 {
                errorMsg = "网络错误"
            } else if errorCode == 10014 {
                errorMsg = "token失效，需要重新登录"
            } else if errorCode == 10417 {
                errorMsg = "您还没有驻版"
            } else if let errorDesc = errorDescription, !errorDesc.isEmpty {
                errorMsg = errorDesc
            } else if errorCode < 0 {
                errorMsg = "服务器错误"
            } else if errorCode < 11000 {
                errorMsg = "系统错误"
            }
            SVProgressHUD.showInfo(withStatus: errorMsg)
            print("\(errorMsg), error code \(errorCode)")
        }
    }
    
    //MARK: - Up Load Attachments
    //if upload succeed, return attachment array, otherwise, nil
    func uploadAttImage(image: UIImage, index: Int) -> [SMAttachment]? {
        let data = convertedAttData(from: image)
        if let rawAttachments = api.net_AddAttachment(data, "\(index).jpg") as? [[String:Any]] {
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

    //MARK: - Reset API's Status
    // usually you don't wanna call this method directly unless when you have to deal with attachments
    func resetStatus() {
        api.reset_status()
    }

    //MARK: - Thread
    // get the thread count of a board
    func getThreadCountForBoard(boardID: String) -> Int {
        api.reset_status()
        return api.net_GetThreadCnt(boardID)
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
    
    // get thread content in board with article id
    func getThreadContentInBoard(boardID: String, articleID: Int, threadRange: NSRange, replyMode: SortMode) -> [SMArticle]? {
        api.reset_status()
        var articleList = [SMArticle]()
        let rawResults = api.net_GetThread(boardID, articleID, threadRange.location, threadRange.length, replyMode.rawValue)
        if let results = rawResults as? [[String:Any]] {
            for (index, result) in results.enumerated() {
                if var article = articleFromDictionary(dict: result) {
                    article.floor = threadRange.location + index
                    article.boardID = boardID
                    article.extraConfigure()
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
            var article = articleFromDictionary(dict: rawValue)
        {
            article.boardID = boardID
            article.extraConfigure()
            return article
        }
        return nil
    }

    // post article in board
    // should call reset status before
    func postArticle(title: String, content: String, inBoard boardID: String) -> Int {
        return api.net_PostArticle(boardID, title, content)
    }

    // forward article to user
    func forwardArticle(articleID: Int, inBoard boardID: String, toUser userID: String) -> Int {
        api.reset_status()
        return api.net_ForwardArticle(boardID, articleID, userID)
    }

    // reply article
    // should call reset status before
    func replyArticle(articleID: Int, title: String, content: String, inBoard boardID: String) -> Int {
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
    func addFavorite(boardID: String) {
        api.reset_status()
        api.net_AddFav(boardID)
    }

    // del favorite board
    func deleteFavorite(boardID: String) {
        api.reset_status()
        api.net_DelFav(boardID)
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
            return boardList
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

    private func articleFromDictionary(dict: [String:Any]) -> SMArticle? {
        if
            let id = dict["id"] as? Int,
            let subject = dict["subject"] as? String,
            let rawBody = dict["body"] as? String,
            let author_id = dict["author_id"] as? String,
            let effsize = dict["effsize"] as? Int,
            let flags = dict["flags"] as? String,
            let timeInterval = dict["time"] as? Double
        {
            let body = cleanedStringFrom(string: rawBody)
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
            return SMArticle(id: id, time: time, subject: subject, authorID: author_id, body: body, effsize: effsize, flags: flags, attachments: attachments)
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
            let body = cleanedStringFrom(string: rawBody)
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
            let subject = htmlEntityDecode(string: rawSubject)
            let board_id = htmlDotDecode(string: rawBoard_id)
            let time = Date(timeIntervalSince1970: timeInterval)
            return SMHotThread(subject: subject, authorID: author_id, id: id, time: time, boardID: board_id, count: count)
        }
        return nil
    }

    private func htmlDotDecode(string: String) -> String {
        return string.replacingOccurrences(of: "%2E", with: ".")
    }

    private func htmlEntityDecode(string: String) -> String {
        return string.replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
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

    private func cleanedStringFrom(string: String) -> String {
        // 去除头尾多余的空格和回车
        var content = string.trimmingCharacters(in: .whitespacesAndNewlines)
        // 去除末尾的--
        // 以及多余的空格和回车
        if content.characters.count >= 2 && content.substring(from: content.index(content.endIndex, offsetBy: -2)) == "--" {
            content = content.substring(to: content.index(content.endIndex, offsetBy: -2))
            content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // 除去签名档，可选
        if !setting.showSignature {
            let pattern = "^--$"
            let regularExpression = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
            let range = regularExpression.rangeOfFirstMatch(in: content, range: NSMakeRange(0, content.characters.count))
            if range.location != NSNotFound {
                content = content.substring(to: content.index(content.startIndex, offsetBy: range.location))
                content = content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        // 去除ANSI控制字符
        var pattern = "\\[(\\d{1,2};?)*m|\\[([ABCDsuKH]|2J)(?![a-zA-Z])|\\[\\d{1,2}[ABCD]|\\[\\d{1,2};\\d{1,2}H"
        var regularExpression = try! NSRegularExpression(pattern: pattern)
        content = regularExpression.stringByReplacingMatches(in: content, range: NSMakeRange(0, content.characters.count), withTemplate: "")

        // 去除图片标志[upload=1][/upload]之类
        pattern = "\\[upload=(\\d){1,2}\\]\\[/upload\\]"
        regularExpression = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        content = regularExpression.stringByReplacingMatches(in: content, range: NSMakeRange(0, content.characters.count), withTemplate: "").trimmingCharacters(in: .whitespacesAndNewlines)
        return content as String
    }
    
    private func image(with image: UIImage, scaledTo newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(newSize)
        image.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
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
        var data = UIImageJPEGRepresentation(newImage, compressionQuality)!
        let maxSize = 1 * 1024 * 1024
        while data.count > maxSize && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            data = UIImageJPEGRepresentation(newImage, compressionQuality)!
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
        var data = UIImageJPEGRepresentation(newImage, compressionQuality)!
        let maxSize = 50 * 1024
        while data.count > maxSize && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            data = UIImageJPEGRepresentation(newImage, compressionQuality)!
        }
        return data
    }
}
