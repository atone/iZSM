//
//  ArticleReadStatus+CoreDataClass.swift
//  iZSM
//
//  Created by Naitong Yu on 2019/9/28.
//  Copyright © 2019 Naitong Yu. All rights reserved.
//
//

import Foundation
import CoreData

@objc(ArticleReadStatus)
public class ArticleReadStatus: NSManagedObject {

}

extension ArticleReadStatus {
    class func saveStatus(section: Int, row: Int, boardID: String, articleID: Int) {
        let setting = AppSetting.shared
        if !setting.rememberLast {
            return
        }
        let container = CoreDataHelper.shared.persistentContainer
        container.performBackgroundTask { context in
            let request: NSFetchRequest<ArticleReadStatus> = ArticleReadStatus.fetchRequest()
            request.predicate = NSPredicate(format: "boardID == '\(boardID)' AND articleID == \(articleID) AND userID == '\(setting.username!.lowercased())' AND sortMode == \(setting.sortMode.rawValue)")
            request.fetchLimit = 1
            do {
                let results = try context.fetch(request)
                let status = results.first ?? ArticleReadStatus(context: context)
                status.boardID = boardID
                status.articleID = Int64(articleID)
                status.userID = setting.username!.lowercased()
                status.sortMode = Int64(setting.sortMode.rawValue)
                status.section = Int64(section)
                status.row = Int64(row)
                try context.save()
                dPrint("saved ArticleReadStatus(section:\(status.section), row:\(status.row), boardID:\(status.boardID!), articleID:\(status.articleID), userID:\(status.userID!), sortMode:\(status.sortMode))")
            } catch {
                dPrint("ERROR in saveStatus() - \(error.localizedDescription)")
            }
        }
    }
    
    class func getStatus(boardID: String, articleID: Int) -> (section: Int, row: Int)? {
        let setting = AppSetting.shared
        if !setting.rememberLast {
            return nil
        }
        let context = CoreDataHelper.shared.persistentContainer.viewContext
        let request: NSFetchRequest<ArticleReadStatus> = ArticleReadStatus.fetchRequest()
        request.predicate = NSPredicate(format: "boardID == '\(boardID)' AND articleID == \(articleID) AND userID == '\(setting.username!.lowercased())' AND sortMode == \(setting.sortMode.rawValue)")
        request.fetchLimit = 1
        do {
            let results = try context.fetch(request)
            if let status = results.first {
                return (section: Int(status.section), row: Int(status.row))
            }
        } catch {
            dPrint("ERROR in getStatus() - \(error.localizedDescription)")
        }
        return nil
    }
}
