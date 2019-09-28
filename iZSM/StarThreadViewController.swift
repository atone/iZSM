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
        request.sortDescriptors = [NSSortDescriptor(key: "createTime", ascending: false)]
        fetchedResultsController = NSFetchedResultsController<StarThread>(fetchRequest: request, managedObjectContext: container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        try? fetchedResultsController?.performFetch()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let object = fetchedResultsController?.object(at: indexPath) else { return }
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kCellIdentifier, for: indexPath) as! StarThreadViewCell
        if let object = fetchedResultsController?.object(at: indexPath) {
            cell.set(title: object.articleTitle, boardID: object.boardID, authorID: object.authorID, comment: object.comment)
        } else {
            cell.set(title: nil, boardID: nil, authorID: nil, comment: nil)
        }
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

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
