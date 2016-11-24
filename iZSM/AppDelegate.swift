//
//  AppDelegate.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/21.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    enum ShortcutIdentifier: String {
        case hot
        case board
        case favorite
        case user
        
        init?(fullType: String) {
            guard let last = fullType.components(separatedBy: ".").last else { return nil }
            self.init(rawValue: last)
        }
        
        var type: String {
            return Bundle.main.bundleIdentifier! + ".\(self.rawValue)"
        }
    }
    
    static let kApplicationShortcutUserInfoIcon = "ApplicationShortcutUserInfoIconKey"

    var window: UIWindow?
    
    /// Saved shortcut item used as a result of an app launch, used later when app is activated.
    var launchedShortcutItem: UIApplicationShortcutItem?
    
    let mainController = UITabBarController()
    let setting = AppSetting.sharedSetting
    let api = SmthAPI()
    let tintColor = UIColor(red: 0/255.0, green: 139/255.0, blue: 203/255.0, alpha: 1)
    
    func handle(shortcutItem: UIApplicationShortcutItem) -> Bool {
        var handled = false
        // Verify that the provided `shortcutItem`'s `type` is one handled by the application.
        guard ShortcutIdentifier(fullType: shortcutItem.type) != nil else { return false }
        
        guard let shortCutType = shortcutItem.type as String? else { return false }
        
        switch shortCutType {
        case ShortcutIdentifier.hot.type:
            mainController.selectedIndex = 0
            handled = true
        case ShortcutIdentifier.board.type:
            mainController.selectedIndex = 1
            handled = true
        case ShortcutIdentifier.favorite.type:
            mainController.selectedIndex = 2
            handled = true
        case ShortcutIdentifier.user.type:
            mainController.selectedIndex = 3
            handled = true
        default:
            break
        }
        return handled
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor.white
        mainController.viewControllers = rootViewControllers()
        
        window?.rootViewController = mainController
        window?.makeKeyAndVisible()
        
        window?.tintColor = tintColor
        // set the appearance of the switch
        UISwitch.appearance().onTintColor = tintColor
        // set the appearance of the navigation bar
        UINavigationBar.appearance().barStyle = .black
        UINavigationBar.appearance().barTintColor = tintColor
        UINavigationBar.appearance().tintColor = UIColor.white
        
        // set the background fetch mode
        if setting.backgroundTaskEnabled {
            application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        } else {
            application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
        }
        
        // register notification
        let type: UIUserNotificationType = [.alert, .badge, .sound]
        let mySettings = UIUserNotificationSettings(types: type, categories: nil)
        application.registerUserNotificationSettings(mySettings)
        
        // if open from notification, then handle it
        if let localNotif = launchOptions?[UIApplicationLaunchOptionsKey.localNotification] as? UILocalNotification {
            print("launch from didFinishLaunchingWithOptions:")
            navigateToNewMessagePage(notification: localNotif)
        }
        
        var shouldPerformAdditionalDelegateHandling = true
        
        // If a shortcut was launched, display its information and take the appropriate action
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            launchedShortcutItem = shortcutItem
            // This will block "performActionForShortcutItem:completionHandler" from being called.
            shouldPerformAdditionalDelegateHandling = false
        }

        return shouldPerformAdditionalDelegateHandling
    }
    
    func rootViewControllers() -> [UIViewController] {
        var controllerArray = [UINavigationController]()
        let hotTableViewController = HotTableViewController()
        hotTableViewController.title = "热点话题"
        hotTableViewController.tabBarItem = UITabBarItem(title: "十大", image: #imageLiteral(resourceName: "Hot"), tag: 0)
        let boardListViewController = BoardListViewController()
        boardListViewController.title = "版面列表"
        boardListViewController.tabBarItem = UITabBarItem(title: "版面", image: #imageLiteral(resourceName: "List"), tag: 1)
        let favListViewController = FavListViewController()
        favListViewController.title = "收藏夹"
        favListViewController.tabBarItem = UITabBarItem(title: "收藏", image: #imageLiteral(resourceName: "Star"), tag: 2)
        let userViewController = UserViewController(style: .grouped)
        userViewController.title = "我"
        userViewController.tabBarItem = UITabBarItem(title: "用户", image: #imageLiteral(resourceName: "User"), tag: 3)
        controllerArray.append(UINavigationController(rootViewController: hotTableViewController))
        controllerArray.append(UINavigationController(rootViewController: boardListViewController))
        controllerArray.append(UINavigationController(rootViewController: favListViewController))
        controllerArray.append(UINavigationController(rootViewController: userViewController))
        return controllerArray
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handledShortCutItem = handle(shortcutItem: shortcutItem)
        print("handle shortcut item in performActionForShortcutItem: \(handledShortCutItem)")
        completionHandler(handledShortCutItem)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        guard let shortcut = launchedShortcutItem else { return }
        
        let handled = handle(shortcutItem: shortcut)
        print("handle shortcut item in didBecomeActive: \(handled)")
        
        launchedShortcutItem = nil
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        print("launch from didReceive notification")
        navigateToNewMessagePage(notification: notification)
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if self.setting.accessToken != nil {
            DispatchQueue.global().async {
                let newMailCount = self.api.getMailStatus()?.newCount ?? 0
                let newReplyCount = self.api.getReferCount(mode: .ReplyToMe)?.newCount ?? 0
                let newReferCount = self.api.getReferCount(mode: .AtMe)?.newCount ?? 0
                print("mail \(self.setting.mailCount) -> \(newMailCount), reply \(self.setting.replyCount) -> \(newReplyCount), refer \(self.setting.referCount) -> \(newReferCount)")
                let allCount = newMailCount + newReplyCount + newReferCount
                application.applicationIconBadgeNumber = allCount
                
                if newMailCount > self.setting.mailCount {
                    print("new mail")
                    let mailNotif = UILocalNotification()
                    mailNotif.alertAction = nil
                    mailNotif.alertBody = "您收到 \(newMailCount) 封新邮件"
                    mailNotif.alertTitle = "新邮件"
                    mailNotif.soundName = UILocalNotificationDefaultSoundName
                    application.presentLocalNotificationNow(mailNotif)
                }
                
                if newReplyCount > self.setting.replyCount {
                    print("new reply")
                    let replyNotif = UILocalNotification()
                    replyNotif.alertAction = nil
                    replyNotif.alertBody = "您收到 \(newReplyCount) 条新回复"
                    replyNotif.alertTitle = "新回复"
                    replyNotif.soundName = UILocalNotificationDefaultSoundName
                    application.presentLocalNotificationNow(replyNotif)
                }
                
                if newReferCount > self.setting.referCount {
                    print("new refer")
                    let atNotif = UILocalNotification()
                    atNotif.alertAction = nil
                    atNotif.alertBody = "有人 @ 了您"
                    atNotif.alertTitle = "新提醒"
                    atNotif.soundName = UILocalNotificationDefaultSoundName
                    application.presentLocalNotificationNow(atNotif)
                }
                
                let hasNewData = (newMailCount > self.setting.mailCount)
                    || (newReplyCount > self.setting.replyCount)
                    || (newReferCount > self.setting.referCount)
                
                self.setting.mailCount = newMailCount
                self.setting.replyCount = newReplyCount
                self.setting.referCount = newReferCount
                
                if hasNewData {
                    completionHandler(.newData)
                    print("new data")
                } else {
                    completionHandler(.noData)
                    print("no new data")
                }
            }
        } else {
            completionHandler(.noData)
            print("no data, user not login or token expired")
        }
    }

    func navigateToNewMessagePage(notification: UILocalNotification) {
        mainController.selectedIndex = 3
        if let nvc = mainController.selectedViewController as? UINavigationController {
            switch notification.alertTitle! {
            case "新邮件":
                let mbvc = MailBoxViewController()
                mbvc.inbox = true
                nvc.show(mbvc, sender: nvc)
            case "新回复":
                let rvc = ReminderViewController()
                rvc.replyMe = true
                nvc.show(rvc, sender: nvc)
            case "新提醒":
                let rvc = ReminderViewController()
                rvc.replyMe = false
                nvc.show(rvc, sender: nvc)
            default:
                break
            }
        }
        
    }
}

func networkActivityIndicatorStart() {
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
}

func networkActivityIndicatorStop() {
    UIApplication.shared.isNetworkActivityIndicatorVisible = false
}

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
        timeInterval /= 60
        if timeInterval < 24 {
            return "\(timeInterval)小时前"
        }
        timeInterval /= 24
        if timeInterval < 7 {
            return "\(timeInterval)天前"
        }
        if timeInterval < 30 {
            return "\(timeInterval/7)周前"
        }
        if timeInterval < 365 {
            return "\(timeInterval/30)个月前"
        }
        timeInterval /= 365
        return "\(timeInterval)年前"
        
    }
    
    var shortDateString: String {
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return formatter.string(from: self)
    }
}

