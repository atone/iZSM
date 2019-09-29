//
//  StarThreadViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2019/9/28.
//  Copyright © 2019 Naitong Yu. All rights reserved.
//

import UIKit
import CoreData

class StarThreadViewController: NTTableViewController {
    
    let kCellIdentifier = "StarThreadViewCell"
    let container = CoreDataHelper.shared.persistentContainer
    
    private var indexMap = [String : IndexPath]()
    
    var fetchedResultsController: NSFetchedResultsController<StarThread>?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = editButtonItem
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
        tableView.register(StarThreadViewCell.self, forCellReuseIdentifier: kCellIdentifier)
        
        title = "文章收藏"
        
        let request: NSFetchRequest<StarThread> = StarThread.fetchRequest()
        let userID = AppSetting.shared.username!.lowercased()
        request.predicate = NSPredicate(format: "userID == '\(userID)'")
        request.sortDescriptors = [NSSortDescriptor(key: "createTime", ascending: false)]
        fetchedResultsController = NSFetchedResultsController<StarThread>(fetchRequest: request, managedObjectContext: container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController?.delegate = self
        try? fetchedResultsController?.performFetch()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let object = fetchedResultsController?.object(at: indexPath) else { return }
        guard let context = fetchedResultsController?.managedObjectContext else { return }
        object.accessTime = Date()
        try? context.save()
        let acvc = ArticleContentViewController()
        acvc.articleID = Int(object.articleID)
        acvc.boardID = object.boardID
        acvc.fromStar = true
        acvc.title = object.articleTitle
        acvc.hidesBottomBarWhenPushed = true
        show(acvc, sender: self)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if let frc = fetchedResultsController {
            return frc.sections!.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections {
            return sections[section].numberOfObjects
        }
        return 0
    }
    
    func configure(_ cell: UITableViewCell, at indexPath: IndexPath) {
        let cell = cell as! StarThreadViewCell
        let object = fetchedResultsController?.object(at: indexPath)
        cell.configure(with: object, tableView: tableView)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kCellIdentifier, for: indexPath)
        configure(cell, at: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sectionInfo = fetchedResultsController?.sections?[section] {
            return sectionInfo.name
        }
        return nil
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return fetchedResultsController?.sectionIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if let result = fetchedResultsController?.section(forSectionIndexTitle: title, at: index) {
            return result
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let object = fetchedResultsController?.object(at: indexPath), let context = fetchedResultsController?.managedObjectContext {
                context.delete(object)
                try? context.save()
            }
        }
    }
}

extension StarThreadViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        case .update:
            if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) {
                configure(cell, at: indexPath)
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
        @unknown default:
            break
        }
    }
}

extension StarThreadViewController {
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
        guard let frc = self.fetchedResultsController else { return nil }
        let thread = frc.object(at: indexPath)
        guard let boardID = thread.boardID, let articleTitle = thread.articleTitle else { return nil }
        let identifier = NSUUID().uuidString
        indexMap[identifier] = indexPath
        let urlString: String
        switch AppSetting.shared.displayMode {
        case .nForum:
            urlString = "https://www.newsmth.net/nForum/#!article/\(boardID)/\(thread.articleID)"
        case .www2:
            urlString = "https://www.newsmth.net/bbstcon.php?board=\(boardID)&gid=\(thread.articleID)"
        case .mobile:
            urlString = "https://m.newsmth.net/article/\(boardID)/\(thread.articleID)"
        }
        let preview: UIContextMenuContentPreviewProvider = { [unowned self] in
            self.getViewController(with: thread)
        }
        let actions: UIContextMenuActionProvider = { [unowned self] seggestedActions in
            let openAction = UIAction(title: "浏览网页版", image: UIImage(systemName: "safari")) { [unowned self] action in
                let webViewController = NTSafariViewController(url: URL(string: urlString)!)
                self.present(webViewController, animated: true)
            }
            let shareAction = UIAction(title: "分享本帖", image: UIImage(systemName: "square.and.arrow.up")) { [unowned self] action in
                let title = "水木\(boardID)版：【\(articleTitle)】"
                let url = URL(string: urlString)!
                let activityViewController = UIActivityViewController(activityItems: [title, url],
                                                                      applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = cell
                activityViewController.popoverPresentationController?.sourceRect = cell.bounds
                self.present(activityViewController, animated: true)
            }
            return UIMenu(title: "", children: [openAction, shareAction])
        }
        return UIContextMenuConfiguration(identifier: identifier as NSString, previewProvider: preview, actionProvider: actions)
    }
    
    override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion { [unowned self] in
            guard let identifier = configuration.identifier as? String else { return }
            guard let indexPath = self.indexMap[identifier] else { return }
            guard let frc = self.fetchedResultsController else { return }
            let thread = frc.object(at: indexPath)
            thread.accessTime = Date()
            try? frc.managedObjectContext.save()
            let acvc = self.getViewController(with: thread)
            self.show(acvc, sender: self)
        }
    }
    
    private func getViewController(with thread: StarThread) -> ArticleContentViewController {
        let acvc = ArticleContentViewController()
        acvc.articleID = Int(thread.articleID)
        acvc.boardID = thread.boardID
        acvc.fromStar = true
        acvc.title = thread.articleTitle
        acvc.hidesBottomBarWhenPushed = true
        return acvc
    }
}
