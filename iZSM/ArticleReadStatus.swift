//
//  ArticleReadStatus.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/7.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import RealmSwift

class ArticleReadStatus: Object {
    dynamic var section: Int = 0
    dynamic var row: Int = 0
    dynamic var boardID: String = ""
    dynamic var articleID: Int = 0
}

class ArticleReadStatusUtil {
    class func saveStatus(section: Int, row: Int, boardID: String, articleID: Int) {
        if !AppSetting.shared.rememberLast {
            return
        }
        DispatchQueue.global().async {
            autoreleasepool {
                let realm = try! Realm()
                let results = realm.objects(ArticleReadStatus.self)
                    .filter("boardID == '\(boardID)' AND articleID == \(articleID)")
                if results.count == 0 {
                    let status = ArticleReadStatus()
                    status.boardID = boardID
                    status.articleID = articleID
                    status.section = section
                    status.row = row
                    try! realm.write {
                        realm.add(status)
                    }
                    dPrint("add new status: \(status)")
                } else {
                    let status = results.first!
                    try! realm.write {
                        status.section = section
                        status.row = row
                    }
                    dPrint("update \(results.count) status: \(status)")
                }
            }
        }
    }
    
    class func getStatus(boardID: String, articleID: Int) -> (section: Int, row: Int)? {
        if !AppSetting.shared.rememberLast {
            return nil
        }
        let realm = try! Realm()
        let results = realm.objects(ArticleReadStatus.self)
            .filter("boardID == '\(boardID)' AND articleID == \(articleID)")
        if results.count > 0 {
            let status = results.first!
            return (section: status.section, row: status.row)
        } else {
            return nil
        }
    }
}
