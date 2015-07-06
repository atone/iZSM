//
//  AppSetting.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/10.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import Foundation

class AppSetting {

    private static let sharedInstance = AppSetting()

    class func sharedSetting() -> AppSetting {
        return sharedInstance
    }

    private struct Static {
        static let UsernameKey = "SmthAPI.username"
        static let PasswordKey = "SmthAPI.password"
        static let AccessTokenKey = "SmthAPI.accessToken"
        static let ExpireDateKey = "SmthAPI.expireDate"
        static let ClearUnreadModeKey = "SmthAPI.ClearUnreadMode"
        static let SortModeKey = "SmthAPI.SortMode"
        static let HideAlwaysOnTopThreadKey = "SmthAPI.hideAlwaysOnTopThread"
        static let ShowSignatureKey = "SmthAPI.showSignature"
        static let ArticleCountPerSectionKey = "SmthAPI.articleCountPerSection"
        static let ThreadCountPerSectionKey = "SmthAPI.threadCountPerSection"
        static let BackgroundTaskEnabledKey = "SmthAPI.backgroundTaskEnabled"
        static let EulaAgreedKey = "SmthAPI.eulaAgreed"
    }

    private let defaults = NSUserDefaults.standardUserDefaults()
    private init () {
        // if some essential settings not set, then set them as default value
        let initialSettings: [String : AnyObject] = [
            Static.ClearUnreadModeKey : Int(SmthAPI.ClearUnreadMode.NotClear.rawValue),
            Static.SortModeKey : Int(SmthAPI.SortMode.Normal.rawValue),
            Static.HideAlwaysOnTopThreadKey : false,
            Static.ShowSignatureKey : false,
            Static.ArticleCountPerSectionKey : 20,
            Static.ThreadCountPerSectionKey : 20,
            Static.BackgroundTaskEnabledKey : true,
            Static.EulaAgreedKey : false
        ]
        defaults.registerDefaults(initialSettings)
    }

    var username: String? {
        get { return defaults.stringForKey(Static.UsernameKey) }
        set {
            defaults.setObject(newValue, forKey: Static.UsernameKey)
            defaults.synchronize()
        }
    }

    var password: String? {
        get { return defaults.stringForKey(Static.PasswordKey) }
        set {
            defaults.setObject(newValue, forKey: Static.PasswordKey)
            defaults.synchronize()
        }
    }

    var accessToken: String? {
        get {
            if let
                accessToken = defaults.stringForKey(Static.AccessTokenKey),
                expireDate = defaults.objectForKey(Static.ExpireDateKey) as? NSDate
            where
                expireDate.compare(NSDate()) == .OrderedDescending
            {
                return accessToken
            }
            return nil
        }
        set {
            defaults.setObject(newValue, forKey: Static.AccessTokenKey)
            defaults.setObject(NSDate(timeIntervalSinceNow: 24 * 60 * 60), forKey: Static.ExpireDateKey)
            defaults.synchronize()
        }
    }

    var backgroundTaskEnabled: Bool {
        get { return defaults.boolForKey(Static.BackgroundTaskEnabledKey) }
        set {
            defaults.setBool(newValue, forKey: Static.BackgroundTaskEnabledKey)
            defaults.synchronize()
        }
    }

    var hideAlwaysOnTopThread: Bool {
        get { return defaults.boolForKey(Static.HideAlwaysOnTopThreadKey) }
        set {
            defaults.setBool(newValue, forKey: Static.HideAlwaysOnTopThreadKey)
            defaults.synchronize()
        }
    }

    var showSignature: Bool {
        get { return defaults.boolForKey(Static.ShowSignatureKey) }
        set {
            defaults.setBool(newValue, forKey: Static.ShowSignatureKey)
            defaults.synchronize()
        }
    }

    var eulaAgreed: Bool {
        get { return defaults.boolForKey(Static.EulaAgreedKey) }
        set {
            defaults.setBool(newValue, forKey: Static.EulaAgreedKey)
            defaults.synchronize()
        }
    }

    var clearUnreadMode: SmthAPI.ClearUnreadMode {
        get { return SmthAPI.ClearUnreadMode(rawValue: Int32(defaults.integerForKey(Static.ClearUnreadModeKey)))! }
        set {
            defaults.setInteger(Int(newValue.rawValue), forKey: Static.ClearUnreadModeKey)
            defaults.synchronize()
        }
    }

    var sortMode: SmthAPI.SortMode {
        get { return SmthAPI.SortMode(rawValue: Int32(defaults.integerForKey(Static.SortModeKey)))! }
        set {
            defaults.setInteger(Int(newValue.rawValue), forKey: Static.SortModeKey)
            defaults.synchronize()
        }
    }

    var articleCountPerSection: Int {
        get { return defaults.integerForKey(Static.ArticleCountPerSectionKey) }
        set {
            defaults.setInteger(newValue, forKey: Static.ArticleCountPerSectionKey)
            defaults.synchronize()
        }
    }

    var threadCountPerSection: Int {
        get { return defaults.integerForKey(Static.ThreadCountPerSectionKey) }
        set {
            defaults.setInteger(newValue, forKey: Static.ThreadCountPerSectionKey)
            defaults.synchronize()
        }
    }

}