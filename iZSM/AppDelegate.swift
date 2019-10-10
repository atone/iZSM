//
//  AppDelegate.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/21.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import UserNotifications
import BackgroundTasks
import SVProgressHUD

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    /// Saved shortcut item used as a result of an app launch, used later when app is activated.
    var launchedShortcutItem: UIApplicationShortcutItem?
    
    var messageTimer: Timer?
    
    let splitViewController = NTSplitViewController()
    let tabBarViewController = NTTabBarController()
    let setting = AppSetting.shared
    
    func handle(shortcutItem: UIApplicationShortcutItem) -> Bool {
        var handled = false
        guard let shortType = shortcutItem.type.components(separatedBy: ".").last else { return false }
        switch shortType {
        case "hot":
            tabBarViewController.selectedIndex = 0
            handled = true
        case "board":
            tabBarViewController.selectedIndex = 1
            handled = true
        case "favorite":
            tabBarViewController.selectedIndex = 2
            handled = true
        case "user":
            tabBarViewController.selectedIndex = 3
            handled = true
        default:
            break
        }
        return handled
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.tintColor = UIColor(named: "SmthColor")
        tabBarViewController.viewControllers = rootViewControllers()
        splitViewController.viewControllers = [tabBarViewController, placeholderViewController()]
        splitViewController.delegate = self
        
        window?.rootViewController = splitViewController
        window?.makeKeyAndVisible()
        
        // set the SVProgressHUD setting
        SVProgressHUD.setMinimumDismissTimeInterval(2)
        
        // set the background fetch mode
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "cn.yunaitong.zsmth.refresh", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        // register notification
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) {
            (granted, error) in
            if !granted {
                dPrint("Notification authorization not granted!")
            }
        }
        
        var shouldPerformAdditionalDelegateHandling = true
        
        // If a shortcut was launched, display its information and take the appropriate action
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            launchedShortcutItem = shortcutItem
            // This will block "performActionForShortcutItem:completionHandler" from being called.
            shouldPerformAdditionalDelegateHandling = false
        }

        return shouldPerformAdditionalDelegateHandling
    }
    
    func placeholderViewController() -> UIViewController {
        let placeholderVC = PlaceholderViewController()
        placeholderVC.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        return NTNavigationController(rootViewController: placeholderVC)
    }
    
    func rootViewControllers() -> [UIViewController] {
        var controllerArray = [NTNavigationController]()
        let hotTableViewController = HotTableViewController()
        hotTableViewController.title = "热点话题"
        hotTableViewController.tabBarItem = UITabBarItem(title: "十大", image: UIImage(systemName: "clock"), selectedImage: UIImage(systemName: "clock.fill"))
        let boardListViewController = BoardListViewController()
        boardListViewController.title = "版面列表"
        boardListViewController.tabBarItem = UITabBarItem(title: "版面", image: UIImage(systemName: "book"), selectedImage: UIImage(systemName: "book.fill"))
        let favListViewController = FavListViewController()
        favListViewController.title = "收藏夹"
        favListViewController.tabBarItem = UITabBarItem(title: "收藏", image: UIImage(systemName: "star"), selectedImage: UIImage(systemName: "star.fill"))
        let userViewController = UserViewController(style: .grouped)
        userViewController.title = "我"
        userViewController.tabBarItem = UITabBarItem(title: "用户", image: UIImage(systemName: "person"), selectedImage: UIImage(systemName: "person.fill"))
        controllerArray.append(NTNavigationController(rootViewController: hotTableViewController))
        controllerArray.append(NTNavigationController(rootViewController: boardListViewController))
        controllerArray.append(NTNavigationController(rootViewController: favListViewController))
        controllerArray.append(NTNavigationController(rootViewController: userViewController))
        return controllerArray
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handledShortCutItem = handle(shortcutItem: shortcutItem)
        dPrint("handle shortcut item in performActionForShortcutItem: \(handledShortCutItem)")
        completionHandler(handledShortCutItem)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        if setting.backgroundTaskEnabled {
            scheduleAppRefresh()
        }
        
        if let messageTimer = self.messageTimer {
            messageTimer.invalidate()
            self.messageTimer = nil
            dPrint("Message timer invalidated")
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if let shortcut = launchedShortcutItem {
            let handled = handle(shortcutItem: shortcut)
            dPrint("handle shortcut item in didBecomeActive: \(handled)")
            launchedShortcutItem = nil
        }
        
        if messageTimer == nil {
            messageTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { timer in
                MessageCenter.shared.checkUnreadMessage()
            }
            dPrint("Schedule timer to check unread message every 15 minutes")
        }
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "cn.yunaitong.zsmth.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minites later
        do {
            try BGTaskScheduler.shared.submit(request)
            dPrint("Successfully submitted refresh task")
        } catch {
            dPrint("Could not schedule app refresh: \(error)")
        }
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        // schedule another refresh task
        scheduleAppRefresh()
        
        task.expirationHandler = {
            dPrint("Background refresh task expired")
        }
        
        MessageCenter.shared.checkUnreadMessage(postUserNotification: true) { success in
            task.setTaskCompleted(success: success)
        }
    }

    func navigateToNewMessagePage(with identifier: String) {
        tabBarViewController.selectedIndex = 3
        if let nvc = tabBarViewController.selectedViewController as? NTNavigationController,
            let userVC = nvc.viewControllers.first as? UserViewController,
            let showVC = nvc.viewControllers.last {
            userVC.tabBarItem.badgeValue = "\(UIApplication.shared.applicationIconBadgeNumber)"
            switch identifier {
            case "zsmth.newmail":
                let mbvc = MailBoxViewController()
                mbvc.inbox = true
                mbvc.userVC = userVC
                showVC.show(mbvc, sender: showVC)
            case "zsmth.newreply":
                let rvc = ReminderViewController()
                rvc.replyMe = true
                rvc.userVC = userVC
                showVC.show(rvc, sender: showVC)
            case "zsmth.newrefer":
                let rvc = ReminderViewController()
                rvc.replyMe = false
                rvc.userVC = userVC
                showVC.show(rvc, sender: showVC)
            default:
                dPrint("Invalid identifier: \(identifier)")
                break
            }
        }
    }
}

extension AppDelegate : UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        dPrint("Handle \(identifier) notification in userNotificationCenter(_:didReceive:withCompletionHandler:)")
        navigateToNewMessagePage(with: identifier)
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let identifier = notification.request.identifier
        dPrint("Handle \(identifier) notification in userNotificationCenter(_:willPresent:withNotificationHandler:)")
        navigateToNewMessagePage(with: identifier)
        completionHandler(UNNotificationPresentationOptions(rawValue: 0))
    }
}

func networkActivityIndicatorStart(withHUD: Bool = false) {
    if withHUD {
        SVProgressHUD.show()
    }
}

func networkActivityIndicatorStop(withHUD: Bool = false) {
    if withHUD {
        SVProgressHUD.dismiss()
    }
}

func dPrint(_ item: @autoclosure () -> Any) {
    #if DEBUG
    print(item())
    #endif
}

var globalShouldRotate = true
var globalLockPortrait = false

private let formatter = DateFormatter()

extension Date {
    var relativeDateString: String {
        var timeInterval = Int(self.timeIntervalSinceNow)
        if timeInterval >= 0 {
            return "现在"
        }
        timeInterval = -timeInterval
        if timeInterval < 60 {
            return "\(timeInterval)秒前"
        }
        timeInterval /= 60
        if timeInterval < 60 {
            return "\(timeInterval)分钟前"
        }
        let minute = timeInterval % 60
        timeInterval /= 60
        if timeInterval < 24 {
            if minute > 0 {
                return "\(timeInterval)小时\(minute)分钟前"
            } else {
                return "\(timeInterval)小时前"
            }
        }
        timeInterval /= 24
        if timeInterval < 365 {
            return "\(timeInterval)天前"
        }
        return shortDateString
    }
    
    var shortDateString: String {
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return formatter.string(from: self)
    }
}

extension SmthAPI {
    func displayErrorIfNeeded() {
        if errorCode != 0 {
            var errorMsg: String = "未知错误"
            if errorCode == -1 {
                errorMsg = "网络错误"
            } else if errorCode == 10014 || errorCode == 10010 {
                errorMsg = "token失效，请刷新"
                AppSetting.shared.accessToken = nil // clear expired access token
            } else if errorCode == 10417 {
                errorMsg = "您还没有驻版"
            } else if let errorDesc = errorDescription, !errorDesc.isEmpty {
                errorMsg = errorDesc
            } else if errorCode < 0 {
                errorMsg = "服务器错误"
            } else if errorCode < 11000 {
                errorMsg = "系统错误"
            }
            SVProgressHUD.showInfo(withStatus: errorMsg)
            dPrint("\(errorMsg), error code \(errorCode)")
        }
    }
}

extension AppDelegate: UISplitViewControllerDelegate {
    
    func splitViewControllerSupportedInterfaceOrientations(_ splitViewController: UISplitViewController) -> UIInterfaceOrientationMask {
        if globalLockPortrait {
            return [.portrait, .portraitUpsideDown]
        } else {
            return .all
        }
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
        if let tabBarController = splitViewController.viewControllers.first as? NTTabBarController,
            let firstNaviCtr = tabBarController.selectedViewController as? NTNavigationController {
            if splitViewController.isCollapsed || !(vc is SmthContentEqutable) {
                if vc != firstNaviCtr.topViewController {
                    firstNaviCtr.pushViewController(vc, animated: true)
                }
            } else if let secondNaviCtr = splitViewController.viewControllers.last as? NTNavigationController {
                if secondNaviCtr.topViewController != vc {
                    vc.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
                    secondNaviCtr.setViewControllers([vc], animated: false)
                }
            }
        }
        return true
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        if let tabBarController = primaryViewController as? NTTabBarController,
            let firstNaviCtr = tabBarController.selectedViewController as? NTNavigationController,
            let secondNaviCtr = secondaryViewController as? NTNavigationController {
            for viewController in secondNaviCtr.viewControllers {
                if viewController is SmthContentEqutable {
                    // remove the display mode button
                    if viewController === secondNaviCtr.viewControllers.first {
                        viewController.navigationItem.leftBarButtonItem = nil
                    }
                    firstNaviCtr.pushViewController(viewController, animated: false)
                }
            }
            secondNaviCtr.viewControllers = []
        }
        return true
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        if let tabBarController = primaryViewController as? NTTabBarController,
            let firstNaviCtr = tabBarController.selectedViewController as? NTNavigationController {
            let secondNaviCtr = NTNavigationController()
            let viewControllers = firstNaviCtr.popToRootViewController(animated: false)
            
            var displayModeButtonAdded = false
            for viewController in viewControllers ?? [] {
                if viewController is SmthContentEqutable {
                    // add the display mode button on first SmthContentEqutable
                    if !displayModeButtonAdded {
                        displayModeButtonAdded = true
                        viewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
                    }
                    secondNaviCtr.pushViewController(viewController, animated: false)
                } else {
                    firstNaviCtr.pushViewController(viewController, animated: false)
                }
            }
            
            if secondNaviCtr.viewControllers.count > 0 {
                return secondNaviCtr
            }
        }
        return placeholderViewController()
    }
}

protocol SmthContentEqutable: class {
    func isEqual(_ object: Any?) -> Bool
}
