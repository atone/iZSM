//
//  BlackListViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2019/11/9.
//  Copyright © 2019 Naitong Yu. All rights reserved.
//

import UIKit

class BlacklistViewController: NTTableViewController {
    let identifier = "BlacklistCell"
    
    var keywordBlacklist: [String] {
        get {
            return AppSetting.shared.keywordBlacklist
        }
        set {
            AppSetting.shared.keywordBlacklist = newValue
        }
    }
    var userBlacklist: [String] {
        get {
            return AppSetting.shared.userBlacklist
        }
        set {
            AppSetting.shared.userBlacklist = newValue
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsSelection = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: identifier)
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add(_:)))
        navigationItem.rightBarButtonItem = addButton
    }
    
    @objc private func add(_ sender: UIBarButtonItem) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.popoverPresentationController?.barButtonItem = sender
        let addKeywordAction = UIAlertAction(title: "添加关键词", style: .default) { _ in
            self.addBlacklist(type: .keyword)
        }
        sheet.addAction(addKeywordAction)
        let addUserAction = UIAlertAction(title: "添加用户ID", style: .default) { _ in
            self.addBlacklist(type: .user)
        }
        sheet.addAction(addUserAction)
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(sheet, animated: true)
    }
    
    private enum BlacklistType {
        case user
        case keyword
    }
    
    private func addBlacklist(type: BlacklistType) {
        let title: String
        switch type {
        case .user:
            title = "添加用户ID"
        case .keyword:
            title = "添加关键词"
        }
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField()
        let okAction = UIAlertAction(title: "确定", style: .default) { _ in
            guard let textField = alert.textFields?.first else { return }
            guard let result = textField.text, !result.isEmpty else { return }
            switch type {
            case .user:
                self.userBlacklist.append(result)
            case .keyword:
                self.keywordBlacklist.append(result)
            }
            self.tableView.reloadData()
        }
        alert.addAction(okAction)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = keywordBlacklist[indexPath.row]
        case 1:
            cell.textLabel?.text = userBlacklist[indexPath.row]
        default:
            break
        }
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return keywordBlacklist.count
        case 1:
            return userBlacklist.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "屏蔽关键词"
        case 1:
            return "屏蔽用户ID"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            if keywordBlacklist.isEmpty {
                return "无"
            }
        case 1:
            if userBlacklist.isEmpty {
                return "无"
            } else {
                return "屏蔽仅在浏览时生效，您仍可能收到被屏蔽用户给您发送的邮件、回复以及@提醒。"
            }
        default:
            break
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        switch indexPath.section {
        case 0:
            keywordBlacklist.remove(at: indexPath.row)
        case 1:
            userBlacklist.remove(at: indexPath.row)
        default:
            break
        }
        tableView.beginUpdates()
        tableView.deleteRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }
}
