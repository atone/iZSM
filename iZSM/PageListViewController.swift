//
//  PageListViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/7.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit

class PageListViewController: UITableViewController {
    
    var currentPage: Int = 0
    var totalPage: Int = 0
    weak var delegate: PageListViewControllerDelegate?

    private let kCellIdentifier = "PageListCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if currentPage < totalPage {
            tableView.scrollToRow(at: IndexPath(row: currentPage, section: 0), at: .middle, animated: true)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return totalPage
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        if let newCell = tableView.dequeueReusableCell(withIdentifier: kCellIdentifier) {
            cell = newCell
        } else {
            cell = UITableViewCell(style: .value1, reuseIdentifier: kCellIdentifier)
        }

        cell.textLabel?.text = "第 \(indexPath.row + 1) 页"
        if indexPath.row == currentPage {
            cell.detailTextLabel?.text = "✓"
            cell.detailTextLabel?.textColor = UIColor(named: "SmthColor")
        } else {
            cell.detailTextLabel?.text = nil
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentPage = indexPath.row
        tableView.reloadData()
        delegate?.pageListViewController(self, currentPageChangedTo: currentPage)
    }
}

protocol PageListViewControllerDelegate: AnyObject {
    func pageListViewController(_ controller: PageListViewController, currentPageChangedTo currentPage: Int)
}
