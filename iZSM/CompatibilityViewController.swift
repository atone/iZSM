//
//  CompatibilityViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2019/11/6.
//  Copyright © 2019 Naitong Yu. All rights reserved.
//

import UIKit

class CompatibilityViewController: NTTableViewController {
    private let setting = AppSetting.shared
    private let identifier = "CompatibilityCell"
    
    lazy var disableHapticTouchSwitch: UISwitch = {
        $0.isOn = setting.disableHapticTouch
        $0.addTarget(self, action: #selector(disableHapticTouchChanged(_:)), for: .valueChanged)
        return $0
    }(UISwitch())
    
    lazy var useClassicReadingSwitch: UISwitch = {
        $0.isOn = setting.classicReadingMode
        $0.addTarget(self, action: #selector(useClassicReadingChanged(_:)), for: .valueChanged)
        return $0
    }(UISwitch())
    
    lazy var useHttpSwitch: UISwitch = {
        $0.isOn = setting.usePlainHttp
        $0.addTarget(self, action: #selector(usePlainHttpChanged(_:)), for: .valueChanged)
        return $0
    }(UISwitch())
    
    lazy var forceDarkModeSwitch: UISwitch = {
        $0.isOn = setting.forceDarkMode
        $0.addTarget(self, action: #selector(forceDarkModeChanged(_:)), for: .valueChanged)
        return $0
    }(UISwitch())
    
    @objc private func disableHapticTouchChanged(_ sender: UISwitch) {
        setting.disableHapticTouch = sender.isOn
    }
    
    @objc private func useClassicReadingChanged(_ sender: UISwitch) {
        setting.classicReadingMode = sender.isOn
    }
    
    @objc private func usePlainHttpChanged(_ sender: UISwitch) {
        setting.usePlainHttp = sender.isOn
        SmthAPI.setUseInsecureHttpConnection(sender.isOn)
    }
    
    @objc private func forceDarkModeChanged(_ sender: UISwitch) {
        setting.forceDarkMode = sender.isOn
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let window = appDelegate.window {
            window.overrideUserInterfaceStyle = sender.isOn ? .dark : .unspecified
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // set tableview self-sizing cell
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: identifier)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 3
        case 1:
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        switch indexPath {
        case IndexPath(row: 0, section: 0):
            cell.textLabel?.text = "禁用Haptic Touch"
            cell.accessoryView = disableHapticTouchSwitch
        case IndexPath(row: 1, section: 0):
            cell.textLabel?.text = "经典看帖界面"
            cell.accessoryView = useClassicReadingSwitch
        case IndexPath(row: 2, section: 0):
            cell.textLabel?.text = "强制黑暗模式"
            cell.accessoryView = forceDarkModeSwitch
        case IndexPath(row: 0, section: 1):
            cell.textLabel?.text = "使用HTTP连接"
            cell.accessoryView = useHttpSwitch
        default:
            break
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 1:
            return "启用该选项后，最水木将使用不安全的HTTP方式与水木社区服务器通讯。仅在默认设置（HTTPS）下无法访问水木社区时尝试开启该选项。"
        default:
            return nil
        }
    }
}
