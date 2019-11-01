//
//  SMBoardInfo+CoreDataClass.swift
//  iZSM
//
//  Created by Naitong Yu on 2019/9/28.
//  Copyright © 2019 Naitong Yu. All rights reserved.
//
//

import Foundation
import CoreData
import SmthConnection

@objc(SMBoardInfo)
public class SMBoardInfo: NSManagedObject {

}

extension SMBoardInfo {
    private static var queryingSet = Set<String>()
    private static let lockQueue = DispatchQueue(label: "cn.yunaitong.iZSM.boardLockQueue")
    
    class func querySMBoardInfo(for boardID: String, callback: @escaping (SMBoard?) -> Void) {
        let container = CoreDataHelper.shared.persistentContainer
        container.performBackgroundTask { context in
            let request: NSFetchRequest<SMBoardInfo> = SMBoardInfo.fetchRequest()
            request.predicate = NSPredicate(format: "boardID == '\(boardID)'")
            request.fetchLimit = 1
            do {
                let results = try context.fetch(request)
                if let boardInfo = results.first, let lastUpdateTime = boardInfo.lastUpdateTime, lastUpdateTime >= Date(timeIntervalSinceNow: -60 * 60 * 24 * 30) {
                    let board = createBoard(from: boardInfo)
                    DispatchQueue.main.async {
                        callback(board)
                    }
                } else { // 如果数据库中没有记录，或者记录更新时间在1个月之前，那么就进行查询
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
                        let api = SmthAPI.shared
                        dPrint("start querying info for board \(boardID)...")
                        var board: SMBoard?
                        if let b = try? api.getBoard(id: boardID) {
                            board = b
                            let results = try context.fetch(request)
                            let boardInfo = results.first ?? SMBoardInfo(context: context)
                            update(boardInfo: boardInfo, with: b)
                            try context.save()
                            dPrint("write board info for \(boardID) success!")
                        } else {
                            dPrint("query board info for \(boardID) failure!")
                        }
                        queryingSet.remove(boardID)
                        DispatchQueue.main.async {
                            callback(board)
                        }
                    } else {  // 有人查，那就等结果
                        var counter = 0
                        while try context.count(for: request) == 0 && counter < 10 { // 最多等待1s
                            usleep(1000 * 100) // 100ms
                            counter += 1
                        }
                        if let boardInfo = try context.fetch(request).first {
                            dPrint("get board info for \(boardID) from other's query")
                            let board = createBoard(from: boardInfo)
                            DispatchQueue.main.async {
                                callback(board)
                            }
                        } else {
                            dPrint("other's query for \(boardID) failed, return nil")
                            DispatchQueue.main.async {
                                callback(nil)
                            }
                        }
                    }
                }
            } catch {
                dPrint("ERROR in querySMBoardInfo(for:callback:) - \(error.localizedDescription)")
            }
        }
    }
    
    class func save(boardList: [SMBoard]) {
        let container = CoreDataHelper.shared.persistentContainer
        container.performBackgroundTask { context in
            do {
                for board in boardList {
                    if board.boardID.isEmpty {
                        continue
                    }
                    let request: NSFetchRequest<SMBoardInfo> = SMBoardInfo.fetchRequest()
                    request.predicate = NSPredicate(format: "boardID == '\(board.boardID)'")
                    request.fetchLimit = 1
                    let results = try context.fetch(request)
                    let boardInfo = results.first ?? SMBoardInfo(context: context)
                    update(boardInfo: boardInfo, with: board)
                }
                try context.save()
            } catch {
                dPrint("ERROR in save(boardList:) - \(error.localizedDescription)")
            }
        }
    }
    
    class func hit(for boardID: String) {
        let container = CoreDataHelper.shared.persistentContainer
        container.performBackgroundTask { context in
            let request: NSFetchRequest<SMBoardInfo> = SMBoardInfo.fetchRequest()
            request.predicate = NSPredicate(format: "boardID == '\(boardID)'")
            request.fetchLimit = 1
            do {
                if let boardInfo = try context.fetch(request).first {
                    boardInfo.searchCount += 1
                    try context.save()
                    dPrint("search count added for \(boardID)")
                } else {
                    dPrint("Error: \(boardID) not found!")
                }
            } catch {
                dPrint("ERROR in hitSearch(for:) - \(error.localizedDescription)")
            }
        }
    }
    
    class func clearHitCount(for boardID: String) {
        let container = CoreDataHelper.shared.persistentContainer
        container.performBackgroundTask { context in
            let request: NSFetchRequest<SMBoardInfo> = SMBoardInfo.fetchRequest()
            request.predicate = NSPredicate(format: "boardID == '\(boardID)'")
            request.fetchLimit = 1
            do {
                if let boardInfo = try context.fetch(request).first {
                    boardInfo.searchCount = 0
                    try context.save()
                    dPrint("search count set zero for \(boardID)")
                } else {
                    dPrint("Error: \(boardID) not found!")
                }
            } catch {
                dPrint("ERROR in hitSearch(for:) - \(error.localizedDescription)")
            }
        }
    }
    
    class func topSearchResult() -> [SMBoard]? {
        let context = CoreDataHelper.shared.persistentContainer.viewContext
        let request: NSFetchRequest<SMBoardInfo> = SMBoardInfo.fetchRequest()
        request.predicate = NSPredicate(format: "searchCount > 0")
        request.sortDescriptors = [NSSortDescriptor(key: "searchCount", ascending: false)]
        do {
            let results = try context.fetch(request)
            guard results.count > 0 else { return nil }
            var boards = [SMBoard]()
            for i in 0..<min(10, results.count) {
                boards.append(createBoard(from: results[i]))
            }
            return boards
        } catch {
            dPrint("ERROR in topSearchResult() - \(error.localizedDescription)")
        }
        return nil
    }
    
    private class func update(boardInfo: SMBoardInfo, with board: SMBoard, updateTime: Date? = nil, searchCount: Int? = nil) {
        boardInfo.bid = Int64(board.bid)
        boardInfo.boardID = board.boardID
        boardInfo.level = Int64(board.level)
        boardInfo.unread = board.unread
        boardInfo.currentUsers = Int64(board.currentUsers)
        boardInfo.maxOnline = Int64(board.maxOnline)
        boardInfo.scoreLevel = Int64(board.scoreLevel)
        boardInfo.section = Int64(board.section)
        boardInfo.total = Int64(board.total)
        boardInfo.position = Int64(board.position)
        boardInfo.lastPost = Int64(board.lastPost)
        boardInfo.manager = board.manager
        boardInfo.type = board.type
        boardInfo.flag = Int64(board.flag)
        boardInfo.maxTime = board.maxTime
        boardInfo.name = board.name
        boardInfo.score = Int64(board.score)
        boardInfo.group = Int64(board.group)
        
        if let updateTime = updateTime {
            boardInfo.lastUpdateTime = updateTime
        } else {
            boardInfo.lastUpdateTime = Date()
        }
        if let searchCount = searchCount {
            boardInfo.searchCount = Int64(searchCount)
        }
    }
    
    private class func createBoard(from boardInfo: SMBoardInfo) -> SMBoard {
        return SMBoard(bid: Int(boardInfo.bid),
                       boardID: boardInfo.boardID!,
                       level: Int(boardInfo.level),
                       unread: boardInfo.unread,
                       currentUsers: Int(boardInfo.currentUsers),
                       maxOnline: Int(boardInfo.maxOnline),
                       scoreLevel: Int(boardInfo.scoreLevel),
                       section: Int(boardInfo.section),
                       total: Int(boardInfo.total),
                       position: Int(boardInfo.position),
                       lastPost: Int(boardInfo.lastPost),
                       manager: boardInfo.manager!,
                       type: boardInfo.type!,
                       flag: Int(boardInfo.flag),
                       maxTime: boardInfo.maxTime!,
                       name: boardInfo.name!,
                       score: Int(boardInfo.score),
                       group: Int(boardInfo.group))
    }
}
