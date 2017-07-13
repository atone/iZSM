//
//  SMUserInfo.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/8.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import RealmSwift

class SMUserInfo: Object {
    dynamic var title: String = ""
    dynamic var level: Int = 0
    dynamic var loginCount: Int = 0
    dynamic var firstLoginTime: Date = Date(timeIntervalSince1970: 0)
    dynamic var age: Int = 0
    dynamic var lastLoginTime: Date = Date(timeIntervalSince1970: 0)
    dynamic var uid: Int = 0
    dynamic var life: String = ""
    dynamic var id: String = ""
    dynamic var gender: Int = 0
    dynamic var score: Int = 0
    dynamic var posts: Int = 0
    dynamic var faceURL: String = ""
    dynamic var nick: String = ""
    dynamic var lastUpdateTime: Date = Date(timeIntervalSince1970: 0)
    
    override static func primaryKey() -> String? {
        return "uid"
    }
    
    override static func indexedProperties() -> [String] {
        return ["id"]
    }
}

class SMUserInfoUtil {
    private static var queryingSet = Set<String>()
    private static let lockQueue = DispatchQueue(label: "cn.yunaitong.iZSM.userLockQueue")

    class func querySMUser(for userID: String, forceUpdate: Bool = false, callback: @escaping (SMUser?) -> Void) {
        DispatchQueue.global().async {
            autoreleasepool {
                let realm = try! Realm()
                let results = realm.objects(SMUserInfo.self).filter("id == '\(userID)'")
                // 如果数据库中没有记录，或者需要强制更新，或者记录更新时间在1小时之前，那么就进行查询
                if results.count == 0 || forceUpdate
                    || results.first!.lastUpdateTime < Date(timeIntervalSinceNow: -60 * 60) {
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
                        let api = SmthAPI()
                        print("start querying info for \(userID)...")
                        let user = api.getUserInfo(userID: userID)
                        queryingSet.remove(userID)
                        if let user = user {
                            let userInfo = userInfoFrom(user: user, updateTime: Date())
                            try! realm.write {
                                realm.add(userInfo, update: true)
                            }
                            let userID = userInfo.id
                            if let username = AppSetting.sharedSetting.username {
                                if username.lowercased() == userID.lowercased() && username != userID {
                                    print("change saved user id from \(username) to \(userID)")
                                    AppSetting.sharedSetting.username = userID
                                }
                            }
                            print("write user info for \(userID) success!")
                        } else {
                            print("write user info for \(userID) failure!")
                        }
                        DispatchQueue.main.async {
                            callback(user)
                        }
                    } else {  // 有人查，那就等结果
                        var counter = 0
                        while results.count == 0 && counter < 10 { // 最多等待1s
                            usleep(1000 * 100) // 100ms
                            counter += 1
                            realm.refresh()
                        }
                        if results.count > 0 {
                            let userInfo = results.first!
                            let user = userFrom(userInfo: userInfo)
                            DispatchQueue.main.async {
                                callback(user)
                            }
                        } else {
                            DispatchQueue.main.async {
                                callback(nil)
                            }
                        }
                    }
                } else {
                    let userInfo = results.first!
                    let user = userFrom(userInfo: userInfo)
                    DispatchQueue.main.async {
                        callback(user)
                    }
                }
            }
        }
    }
    
    private class func userFrom(userInfo: SMUserInfo) -> SMUser {
        return SMUser(title: userInfo.title,
                      level: userInfo.level,
                      loginCount: userInfo.loginCount,
                      firstLoginTime: userInfo.firstLoginTime,
                      age: userInfo.age,
                      lastLoginTime: userInfo.lastLoginTime,
                      uid: userInfo.uid,
                      life: userInfo.life,
                      id: userInfo.id,
                      gender: userInfo.gender,
                      score: userInfo.score,
                      posts: userInfo.posts,
                      faceURL: userInfo.faceURL,
                      nick: userInfo.nick)
    }
    
    private class func userInfoFrom(user: SMUser, updateTime: Date) -> SMUserInfo {
        let userInfo = SMUserInfo()
        userInfo.title = user.title
        userInfo.level = user.level
        userInfo.loginCount = user.loginCount
        userInfo.firstLoginTime = user.firstLoginTime
        userInfo.age = user.age
        userInfo.lastLoginTime = user.lastLoginTime
        userInfo.uid = user.uid
        userInfo.life = user.life
        userInfo.id = user.id
        userInfo.gender = user.gender
        userInfo.score = user.score
        userInfo.posts = user.posts
        userInfo.faceURL = user.faceURL
        userInfo.nick = user.nick
        userInfo.lastUpdateTime = updateTime
        return userInfo
    }
}
