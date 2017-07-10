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
    dynamic var name: String = ""
    dynamic var lastUpdateTime: Date = Date(timeIntervalSince1970: 0)
    
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
    
    class func querySMBoardInfo(for boardID: String, callback: @escaping (SMBoardInfo?) -> Void) {
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
                        print("start querying info for board \(boardID)...")
                        if let boards = api.queryBoard(query: boardID) {
                            for board in boards {
                                if board.boardID == boardID {
                                    queryingSet.remove(boardID)
                                    let boardInfo = boardInfoFrom(board: board, updateTime: Date())
                                    DispatchQueue.main.async {
                                        callback(boardInfo)
                                    }
                                    let boardInfo2 = boardInfoFrom(board: board, updateTime: Date())
                                    try! realm.write {
                                        realm.add(boardInfo2, update: true)
                                    }
                                    print("write board info for \(boardID) success!")
                                    
                                    break
                                }
                            }
                        } else {
                            print("query board info for \(boardID) failure!")
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
                            let boardInfo2 = SMBoardInfo()
                            boardInfo2.bid = boardInfo.bid
                            boardInfo2.boardID = boardInfo.boardID
                            boardInfo2.name = boardInfo.name
                            boardInfo2.lastUpdateTime = boardInfo.lastUpdateTime
                            DispatchQueue.main.async {
                                callback(boardInfo2)
                            }
                        } else {
                            DispatchQueue.main.async {
                                callback(nil)
                            }
                        }
                    }
                } else {
                    let boardInfo = results.first!
                    let boardInfo2 = SMBoardInfo()
                    boardInfo2.bid = boardInfo.bid
                    boardInfo2.boardID = boardInfo.boardID
                    boardInfo2.name = boardInfo.name
                    boardInfo2.lastUpdateTime = boardInfo.lastUpdateTime
                    DispatchQueue.main.async {
                        callback(boardInfo2)
                    }
                }
            }
        }
    }
    
    private class func boardInfoFrom(board: SMBoard, updateTime: Date) -> SMBoardInfo {
        let boardInfo = SMBoardInfo()
        boardInfo.bid = board.bid
        boardInfo.boardID = board.boardID
        boardInfo.name = board.name
        boardInfo.lastUpdateTime = updateTime
        return boardInfo
    }
}
