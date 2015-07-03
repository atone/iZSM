//
//  AppDelegate.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/5.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let setting = AppSetting.sharedSetting()
    let tintColor = UIColor(red: 0/255.0, green: 139/255.0, blue: 203/255.0, alpha: 1)

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        window?.backgroundColor = UIColor.whiteColor()
        window?.tintColor = tintColor

        // set the appearance of the navigation bar
        UINavigationBar.appearance().barStyle = .Black
        UINavigationBar.appearance().barTintColor = tintColor
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()

        // set the background fetch mode
        if setting.backgroundTaskEnabled {
            application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        } else {
            application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
        }

        // register notification
        let type: UIUserNotificationType = .Alert | .Badge | .Sound
        let mySettings = UIUserNotificationSettings(forTypes: type, categories: nil)
        application.registerUserNotificationSettings(mySettings)

        // if open from notification, then handle it
        if let localNotif = launchOptions?[UIApplicationLaunchOptionsLocalNotificationKey] as? UILocalNotification {
            navigateToNewMessagePageWithNotification(localNotif)
        }
        return true
    }

    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        navigateToNewMessagePageWithNotification(notification)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {

        if setting.accessToken != nil {
            let tabBarController = self.window?.rootViewController as? UITabBarController
            let navigationController = tabBarController?.viewControllers?.last as? UINavigationController
            let userViewController = navigationController?.viewControllers?.first as? UserViewController

            if let uvc = userViewController {
                uvc.checkNewMailAndReferenceBackgroundMode(true) { hasNewMessage -> Void in
                    if hasNewMessage {
                        completionHandler(.NewData)
                        printLog("new data")
                    } else {
                        completionHandler(.NoData)
                        printLog("no new data")
                    }
                }

            } else {
                completionHandler(.Failed)
                printLog("failed")
            }
        } else {
            completionHandler(.NoData)
            printLog("no data, user not login or token expired")
        }
    }

    func navigateToNewMessagePageWithNotification(notif: UILocalNotification) {
        let tabBarController = self.window?.rootViewController as? UITabBarController
        let navigationController = tabBarController?.viewControllers?.last as? UINavigationController
        let userViewController = navigationController?.viewControllers?.first as? UserViewController

        if let uvc = userViewController {
            tabBarController?.selectedIndex = 3
            switch notif.category! {
            case "新邮件":
                let mbvc = uvc.storyboard?.instantiateViewControllerWithIdentifier("MailBoxViewController") as! MailBoxViewController
                mbvc.inbox = true
                uvc.showViewController(mbvc, sender: uvc)
            case "新回复":
                let rvc = uvc.storyboard?.instantiateViewControllerWithIdentifier("ReminderViewController") as! ReminderViewController
                rvc.replyMe = true
                uvc.showViewController(rvc, sender: uvc)
            case "新提醒":
                let rvc = uvc.storyboard?.instantiateViewControllerWithIdentifier("ReminderViewController") as! ReminderViewController
                rvc.replyMe = false
                uvc.showViewController(rvc, sender: uvc)
            default:
                break
            }
        }
    }
}

func networkActivityIndicatorStart() {
    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
}

func networkActivityIndicatorStop() {
    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
}

func printLog<T>(message: T,
    file: String = __FILE__,
    method: String = __FUNCTION__, line: Int = __LINE__)
{
    #if DEBUG
        println("\(file.lastPathComponent)[\(line)], \(method): \(message)")
    #endif
}

extension NSDate {

    func beginningOfDay() -> NSDate {
        var calendar = NSCalendar.currentCalendar()
        var components = calendar.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay, fromDate: self)
        return calendar.dateFromComponents(components)!
    }

    func endOfDay() -> NSDate {
        var components = NSDateComponents()
        components.day = 1
        var date = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: self.beginningOfDay(), options: .allZeros)!
        date = date.dateByAddingTimeInterval(-1)
        return date
    }
}

