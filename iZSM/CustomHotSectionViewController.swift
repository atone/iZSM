//
//  CustomHotSectionViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2019/9/19.
//  Copyright © 2019 Naitong Yu. All rights reserved.
//

import UIKit

class CustomHotSectionViewController: NTTableViewController {
    let setting = AppSetting.shared
    let kSwitchLabelIdentifier = "SwitchLabelIdentifier"
    let kSectionLabelIdentifier = "kSectionLabelIdentifier"
    
    var disabledIndex: [Int]  {
        get {
            return setting.disabledHotSections
        }
        set {
            setting.disabledHotSections = newValue
        }
    }
    var availableIndex: [Int] {
        get {
            return setting.availableHotSections
        }
        set {
            setting.availableHotSections = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEditing(true, animated: false)
    }
    
    deinit {
        dPrint("更新十大页面...")
        NotificationCenter.default.post(name: HotTableViewController.kUpdateHotSectionNotification, object: nil)
    }
    
    @objc private func switchChanged(_ sender: UISwitch) {
        setting.customHotSection = sender.isOn
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if setting.customHotSection {
            return 3
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return availableIndex.count
        } else {
            return disabledIndex.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath {
        case IndexPath(row: 0, section: 0):
            let cell = UITableViewCell(style: .default, reuseIdentifier: kSwitchLabelIdentifier)
            let customSwitch = UISwitch()
            customSwitch.isOn = setting.customHotSection
            customSwitch.onTintColor = UIColor(named: "SmthColor")
            customSwitch.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            cell.accessoryView = customSwitch
            cell.textLabel?.text = "自定义热门分区"
            return cell
        default:
            let cell: UITableViewCell
            if let newCell = tableView.dequeueReusableCell(withIdentifier: kSectionLabelIdentifier) {
                cell = newCell
            } else {
                cell = UITableViewCell(style: .default, reuseIdentifier: kSectionLabelIdentifier)
            }
            let index = indexPath.section == 1 ? setting.availableHotSections[indexPath.row] : disabledIndex[indexPath.row]
            cell.textLabel?.text = SMHotSection.sections[index].name
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "已选分区"
        } else if section == 2 {
            return "可用分区"
        }
        return nil
    }
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let tmp: Int
        if fromIndexPath.section == 1 {
            tmp = availableIndex.remove(at: fromIndexPath.row)
        } else {
            tmp = disabledIndex.remove(at: fromIndexPath.row)
        }
        if to.section == 1 {
            availableIndex.insert(tmp, at: to.row)
        } else {
            disabledIndex.insert(tmp, at: to.row)
        }
    }
    
    //MARK: - TableView Styles
    private func flexible(at indexPath: IndexPath) -> Bool {
        return indexPath.section != 0
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return flexible(at: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return flexible(at: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if flexible(at: proposedDestinationIndexPath) {
            return proposedDestinationIndexPath
        } else {
            return IndexPath(row: 0, section: 1)
        }
    }
}
