//
//  SMUserInfo.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/8.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import RealmSwift

class SMUserInfo: Object {
    @objc dynamic var title: String = ""
    @objc dynamic var level: Int = 0
    @objc dynamic var loginCount: Int = 0
    @objc dynamic var firstLoginTime: Date = Date(timeIntervalSince1970: 0)
    @objc dynamic var age: Int = 0
    @objc dynamic var lastLoginTime: Date = Date(timeIntervalSince1970: 0)
    @objc dynamic var uid: Int = 0
    @objc dynamic var life: String = ""
    @objc dynamic var id: String = ""
    @objc dynamic var gender: Int = 0
    @objc dynamic var score: Int = 0
    @objc dynamic var posts: Int = 0
    @objc dynamic var faceURL: String = ""
    @objc dynamic var nick: String = ""
    
    @objc dynamic var lastUpdateTime: Date = Date()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class SMUserInfoUtil {
    private static var queryingSet = Set<String>()
    private static let lockQueue = DispatchQueue(label: "cn.yunaitong.iZSM.userLockQueue")
    
    class func updateSMUser(with user:SMUser, callback: @escaping () -> Void) {
        DispatchQueue.global().async {
            autoreleasepool {
                let realm = try! Realm()
                let userInfo = userInfoFrom(user: user, updateTime: Date())
                try! realm.write {
                    realm.add(userInfo, update: .modified)
                }
                dPrint("update user info for \(user.id) success!")
                DispatchQueue.main.async {
                    callback()
                }
            }
        }
    }

    class func querySMUser(for userID: String, forceUpdate: Bool = false, callback: @escaping (SMUser?) -> Void) {
        DispatchQueue.global().async {
            autoreleasepool {
                let realm = try! Realm()
                if let userInfo = realm.object(ofType: SMUserInfo.self, forPrimaryKey: userID),
                    !forceUpdate, userInfo.lastUpdateTime >= Date(timeIntervalSinceNow: -60 * 60) {
                    let user = userFrom(userInfo: userInfo)
                    DispatchQueue.main.async {
                        callback(user)
                    }
                } else {  // 如果数据库中没有记录，或者需要强制更新，或者记录更新时间在1小时之前，那么就进行查询
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
                        dPrint("start querying info for \(userID)...")
                        let user = api.getUserInfo(userID: userID)
                        queryingSet.remove(userID)
                        if let user = user {
                            let userInfo = userInfoFrom(user: user, updateTime: Date())
                            try! realm.write {
                                realm.add(userInfo, update: .modified)
                            }
                            let userID = userInfo.id
                            if let username = AppSetting.shared.username {
                                if username.lowercased() == userID.lowercased() && username != userID {
                                    dPrint("change saved user id from \(username) to \(userID)")
                                    AppSetting.shared.username = userID
                                }
                            }
                            dPrint("write user info for \(userID) success!")
                        } else {
                            dPrint("write user info for \(userID) failure!")
                        }
                        DispatchQueue.main.async {
                            callback(user)
                        }
                    } else {  // 有人查，那就等结果
                        var counter = 0
                        while realm.object(ofType: SMUserInfo.self, forPrimaryKey: userID) == nil && counter < 10 { // 最多等待1s
                            usleep(1000 * 100) // 100ms
                            counter += 1
                            realm.refresh()
                        }
                        if let userInfo = realm.object(ofType: SMUserInfo.self, forPrimaryKey: userID) {
                            dPrint("get user info for \(userID) from other\'s query")
                            let user = userFrom(userInfo: userInfo)
                            DispatchQueue.main.async {
                                callback(user)
                            }
                        } else {
                            dPrint("other\'s query for \(userID) failed, return nil")
                            DispatchQueue.main.async {
                                callback(nil)
                            }
                        }
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
