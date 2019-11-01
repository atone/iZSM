//
//  StarThread+CoreDataClass.swift
//  iZSM
//
//  Created by Naitong Yu on 2019/9/28.
//  Copyright © 2019 Naitong Yu. All rights reserved.
//
//

import Foundation
import CoreData
import SmthConnection

@objc(StarThread)
public class StarThread: NSManagedObject {

}

extension StarThread {
    class func updateInfo(articleID: Int, boardID: String, comment: String? = nil, callback: ((_ success: Bool) -> Void)? = nil) {
        guard let userID = AppSetting.shared.username?.lowercased() else { return }
        let container = CoreDataHelper.shared.persistentContainer
        container.performBackgroundTask { context in
            if let article = try? SmthAPI.shared.getArticle(articleID, in: boardID) {
                let request: NSFetchRequest<StarThread> = StarThread.fetchRequest()
                request.predicate = NSPredicate(format: "articleID == \(articleID) AND boardID == '\(boardID)' AND userID == '\(userID)'")
                request.fetchLimit = 1
                do {
                    if let thread = try context.fetch(request).first {
                        // only update title and comment
                        thread.articleTitle = article.subject
                        thread.comment = comment
                    } else {
                        let thread = StarThread(context: context)
                        thread.accessTime = Date()
                        thread.articleID = Int64(articleID)
                        thread.articleTitle = article.subject
                        thread.authorID = article.authorID
                        thread.boardID = boardID
                        thread.comment = comment
                        thread.createTime = Date()
                        thread.postTime = article.time
                        thread.userID = userID
                    }
                    try context.save()
                    callback?(true)
                } catch {
                    let error = error as NSError
                    dPrint(error.userInfo)
                    callback?(false)
                }
                
            } else {
                callback?(false)
            }
        }
    }
}
