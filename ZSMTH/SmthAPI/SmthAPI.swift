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

    private let setting = AppSetting.sharedSetting()

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
            } else if errorCode < 0 {
                errorMsg = "服务器错误"
            } else if errorCode == 10014 {
                errorMsg = "token失效，需要重新登录"
            } else if errorCode < 11000 {
                errorMsg = "系统错误"
            } else if let errorDesc = errorDescription where !errorDesc.isEmpty {
                errorMsg = errorDesc
            }

            let hud = MBProgressHUD.showHUDAddedTo(UIApplication.sharedApplication().keyWindow, animated: true)
            hud.mode = .Text
            hud.labelText = errorMsg
            hud.hide(true, afterDelay: 1)
        }
    }

    //MARK: - Up Load Attachments
    //if upload succeed, return true, otherwise, false
    func uploadImage(image: UIImage) -> Bool {
        let imageName = "image.jpg"
        let localPath = api.apiGetUserdata_attpost_path(imageName)
        let data = convertedDataFromImage(image)
        data.writeToFile(localPath, atomically: true)
        var error:Int32 = 0
        let ret = apiNetAddAttachment(localPath, &error)
        return (ret == 0)
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
        if let results = rawResults as? [[String:AnyObject]] {
            for result in results {
                if let thread = threadFromDictionary(result) {
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
        if let results = rawResults as? [[String:AnyObject]] {
            for (index, result) in enumerate(results) {
                if var article = articleFromDictionary(result) {
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
        if let results = rawResults as? [[String:AnyObject]] {
            for result in results {
                if let thread = threadFromDictionary(result) {
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
        if let rawValue = api.net_GetArticle(boardID, articleID) as? [String:AnyObject],
            var article = articleFromDictionary(rawValue)
        {
            article.boardID = boardID
            article.extraConfigure()
            return article
        }
        return nil
    }

    // post article in board
    // should call reset status before
    func postArticle(#title: String, content: String, inBoard boardID: String) -> Int {
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


    // MARK: - Mail
    // get sent mail count
    func getMailSentCount() -> Int {
        api.reset_status()
        return Int(api.net_GetMailCountSent())
    }

    // get mail status
    func getMailStatus() -> SMMailStatus? {
        api.reset_status()
        if let
            rawValue = api.net_GetMailCount() as? [String:AnyObject],
            is_full = (rawValue["is_full"] as? NSNumber)?.boolValue,
            error_description = rawValue["error_description"] as? String,
            total_count = (rawValue["total_count"] as? NSNumber)?.integerValue,
            error = (rawValue["error"] as? NSNumber)?.integerValue,
            new_count = (rawValue["new_count"] as? NSNumber)?.integerValue
        {
            return SMMailStatus(isFull: is_full, totalCount: total_count, newCount: new_count, error: error, errorDescription: error_description)
        }
        return nil
    }

    // get sent mail list
    func getMailSentList(#inRange: NSRange) -> [SMMail]? {
        api.reset_status()
        var mailList = [SMMail]()
        if let rawValues = api.net_LoadMailSentList(inRange.location, inRange.length) as? [[String:AnyObject]] {
            for rawValue in rawValues {
                if let mail = mailFromDictionary(rawValue) {
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
    func getMailList(#inRange: NSRange) -> [SMMail]? {
        api.reset_status()
        var mailList = [SMMail]()
        if let rawValues = api.net_LoadMailList(inRange.location, inRange.length) as? [[String:AnyObject]] {
            for rawValue in rawValues {
                if let mail = mailFromDictionary(rawValue) {
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
        if let rawValue = api.net_GetMailSent(Int32(position)) as? [String:AnyObject] {
            return mailFromDictionary(rawValue)
        }
        return nil
    }

    // get mail at position
    func getMailAtPosition(position: Int) -> SMMail? {
        api.reset_status()
        if let rawValue = api.net_GetMail(Int32(position)) as? [String:AnyObject] {
            return mailFromDictionary(rawValue)
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
    func getReferCount(#mode: ReferMode) -> SMReferenceStatus? {
        api.reset_status()
        if let
            dict = api.net_GetReferCount(mode.rawValue) as? [String:AnyObject],
            error_description = dict["error_description"] as? String,
            total_count = (dict["total_count"] as? NSNumber)?.integerValue,
            error = (dict["error"] as? NSNumber)?.integerValue,
            new_count = (dict["new_count"] as? NSNumber)?.integerValue
        {
            return SMReferenceStatus(totalCount: total_count, newCount: new_count, error: error, errorDescription: error_description)
        }
        return nil
    }

    // get reference list
    func getReferList(#mode: ReferMode, inRange: NSRange) -> [SMReference]? {
        api.reset_status()
        var referList = [SMReference]()
        if let references = api.net_LoadRefer(mode.rawValue, inRange.location, inRange.length) as? [[String:AnyObject]] {
            for refer in references {
                if let refer = referenceFromDictionary(refer) {
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
    func setReferRead(#mode: ReferMode, atPosition: Int) -> Int {
        api.reset_status()
        return Int(api.net_SetReferRead(mode.rawValue, Int32(atPosition)))
    }

    // MARK: - Favorite
    // get favorite board list
    func getFavBoardList(group: Int) -> [SMBoard]? {
        api.reset_status()
        var boardList = [SMBoard]()
        if let rawList = api.net_LoadFavorites(group) as? [[String:AnyObject]] {
            for rawBoard in rawList {
                if let board = boardFromDictionary(rawBoard) {
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
        if let rawList = api.net_LoadBoards(group) as? [[String:AnyObject]] {
            for rawBoard in rawList {
                if let board = boardFromDictionary(rawBoard) {
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
        if let rawList = api.net_ReadSection(section, group) as? [[String:AnyObject]] {
            for rawBoard in rawList {
                if let board = boardFromDictionary(rawBoard) {
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
        if let rawList = api.net_QueryBoard(query) as? [[String:AnyObject]] {
            for rawBoard in rawList {
                if let board = boardFromDictionary(rawBoard) {
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
        if let rawList = api.net_LoadSection() as? [[String:AnyObject]] {
            for raw in rawList {
                if let
                    code = raw["code"] as? String,
                    desc = raw["desc"] as? String,
                    name = raw["name"] as? String,
                    id = (raw["id"] as? NSNumber)?.integerValue
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
        if let rawThreads = api.net_LoadSectionHot(section) as? [[String: AnyObject]] {
            for rawThread in rawThreads {
                if let hotThread = hotThreadFromDictionary(rawThread) {
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
    func getUserInfo(#userID: String) -> SMUser? {
        api.reset_status()
        if let rawData = api.net_QueryUser(userID) as? [String:AnyObject] {
            return userFromDictionary(rawData)
        }
        return nil
    }

    // get user friend list
    func getUserFriendList(#userID: String) -> [String]? {
        api.reset_status()
        var friendList = [String]()
        if let rawList = api.net_LoadUserAllFriends(userID) as? [[String:AnyObject]] {
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
    func getFriendListRefreshStamp(#userID: String) -> Int {
        api.reset_status()
        return Int(api.net_LoadUserFriendsTS(userID))
    }

    // add friend
    func addFriend(#friendID: String) -> Int {
        api.reset_status()
        return Int(api.net_AddUserFriend(friendID))
    }

    // delete friend
    func delFriend(#friendID: String) -> Int {
        api.reset_status()
        return Int(api.net_DelUserFriend(friendID))
    }

    // modify user face image
    func modifyFaceImage(imageName: String) -> SMUser? {
        api.reset_status()
        if let raw = api.net_modifyFace(imageName) as? [String:AnyObject] {
            return userFromDictionary(raw)
        }
        return nil
    }

    // login to the bbs
    func loginBBS(#username: String, password: String) -> Int {
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
        if let rawList = api.net_LoadMember(userID, 0, 100) as? [[String:AnyObject]] {
            for raw in rawList {
                if let member = memberFromDictionary(raw) {
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
    private func threadFromDictionary(dict: [String:AnyObject]) -> SMThread? {
        if let
            id = (dict["id"] as? NSNumber)?.integerValue,
            count = (dict["count"] as? NSNumber)?.integerValue,
            last_reply_id = (dict["last_reply_id"] as? NSNumber)?.integerValue,

            subject = dict["subject"] as? String,
            author_id = dict["author_id"] as? String,
            board_id = dict["board_id"] as? String,
            flags = dict["flags"] as? String,
            last_user_id = dict["last_user_id"] as? String,
            board_name = dict["board_name"] as? String,

            timeInterval = (dict["time"] as? NSNumber)?.doubleValue,
            lastTimeInterval = (dict["last_time"] as? NSNumber)?.doubleValue

        {
            let time = NSDate(timeIntervalSince1970: timeInterval)
            let last_time = NSDate(timeIntervalSince1970: lastTimeInterval)

            return SMThread(id: id, time: time, subject: subject, authorID: author_id, lastReplyAuthorID: last_user_id, lastReplyThreadID: last_reply_id, boardID: board_id, boardName: board_name, flags: flags, count: count, lastReplyTime: last_time)
        }
        return nil
    }

    private func articleFromDictionary(dict: [String:AnyObject]) -> SMArticle? {
        if let
            id = (dict["id"] as? NSNumber)?.integerValue,
            subject = dict["subject"] as? String,
            rawBody = dict["body"] as? String,
            author_id = dict["author_id"] as? String,
            effsize = (dict["effsize"] as? NSNumber)?.integerValue,
            flags = dict["flags"] as? String,
            timeInterval = (dict["time"] as? NSNumber)?.doubleValue
        {
            let body = cleanedStringFrom(string: rawBody)
            let time = NSDate(timeIntervalSince1970: timeInterval)
            var attachments = [SMAttachment]()
            if let rawAttachments = dict["attachment_list"] as? [[String:AnyObject]] {
                for rawAttachment in rawAttachments {
                    if let
                        name = rawAttachment["name"] as? String,
                        pos = (rawAttachment["pos"] as? NSNumber)?.integerValue,
                        size = (rawAttachment["size"] as? NSNumber)?.integerValue
                    {
                        attachments.append(SMAttachment(name: name, pos: pos, size: size))
                    }
                }
            }
            return SMArticle(id: id, time: time, subject: subject, authorID: author_id, body: body, effsize: effsize, flags: flags, attachments: attachments)
        }
        return nil
    }

    private func mailFromDictionary(dict: [String:AnyObject]) -> SMMail? {
        if let
            author_id = dict["author_id"] as? String,
            rawBody = dict["body"] as? String,
            flags = dict["flags"] as? String,
            subject = dict["subject"] as? String,
            timeInterval = (dict["time"] as? NSNumber)?.doubleValue
        {
            let time = NSDate(timeIntervalSince1970: timeInterval)
            var position = 0
            if let rawPosition = dict["position"] as? NSNumber {
                position = rawPosition.integerValue
            } else if let rawPosition = dict["position"] as? String {
                position = rawPosition.toInt() ?? 0
            }
            let body = cleanedStringFrom(string: rawBody)
            var attachments = [SMAttachment]()
            if let rawAttachments = dict["attachment_list"] as? [[String:AnyObject]] {
                for rawAttachment in rawAttachments {
                    if let
                        name = rawAttachment["name"] as? String,
                        pos = (rawAttachment["pos"] as? NSNumber)?.integerValue,
                        size = (rawAttachment["size"] as? NSNumber)?.integerValue
                    {
                        attachments.append(SMAttachment(name: name, pos: pos, size: size))
                    }
                }
            }
            return SMMail(subject: subject, body: body, authorID: author_id, position: position, time: time, flags: flags, attachments: attachments)

        }
        return nil
    }

    private func referenceFromDictionary(dict: [String:AnyObject]) -> SMReference? {
        if let
            subject = dict["subject"] as? String,
            flag = (dict["flag"] as? NSNumber)?.integerValue,
            re_id = (dict["re_id"] as? NSNumber)?.integerValue,
            rawMode = (dict["mode"] as? NSNumber)?.intValue,
            mode = SmthAPI.ReferMode(rawValue: rawMode),
            id = (dict["id"] as? NSNumber)?.integerValue,
            board_id = dict["board_id"] as? String,
            user_id = dict["user_id"] as? String,
            group_id = (dict["group_id"] as? NSNumber)?.integerValue,
            timeInterval = (dict["time"] as? NSNumber)?.doubleValue
        {
            let time = NSDate(timeIntervalSince1970: timeInterval)
            var position = 0
            if let rawPosition = dict["position"] as? NSNumber {
                position = rawPosition.integerValue
            } else if let rawPosition = dict["position"] as? String {
                position = rawPosition.toInt() ?? 0
            }
            return SMReference(subject: subject, flag: flag, replyID: re_id, mode: mode, id: id, boardID: board_id, time: time, userID: user_id, groupID: group_id, position: position)
        }
        return nil
    }

    private func hotThreadFromDictionary(dict: [String:AnyObject]) -> SMHotThread? {
        if let
            rawSubject = dict["subject"] as? String,
            author_id = dict["author_id"] as? String,
            rawBoard_id = dict["board"] as? String,
            timeInterval = (dict["time"] as? NSString)?.doubleValue,
            count = (dict["count"] as? NSString)?.integerValue,
            id = (dict["id"] as? NSString)?.integerValue
        {
            let subject = htmlEntityDecode(rawSubject)
            let board_id = htmlDotDecode(rawBoard_id)
            let time = NSDate(timeIntervalSince1970: timeInterval)
            return SMHotThread(subject: subject, authorID: author_id, id: id, time: time, boardID: board_id, count: count)
        }
        return nil
    }

    private func htmlDotDecode(string: String) -> String {
        return string.stringByReplacingOccurrencesOfString("%2E", withString: ".")
    }

    private func htmlEntityDecode(string: String) -> String {
        return string.stringByReplacingOccurrencesOfString("&quot;", withString: "\"")
            .stringByReplacingOccurrencesOfString("&apos;", withString: "'")
            .stringByReplacingOccurrencesOfString("&amp;", withString: "&")
            .stringByReplacingOccurrencesOfString("&lt;", withString: "<")
            .stringByReplacingOccurrencesOfString("&gt;", withString: ">")
    }

    private func boardFromDictionary(dict: [String:AnyObject]) -> SMBoard? {
        if let
            level = (dict["level"] as? NSNumber)?.integerValue,
            unread = (dict["unread"] as? NSNumber)?.boolValue,
            current_users = (dict["current_users"] as? NSNumber)?.integerValue,
            max_online = (dict["max_online"] as? NSNumber)?.integerValue,
            score_level = (dict["score_level"] as? NSNumber)?.integerValue,
            total = (dict["total"] as? NSNumber)?.integerValue,
            position = (dict["position"] as? NSNumber)?.integerValue,
            last_post = (dict["last_post"] as? NSNumber)?.integerValue,
            manager = dict["manager"] as? String,
            type = dict["type"] as? String,
            flag = (dict["flag"] as? NSNumber)?.integerValue,
            bid = (dict["bid"] as? NSNumber)?.integerValue,
            max_timeInterval = (dict["max_time"] as? NSNumber)?.doubleValue,
            id = dict["id"] as? String,
            name = dict["name"] as? String,
            score = (dict["score"] as? NSNumber)?.integerValue,
            group = (dict["group"] as? NSNumber)?.integerValue
        {
            var section: Int = 0
            if let sectionInt = dict["section"] as? NSNumber {
                section = sectionInt.integerValue
            } else if let sectionStr = dict["section"] as? String {
                section = sectionStr.toInt() ?? 10 // 10 means "A", aborted section
            }
            let max_time = NSDate(timeIntervalSince1970: max_timeInterval)
            return SMBoard(bid: bid, boardID: id, level: level, unread: unread, currentUsers: current_users, maxOnline: max_online, scoreLevel: score_level, section: section, total: total, position: position, lastPost: last_post, manager: manager, type: type, flag: flag, maxTime: max_time, name: name, score: score, group: group)
        }
        return nil
    }

    private func userFromDictionary(dict:[String:AnyObject]) -> SMUser? {
        if let
            title = dict["title"] as? String,
            level = (dict["level"] as? NSNumber)?.integerValue,
            logins = (dict["logins"] as? NSNumber)?.integerValue,
            first_login_timeInterval = (dict["first_login"] as? NSNumber)?.doubleValue,
            last_login_timeInterval = (dict["last_login"] as? NSNumber)?.doubleValue,
            age = (dict["age"] as? NSNumber)?.integerValue,
            uid = (dict["uid"] as? NSNumber)?.integerValue,
            life = dict["life"] as? String,
            id = dict["id"] as? String,
            faceurl = dict["faceurl"] as? String,
            nick = dict["nick"] as? String,
            gender = (dict["gender"] as? NSNumber)?.integerValue,
            score = (dict["score"] as? NSNumber)?.integerValue,
            posts = (dict["posts"] as? NSNumber)?.integerValue
        {
            let first_login = NSDate(timeIntervalSince1970: first_login_timeInterval)
            let last_login = NSDate(timeIntervalSince1970: last_login_timeInterval)
            return SMUser(title: title, level: level, loginCount: logins, firstLoginTime: first_login, age: age, lastLoginTime: last_login, uid: uid, life: life, id: id, gender: gender, score: score, posts: posts, faceURL: faceurl, nick: nick)
        }
        return nil
    }

    private func memberFromDictionary(dict:[String:AnyObject]) -> SMMember? {
        if let
            rawBoard = dict["board"] as? [String:AnyObject],
            board = boardFromDictionary(rawBoard),
            board_id = dict["board_id"] as? String,
            flag = (dict["flag"] as? NSNumber)?.integerValue,
            score = (dict["score"] as? NSNumber)?.integerValue,
            status = (dict["status"] as? NSNumber)?.integerValue,
            timeInterval = (dict["time"] as? NSNumber)?.doubleValue,
            title = dict["title"] as? String,
            user_id = dict["user_id"] as? String

        {
            let time = NSDate(timeIntervalSince1970: timeInterval)
            return SMMember(board: board, boardID: board_id, flag: flag, score: score, status: status, time: time, title: title, userID: user_id)
        }
        return nil
    }

    private func cleanedStringFrom(#string: String) -> String {
        var content = string as NSString
        // 去除头尾多余的空格和回车
        content = content.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        // 去除末尾的--
        // 以及多余的空格和回车
        if content.length >= 2 && content.substringFromIndex(content.length-2) == "--" {
            content = content.substringToIndex(content.length-2)
            content = content.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        }
        // 除去签名档，可选
        if !setting.showSignature {
            let pattern = "^--$"
            let regularExpression = NSRegularExpression(pattern: pattern, options: .AnchorsMatchLines, error: nil)!
            let range = regularExpression.rangeOfFirstMatchInString(content as String, options: .allZeros, range: NSMakeRange(0, content.length))
            if range.location != NSNotFound {
                content = content.substringToIndex(range.location)
                content = content.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            }
        }
        // 去除ANSI控制字符
        var pattern = "\\[((\\d){1,2};?)*[mB]"
        var regularExpression = NSRegularExpression(pattern: pattern, options: .allZeros, error: nil)!
        content = regularExpression.stringByReplacingMatchesInString(content as String, options: .allZeros, range: NSMakeRange(0, content.length), withTemplate: "")

        // 去除图片标志[upload=1][/upload]之类
        pattern = "\\[upload=(\\d){1,2}\\]\\[/upload\\]"
        regularExpression = NSRegularExpression(pattern: pattern, options: .CaseInsensitive, error: nil)!
        content = regularExpression.stringByReplacingMatchesInString(content as String, options: .allZeros, range: NSMakeRange(0, content.length), withTemplate: "")
        return content as String
    }

    private func resizedImageFromImage(image: UIImage) -> UIImage {
        let width: CGFloat = 1280
        let currentWidth = image.size.width
        if currentWidth <= width {
            return image
        }
        let height = image.size.height * width / currentWidth
        let newImageSize = CGSize(width: width, height: height)
        UIGraphicsBeginImageContext(newImageSize)
        image.drawInRect(CGRect(origin: CGPointZero, size: newImageSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        return newImage
    }

    private func convertedDataFromImage(image: UIImage) -> NSData {
        let newImage = resizedImageFromImage(image)
        var compressionQuality: CGFloat = 1
        var data = UIImageJPEGRepresentation(newImage, compressionQuality)

        let maxSize = 1 * 1024 * 1024
        while data.length > maxSize && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            data = UIImageJPEGRepresentation(newImage, compressionQuality)
        }
        return data
    }

}
