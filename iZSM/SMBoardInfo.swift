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
    
    dynamic var lastUpdateTime: Date = Date(timeIntervalSince1970: 0)
    dynamic var searchCount: Int = 0
    
    override static func primaryKey() -> String? {
        return "bid"
    }
    
    override static func indexedProperties() -> [String] {
        return ["boardID"]
    }
}

class SMBoardInfoUtil {
    private static var queryingSet = Set<String>()
    private static let lockQueue = DispatchQueue(label: "cn.yunaitong.iZSM.boardLockQueue")
    
    class func querySMBoardInfo(for boardID: String, callback: @escaping (SMBoard?) -> Void) {
        DispatchQueue.global().async {
            autoreleasepool {
                let realm = try! Realm()
                let results = realm.objects(SMBoardInfo.self).filter("boardID == '\(boardID)'")
                // 如果数据库中没有记录，或者记录更新时间在1个月之前，那么就进行查询
                if results.count == 0
                    || results.first!.lastUpdateTime < Date(timeIntervalSinceNow: -60 * 60 * 24 * 30) {
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
                                    if results.count == 0 {
                                        let boardInfo = SMBoardInfo()
                                        updateBoardInfo(boardInfo: boardInfo, with: board, newBoard: true, updateTime: Date())
                                        try! realm.write {
                                            realm.add(boardInfo)
                                        }
                                        dPrint("add board info for \(boardID) success!")
                                    } else {
                                        let boardInfo = results.first!
                                        try! realm.write {
                                            updateBoardInfo(boardInfo: boardInfo, with: board, newBoard: false, updateTime: Date())
                                        }
                                        dPrint("update board info for \(boardID) success!")
                                    }
                                    break
                                }
                            }
                        } else {
                            dPrint("query board info for \(boardID) failure!")
                        }
                    } else {  // 有人查，那就等结果
                        var counter = 0
                        while results.count == 0 && counter < 10 { // 最多等待1s
                            usleep(1000 * 100) // 100ms
                            counter += 1
                            realm.refresh()
                        }
                        if results.count > 0 {
                            let boardInfo = results.first!
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
                } else {
                    let boardInfo = results.first!
                    let board = boardFrom(boardInfo: boardInfo)
                    DispatchQueue.main.async {
                        callback(board)
                    }
                }
            }
        }
    }
    
    private class func updateBoardInfo(boardInfo: SMBoardInfo, with board: SMBoard, newBoard: Bool, updateTime: Date? = nil, searchCount: Int? = nil) {
        if newBoard {
            boardInfo.bid = board.bid  // Primary key can't be changed after an object is inserted
        }
        boardInfo.boardID = board.boardID
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
