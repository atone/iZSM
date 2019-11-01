//
//  SMUserInfo+CoreDataClass.swift
//  iZSM
//
//  Created by Naitong Yu on 2019/9/28.
//  Copyright © 2019 Naitong Yu. All rights reserved.
//
//

import Foundation
import CoreData
import SmthConnection

@objc(SMUserInfo)
public class SMUserInfo: NSManagedObject {

}

extension SMUserInfo {
    private static var queryingSet = Set<String>()
    private static let lockQueue = DispatchQueue(label: "cn.yunaitong.iZSM.userLockQueue")
    
    class func updateSMUserInfo(with user:SMUser, callback: @escaping () -> Void) {
        let container = CoreDataHelper.shared.persistentContainer
        container.performBackgroundTask { context in
            let request: NSFetchRequest<SMUserInfo> = SMUserInfo.fetchRequest()
            request.predicate = NSPredicate(format: "id == '\(user.id)'")
            request.fetchLimit = 1
            do {
                let results = try context.fetch(request)
                let userInfo = results.first ?? SMUserInfo(context: context)
                update(userInfo: userInfo, with: user, updateTime: Date())
                try context.save()
            } catch {
                dPrint("ERROR in updateSMUserInfo(with:callback:) - \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                callback()
            }
        }
    }

    class func querySMUser(for userID: String, forceUpdate: Bool = false, callback: @escaping (SMUser?) -> Void) {
        let container = CoreDataHelper.shared.persistentContainer
        container.performBackgroundTask { context in
            let request: NSFetchRequest<SMUserInfo> = SMUserInfo.fetchRequest()
            request.predicate = NSPredicate(format: "id == '\(userID)'")
            request.fetchLimit = 1
            do {
                let results = try context.fetch(request)
                if let userInfo = results.first, !forceUpdate, let lastUpdateTime = userInfo.lastUpdateTime, lastUpdateTime >= Date(timeIntervalSinceNow: -60 * 60) {
                    let user = createUser(from: userInfo)
                    DispatchQueue.main.async {
                        callback(user)
                    }
                } else { // 如果数据库中没有记录，或者需要强制更新，或者记录更新时间在1小时之前，那么就进行查询
                    var shouldMakeQuery: Bool = false
                    lockQueue.sync {
                        if queryingSet.contains(userID) {
                            shouldMakeQuery = false
                        } else {
                            shouldMakeQuery = true
                            queryingSet.insert(userID)
                        }
                    }
                    if shouldMakeQuery {
                        let api = SmthAPI.shared
                        dPrint("start querying info for \(userID)...")
                        let user = try? api.queryUser(with: userID)
                        if let user = user {
                            let results = try context.fetch(request)
                            let userInfo = results.first ?? SMUserInfo(context: context)
                            update(userInfo: userInfo, with: user, updateTime: Date())
                            try context.save()
                            let userID = userInfo.id!
                            if let username = AppSetting.shared.username {
                                if username.lowercased() == userID.lowercased() && username != userID {
                                    dPrint("change saved user id from \(username) to \(userID)")
                                    AppSetting.shared.username = userID
                                }
                            }
                            dPrint("write user info for \(userID) success!")
                        } else {
                            dPrint("could not find info for \(userID)")
                        }
                        queryingSet.remove(userID)
                        DispatchQueue.main.async {
                            callback(user)
                        }
                    } else {  // 有人查，那就等结果
                        var counter = 0
                        while try context.count(for: request) == 0 && counter < 10 { // 最多等待1s
                            usleep(1000 * 100) // 100ms
                            counter += 1
                        }
                        if let userInfo = try context.fetch(request).first {
                            dPrint("get user info for \(userID) from other's query")
                            let user = createUser(from: userInfo)
                            DispatchQueue.main.async {
                                callback(user)
                            }
                        } else {
                            dPrint("other's query for \(userID) failed, return nil")
                            DispatchQueue.main.async {
                                callback(nil)
                            }
                        }
                    }
                }
            } catch {
                dPrint("ERROR in querySMUser(for:forceUpdate:callback:) - \(error.localizedDescription)")
            }
        }
    }
    
    private class func createUser(from userInfo: SMUserInfo) -> SMUser {
        return SMUser(title: userInfo.title!,
                      level: Int(userInfo.level),
                      loginCount: Int(userInfo.loginCount),
                      firstLoginTime: userInfo.firstLoginTime!,
                      age: Int(userInfo.age),
                      lastLoginTime: userInfo.lastLoginTime!,
                      uid: Int(userInfo.uid),
                      life: userInfo.life!,
                      id: userInfo.id!,
                      gender: Int(userInfo.gender),
                      score: Int(userInfo.score),
                      posts: Int(userInfo.posts),
                      faceURL: userInfo.faceURL!,
                      nick: userInfo.nick!)
    }
    
    private class func update(userInfo: SMUserInfo, with user: SMUser, updateTime: Date) {
        userInfo.title = user.title
        userInfo.level = Int64(user.level)
        userInfo.loginCount = Int64(user.loginCount)
        userInfo.firstLoginTime = user.firstLoginTime
        userInfo.age = Int64(user.age)
        userInfo.lastLoginTime = user.lastLoginTime
        userInfo.uid = Int64(user.uid)
        userInfo.life = user.life
        userInfo.id = user.id
        userInfo.gender = Int64(user.gender)
        userInfo.score = Int64(user.score)
        userInfo.posts = Int64(user.posts)
        userInfo.faceURL = user.faceURL
        userInfo.nick = user.nick
        userInfo.lastUpdateTime = updateTime
    }
}
