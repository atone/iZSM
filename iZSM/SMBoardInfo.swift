//
//  SMBoardInfo.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/10.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import RealmSwift

class SMBoardInfo: Object {
    dynamic var bid: Int = 0
    dynamic var boardID: String = ""
    dynamic var level: Int = 0
    dynamic var unread: Bool = false
    dynamic var currentUsers: Int = 0
    dynamic var maxOnline: Int = 0
    dynamic var scoreLevel: Int = 0
    dynamic var section: Int = 0
    dynamic var total: Int = 0
    dynamic var position: Int = 0
    dynamic var lastPost: Int = 0
    dynamic var manager: String = ""
    dynamic var type: String = ""
    dynamic var flag: Int = 0
    dynamic var maxTime: Date = Date(timeIntervalSince1970: 0)
    dynamic var name: String = ""
    dynamic var score: Int = 0
    dynamic var group: Int = 0
    
    dynamic var lastUpdateTime: Date = Date()
    dynamic var searchCount: Int = 0
    
    override static func primaryKey() -> String? {
        return "boardID"
    }
}

class SMBoardInfoUtil {
    private static var queryingSet = Set<String>()
    private static let lockQueue = DispatchQueue(label: "cn.yunaitong.iZSM.boardLockQueue")
    private static let semaphore = DispatchSemaphore(value: 1)
    
    class func querySMBoardInfo(for boardID: String, callback: @escaping (SMBoard?) -> Void) {
        DispatchQueue.global().async {
            autoreleasepool {
                let realm = try! Realm()
                if let boardInfo = realm.object(ofType: SMBoardInfo.self, forPrimaryKey: boardID),
                    boardInfo.lastUpdateTime >= Date(timeIntervalSinceNow: -60 * 60 * 24 * 30) {
                    let board = boardFrom(boardInfo: boardInfo)
                    DispatchQueue.main.async {
                        callback(board)
                    }
                } else {  // 如果数据库中没有记录，或者记录更新时间在1个月之前，那么就进行查询
                    var shouldMakeQuery: Bool = false
                    lockQueue.sync {
                        if queryingSet.contains(boardID) {
                            shouldMakeQuery = false
                        } else {
                            shouldMakeQuery = true
                            queryingSet.insert(boardID)
                        }
                    }
                    if shouldMakeQuery {
                        let api = SmthAPI()
                        dPrint("start querying info for board \(boardID)...")
                        if let boards = api.queryBoard(query: boardID) {
                            for board in boards {
                                if board.boardID == boardID {
                                    queryingSet.remove(boardID)
                                    DispatchQueue.main.async {
                                        callback(board)
                                    }
                                    if let boardInfo = realm.object(ofType: SMBoardInfo.self, forPrimaryKey: boardID) {
                                        try! realm.write {
                                            updateBoardInfo(boardInfo: boardInfo, with: board, newBoard: false, updateTime: Date())
                                        }
                                        dPrint("update board info for \(boardID) success!")
                                    } else {
                                        let boardInfo = SMBoardInfo()
                                        updateBoardInfo(boardInfo: boardInfo, with: board, newBoard: true, updateTime: Date())
                                        try! realm.write {
                                            realm.add(boardInfo)
                                        }
                                        dPrint("add board info for \(boardID) success!")
                                    }
                                    break
                                }
                            }
                        } else {
                            dPrint("query board info for \(boardID) failure!")
                        }
                    } else {  // 有人查，那就等结果
                        var counter = 0
                        while realm.object(ofType: SMBoardInfo.self, forPrimaryKey: boardID) == nil && counter < 10 { // 最多等待1s
                            usleep(1000 * 100) // 100ms
                            counter += 1
                            realm.refresh()
                        }
                        if let boardInfo = realm.object(ofType: SMBoardInfo.self, forPrimaryKey: boardID) {
                            let board = boardFrom(boardInfo: boardInfo)
                            DispatchQueue.main.async {
                                callback(board)
                            }
                        } else {
                            DispatchQueue.main.async {
                                callback(nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    class func save(boardList: [SMBoard]) {
        DispatchQueue.global().async {
            autoreleasepool {
                semaphore.wait()
                let realm = try! Realm()
                for board in boardList {
                    if board.boardID.isEmpty {
                        continue
                    }
                    if let boardInfo = realm.object(ofType: SMBoardInfo.self, forPrimaryKey: board.boardID) {
                        try! realm.write {
                            updateBoardInfo(boardInfo: boardInfo, with: board, newBoard: false, updateTime: Date())
                        }
                        //dPrint("update board info for \(board.boardID) success!")
                    } else {
                        let boardInfo = SMBoardInfo()
                        updateBoardInfo(boardInfo: boardInfo, with: board, newBoard: true, updateTime: Date())
                        try! realm.write {
                            realm.add(boardInfo)
                        }
                        //dPrint("add board info for \(board.boardID) success!")
                    }
                }
                semaphore.signal()
            }
        }
    }
    
    class func hitSearch(for board: SMBoard) {
        DispatchQueue.global().async {
            autoreleasepool {
                semaphore.wait()
                let realm = try! Realm()
                if let boardInfo = realm.object(ofType: SMBoardInfo.self, forPrimaryKey: board.boardID) {
                    try! realm.write {
                        boardInfo.searchCount += 1
                    }
                    dPrint("search count added for \(board.boardID)")
                } else {
                    dPrint("Error: \(board.boardID) not found!")
                }
                semaphore.signal()
            }
        }
    }
    
    class func clearSearchCount(for board: SMBoard) {
        DispatchQueue.global().async {
            autoreleasepool {
                semaphore.wait()
                let realm = try! Realm()
                if let boardInfo = realm.object(ofType: SMBoardInfo.self, forPrimaryKey: board.boardID) {
                    try! realm.write {
                        boardInfo.searchCount = 0
                    }
                    dPrint("search count set zero for \(board.boardID)")
                } else {
                    dPrint("Error: \(board.boardID) not found!")
                }
                semaphore.signal()
            }
        }
    }
    
    class func topSearchResult() -> [SMBoard]? {
        let realm = try! Realm()
        let results = realm.objects(SMBoardInfo.self).filter("searchCount > 0").sorted(byKeyPath: "searchCount", ascending: false)
        guard results.count > 0 else { return nil }
        var boards = [SMBoard]()
        for i in 0..<min(10, results.count) {
            boards.append(boardFrom(boardInfo: results[i]))
        }
        return boards
    }
    
    private class func updateBoardInfo(boardInfo: SMBoardInfo, with board: SMBoard, newBoard: Bool, updateTime: Date? = nil, searchCount: Int? = nil) {
        if newBoard {
            boardInfo.boardID = board.boardID  // Primary key can't be changed after an object is inserted
        }
        boardInfo.bid = board.bid
        boardInfo.level = board.level
        boardInfo.unread = board.unread
        boardInfo.currentUsers = board.currentUsers
        boardInfo.maxOnline = board.maxOnline
        boardInfo.scoreLevel = board.scoreLevel
        boardInfo.section = board.section
        boardInfo.total = board.total
        boardInfo.position = board.position
        boardInfo.lastPost = board.lastPost
        boardInfo.manager = board.manager
        boardInfo.type = board.type
        boardInfo.flag = board.flag
        boardInfo.maxTime = board.maxTime
        boardInfo.name = board.name
        boardInfo.score = board.score
        boardInfo.group = board.group
        
        if let updateTime = updateTime {
            boardInfo.lastUpdateTime = updateTime
        }
        if let searchCount = searchCount {
            boardInfo.searchCount = searchCount
        }
    }
    
    private class func boardFrom(boardInfo: SMBoardInfo) -> SMBoard {
        return SMBoard(bid: boardInfo.bid,
                       boardID: boardInfo.boardID,
                       level: boardInfo.level,
                       unread: boardInfo.unread,
                       currentUsers: boardInfo.currentUsers,
                       maxOnline: boardInfo.maxOnline,
                       scoreLevel: boardInfo.scoreLevel,
                       section: boardInfo.section,
                       total: boardInfo.total,
                       position: boardInfo.position,
                       lastPost: boardInfo.lastPost,
                       manager: boardInfo.manager,
                       type: boardInfo.type,
                       flag: boardInfo.flag,
                       maxTime: boardInfo.maxTime,
                       name: boardInfo.name,
                       score: boardInfo.score,
                       group: boardInfo.group)
    }
}
