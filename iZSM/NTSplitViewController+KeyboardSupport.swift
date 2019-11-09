//
//  NTSplitViewController+KeyboardSupport.swift
//  iZSM
//
//  Created by Naitong Yu on 2019/11/8.
//  Copyright © 2019 Naitong Yu. All rights reserved.
//

extension NTSplitViewController {
    
    override var keyCommands: [UIKeyCommand]? {
        if presentedViewController != nil {
            return nil
        }
        
        if isInSearchMode {
            return searchModeCommands + navigationCommands
        }
        
        var commands = [UIKeyCommand]()
        commands.append(contentsOf: switchTabCommands)
        
        if topMasterViewController is BaseTableViewController
            || (isCollapsed && topMasterViewController is ArticleContentViewController) {
            commands.append(contentsOf: navigationCommands)
            if !(isCollapsed && topMasterViewController is ArticleContentViewController) {
                commands.append(enterCommand)
            }
            commands.append(backCommand)
        }
        
        if topMasterViewController is HotTableViewController {
            commands.append(contentsOf: hotTopicCommands)
        }
        
        if boardListCanEnterSearchMode {
            commands.append(contentsOf: boardListCommands)
        }
        
        if topMasterViewController is ArticleListViewController {
            commands.append(contentsOf: articleListCommands)
        }
        
        if let contentVC = topViewController as? ArticleContentViewController, isCollapsed || contentVC.isFocus {
            commands.append(contentsOf: articleContentCommands)
        }
        
        return commands
    }
    
    // MARK: - commands
    
    private var switchTabCommands: [UIKeyCommand] {
        return [
            UIKeyCommand(title: "十大", action: #selector(switchTab(_:)), input: "1", modifierFlags: [.command]),
            UIKeyCommand(title: "版面", action: #selector(switchTab(_:)), input: "2", modifierFlags: [.command]),
            UIKeyCommand(title: "收藏", action: #selector(switchTab(_:)), input: "3", modifierFlags: [.command]),
            UIKeyCommand(title: "用户", action: #selector(switchTab(_:)), input: "4", modifierFlags: [.command])
        ]
    }
    
    private var enterCommand: UIKeyCommand {
        return UIKeyCommand(title: "打开", action: #selector(enter(_:)), input: "\r")
    }
    
    private var backCommand: UIKeyCommand {
        return UIKeyCommand(title: "返回", action: #selector(back(_:)), input: "\u{8}")
    }
    
    private var navigationCommands: [UIKeyCommand] {
        return [
            UIKeyCommand(title: "上一项", action: #selector(navigationAction(_:)), input: UIKeyCommand.inputUpArrow),
            UIKeyCommand(title: "下一项", action: #selector(navigationAction(_:)), input: UIKeyCommand.inputDownArrow)
        ]
    }
    
    private var hotTopicCommands: [UIKeyCommand] {
        return [
            UIKeyCommand(title: "刷新", action: #selector(hotTopicAction(_:)), input: "r", modifierFlags: [.command])
        ]
    }
    
    private var boardListCommands: [UIKeyCommand] {
        return [
            UIKeyCommand(title: "查找", action: #selector(boardListAction(_:)), input: "f", modifierFlags: [.command])
        ]
    }
    
    private var articleListCommands: [UIKeyCommand] {
        return [
            UIKeyCommand(title: "发帖", action: #selector(articleListAction(_:)), input: "p", modifierFlags: [.control]),
            UIKeyCommand(title: "查找", action: #selector(articleListAction(_:)), input: "f", modifierFlags: [.command]),
            UIKeyCommand(title: "刷新", action: #selector(articleListAction(_:)), input: "r", modifierFlags: [.command])
        ]
    }
    
    private var articleContentCommands: [UIKeyCommand] {
        return [
            UIKeyCommand(title: "向前翻页", action: #selector(articleContentAction(_:)), input: UIKeyCommand.inputLeftArrow),
            UIKeyCommand(title: "向后翻页", action: #selector(articleContentAction(_:)), input: UIKeyCommand.inputRightArrow),
            UIKeyCommand(title: "回复", action: #selector(articleContentAction(_:)), input: "r"),
            UIKeyCommand(title: "私信回复", action: #selector(articleContentAction(_:)), input: "r", modifierFlags: [.control])
        ]
    }
    
    private var searchModeCommands: [UIKeyCommand] {
        return [
            UIKeyCommand(title: "打开", action: #selector(enter(_:)), input: "\r", modifierFlags: [.command]),
            UIKeyCommand(title: "返回", action: #selector(back(_:)), input: "\u{8}", modifierFlags: [.command]),
            UIKeyCommand(title: "退出", action: #selector(escapeSearchMode(_:)), input: UIKeyCommand.inputEscape)
        ]
    }
    
    // MARK: - helpers
    
    private var masterNavigationController: NTNavigationController? {
        guard let tabBarVC = viewControllers.first as? NTTabBarController else { return nil }
        return tabBarVC.selectedViewController as? NTNavigationController
    }
    
    private var detailNavigationController: NTNavigationController? {
        return viewControllers.last as? NTNavigationController
    }
    
    private var topMasterViewController: UIViewController? {
        return masterNavigationController?.topViewController
    }
    
    private var topDetailViewController: UIViewController? {
        return detailNavigationController?.topViewController
    }
    
    private var topViewController: UIViewController? {
        if let dtv = topDetailViewController {
            return dtv
        } else if let mtv = topMasterViewController {
            return mtv
        }
        return nil
    }
    
    private var isInSearchMode: Bool {
        if let alvc = topMasterViewController as? ArticleListViewController {
            return alvc.searchMode
        } else if let blvc = topMasterViewController as? BoardListViewController {
            return blvc.searchMode
        }
        return false
    }
    
    private var boardListCanEnterSearchMode: Bool {
        if let blvc = topMasterViewController as? BoardListViewController, blvc.boardID == 0 {
            return true
        }
        return false
    }
    
    private func viewControllerNavigateToContent(_ vc: BaseTableViewController) -> Bool {
        return vc is HotTableViewController
            || vc is ArticleListViewController
            || vc is ArticleListSearchResultViewController
            || (vc is FavListViewController && (vc as! FavListViewController).index == 1)
    }
    
    // MARK: - actions
    
    @objc private func switchTab(_ sender: UIKeyCommand) {
        guard let input = sender.input else { return }
        guard let intKey = Int(input) else { return }
        guard let tabBarViewController = viewControllers.first as? NTTabBarController else { return }
        tabBarViewController.selectedIndex = intKey - 1
    }
    
    @objc private func enter(_ sender: UIKeyCommand) {
        guard let masterNVC = masterNavigationController else { return }
        if let topVC = masterNVC.topViewController as? BaseTableViewController {
            topVC.navigateEnter()
            if viewControllerNavigateToContent(topVC) {
                let contentVC: ArticleContentViewController?
                if !isCollapsed, let detailNVC = detailNavigationController {
                    contentVC = detailNVC.topViewController as? ArticleContentViewController
                } else {
                    contentVC = masterNVC.topViewController as? ArticleContentViewController
                }
                if let contentVC = contentVC, contentVC.isFocus == false {
                    contentVC.isFocus = true
                }
            }
        }
    }
    
    @objc private func back(_ sender: UIKeyCommand) {
        if !isCollapsed {
            guard let detailNVC = detailNavigationController else { return }
            if detailNVC.viewControllers.count > 1 {
                detailNVC.popViewController(animated: true)
                return
            } else if let contentVC = detailNVC.topViewController as? ArticleContentViewController,
                contentVC.isFocus == true {
                contentVC.isFocus = false
                if let indexPath = contentVC.tableView.indexPathForSelectedRow {
                    contentVC.tableView.deselectRow(at: indexPath, animated: false)
                }
                return
            }
        }
        
        guard let masterNVC = masterNavigationController else { return }
        if masterNVC.viewControllers.count > 1 {
            masterNVC.popViewController(animated: true)
        } else if let topVC = masterNVC.topViewController as? BaseTableViewController {
            if topVC.isFocus {
                topVC.isFocus = false
                if let indexPath = topVC.tableView.indexPathForSelectedRow {
                    topVC.tableView.deselectRow(at: indexPath, animated: true)
                }
            } else if preferredDisplayMode != .automatic {
                preferredDisplayMode = .automatic
            }
        }
    }
    
    @objc private func navigationAction(_ sender: UIKeyCommand) {
        if displayMode != .allVisible {
            preferredDisplayMode = .allVisible
        }
        if let contentVC = topViewController as? ArticleContentViewController,
            isCollapsed || contentVC.isFocus {
            if sender.input == UIKeyCommand.inputUpArrow {
                contentVC.navigateUp()
            } else if sender.input == UIKeyCommand.inputDownArrow {
                contentVC.navigateDown()
            }
        } else if let baseVC = topMasterViewController as? BaseTableViewController {
            if sender.input == UIKeyCommand.inputUpArrow {
                baseVC.navigateUp()
            } else if sender.input == UIKeyCommand.inputDownArrow {
                baseVC.navigateDown()
            }
        }
    }
    
    @objc private func hotTopicAction(_ sender: UIKeyCommand) {
        if let hvc = topMasterViewController as? HotTableViewController {
            if sender.input == "r" {
                hvc.navigateRefresh()
            }
        }
    }
    
    @objc private func boardListAction(_ sender: UIKeyCommand) {
        if let blvc = topMasterViewController as? BoardListViewController {
            if sender.input == "f" {
                blvc.navigateEnterSearch()
            }
        }
    }
    
    @objc private func articleListAction(_ sender: UIKeyCommand) {
        if let alvc = topMasterViewController as? ArticleListViewController {
            if sender.input == "p" {
                alvc.navigateCompose()
            } else if sender.input == "f" {
                alvc.navigateEnterSearch()
            } else if sender.input == "r" {
                alvc.navigateRefresh()
            }
        }
    }
    
    @objc private func escapeSearchMode(_ sender: UIKeyCommand) {
        if let alvc = topMasterViewController as? ArticleListViewController {
            alvc.navigateEscapeSearch()
        } else if let blvc = topMasterViewController as? BoardListViewController {
            blvc.navigateEscapeSearch()
        }
    }
    
    @objc private func articleContentAction(_ sender: UIKeyCommand) {
        if let contentVC = topViewController as? ArticleContentViewController {
            if sender.input == UIKeyCommand.inputLeftArrow {
                contentVC.navigatePrevPage()
            } else if sender.input == UIKeyCommand.inputRightArrow {
                contentVC.navigateNextPage()
            } else if sender.input == "r" {
                if sender.modifierFlags == .control {
                    contentVC.navigateReply(byMail: true)
                } else {
                    contentVC.navigateReply()
                }
            }
        }
    }
}
