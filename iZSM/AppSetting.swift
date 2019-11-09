//
//  AppSetting.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/10.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import Foundation
import DeviceKit
import KeychainSwift
import SmthConnection

class AppSetting {

    static let shared = AppSetting()
    
    enum DisplayMode: Int {
        case nForum = 0, www2, mobile
    }

    private struct Static {
        static let UsernameKey = "SmthAPI.username"
        static let PasswordKey = "SmthAPI.password"
        static let AccessTokenKey = "SmthAPI.accessToken"
        static let ExpireDateKey = "SmthAPI.expireDate"
        static let ReplySortModeKey = "SmthAPI.ReplySortMode"
        static let HideAlwaysOnTopThreadKey = "SmthAPI.hideAlwaysOnTopThread"
        static let ShowSignatureKey = "SmthAPI.showSignature"
        static let ArticleCountPerSectionKey = "SmthAPI.articleCountPerSection"
        static let ThreadCountPerSectionKey = "SmthAPI.threadCountPerSection"
        static let BackgroundTaskEnabledKey = "SmthAPI.backgroundTaskEnabled"
        static let EulaAgreedKey = "SmthAPI.eulaAgreed"
        static let MailCountKey = "SmthAPI.mailCountKey"
        static let ReplyCountKey = "SmthAPI.replyCountKey"
        static let ReferCountKey = "SmthAPI.referCountKey"
        static let RememberLastKey = "SmthAPI.rememberLastKey"
        static let DisplayModeKey = "SmthAPI.displayModeKey"
        static let ShowAvatarKey = "SmthAPI.showAvatarKey"
        static let NoPicModeKey = "SmthAPI.noPicModeKey"
        static let AddDeviceSignatureKey = "SmthAPI.deviceSignatureKey"
        static let CustomHotSectionKey = "SmthAPI.customHotSectionKey"
        static let AutoSortHotSectionKey = "SmthAPI.autoSortHotSectionKey"
        static let AvailableHotSectionsKey = "SmthAPI.availableHotSectionsKey"
        static let DisabledHotSectionsKey = "SmthAPI.disabledHotSectionsKey"
        static let CustomFontScaleIndexKey = "SmthAPI.customFontScaleIndexKey"
        static let ThreadSortModeKey = "SmthAPI.threadSortModeKey"
        static let useBoldFontKey = "SmthAPI.useBoldFontKey"
        static let userBlacklistKey = "SmthAPI.userBlacklistKey"
        static let keywordBlacklistKey = "SmthAPI.keywordBlacklistKey"
        static let disableHapticTouchKey = "SmthAPI.Compatibility.disableHapticTouchKey"
        static let classicReadingModeKey = "SmthAPI.Compatibility.classicReadingModeKey"
        static let forceDarkModeKey = "SmthAPI.Compatibility.forceDarkModeKey"
        static let usePlainHttpKey = "SmthAPI.Compatibility.usePlainHttpKey"
    }

    private let defaults = UserDefaults.standard
    private let keychain = KeychainSwift()
    
    private init () {
        // if some essential settings not set, then set them as default value
        let initialSettings: [String : Any] = [
            Static.ReplySortModeKey : SMThread.ReplySortMode.oldFirst.rawValue,
            Static.HideAlwaysOnTopThreadKey : false,
            Static.ShowSignatureKey : false,
            Static.ArticleCountPerSectionKey : 20,
            Static.ThreadCountPerSectionKey : 20,
            Static.BackgroundTaskEnabledKey : true,
            Static.EulaAgreedKey : false,
            Static.MailCountKey : 0,
            Static.ReplyCountKey : 0,
            Static.ReferCountKey : 0,
            Static.RememberLastKey : true,
            Static.DisplayModeKey : DisplayMode.mobile.rawValue,
            Static.ShowAvatarKey : true,
            Static.NoPicModeKey : false,
            Static.AddDeviceSignatureKey : true,
            Static.CustomHotSectionKey : false,
            Static.AutoSortHotSectionKey : false,
            Static.AvailableHotSectionsKey : [1, 2, 3, 4, 5, 6, 7, 8, 9],
            Static.DisabledHotSectionsKey : [0],
            Static.CustomFontScaleIndexKey: 2,
            Static.ThreadSortModeKey : 0,
            Static.useBoldFontKey : false,
            Static.disableHapticTouchKey : false,
            Static.classicReadingModeKey : false,
            Static.forceDarkModeKey : false,
            Static.usePlainHttpKey : false
        ]
        defaults.register(defaults: initialSettings)
    }
    
    var deviceName: String {
        var name = Device.current.description
        // 水木会过滤掉字符ʀ，故用r替换
        name = name.replacingOccurrences(of: "ʀ", with: "r")
        return name
    }
    
    var signature: String {
        return "- 来自「最水木 for \(deviceName)」"
    }
    
    var addDeviceSignature: Bool {
        get { return defaults.bool(forKey: Static.AddDeviceSignatureKey) }
        set {
            defaults.set(newValue, forKey: Static.AddDeviceSignatureKey)
        }
    }

    var username: String? {
        get {
            if let user = keychain.get(Static.UsernameKey) {
                if !user.isEmpty {
                    return user
                }
            }
            return nil
        }
        set {
            keychain.set(newValue ?? "", forKey: Static.UsernameKey)
        }
    }

    var password: String? {
        get {
            if let pass = keychain.get(Static.PasswordKey) {
                if !pass.isEmpty {
                    return pass
                }
            }
            return nil
        }
        set {
            keychain.set(newValue ?? "", forKey: Static.PasswordKey)
        }
    }

    var accessToken: String? {
        get {
            if
                let accessToken = defaults.string(forKey: Static.AccessTokenKey),
                let expireDate = defaults.object(forKey: Static.ExpireDateKey) as? Date,
                expireDate > Date()  // access token is not expired
            {
                return accessToken
            }
            return nil
        }
        set {
            defaults.set(newValue, forKey: Static.AccessTokenKey)
            defaults.set(Date(timeIntervalSinceNow: 24 * 60 * 60), forKey: Static.ExpireDateKey)
        }
    }

    var backgroundTaskEnabled: Bool {
        get { return defaults.bool(forKey: Static.BackgroundTaskEnabledKey) }
        set {
            defaults.set(newValue, forKey: Static.BackgroundTaskEnabledKey)
        }
    }

    var hideAlwaysOnTopThread: Bool {
        get { return defaults.bool(forKey: Static.HideAlwaysOnTopThreadKey) }
        set {
            defaults.set(newValue, forKey: Static.HideAlwaysOnTopThreadKey)
        }
    }

    var showSignature: Bool {
        get { return defaults.bool(forKey: Static.ShowSignatureKey) }
        set {
            defaults.set(newValue, forKey: Static.ShowSignatureKey)
        }
    }

    var eulaAgreed: Bool {
        get { return defaults.bool(forKey: Static.EulaAgreedKey) }
        set {
            defaults.set(newValue, forKey: Static.EulaAgreedKey)
        }
    }

    var sortMode: SMThread.ReplySortMode {
        get { return SMThread.ReplySortMode(rawValue: defaults.integer(forKey: Static.ReplySortModeKey)) ?? .oldFirst }
        set {
            defaults.set(newValue.rawValue, forKey: Static.ReplySortModeKey)
        }
    }

    var articleCountPerSection: Int {
        get { return defaults.integer(forKey: Static.ArticleCountPerSectionKey) }
        set {
            defaults.set(newValue, forKey: Static.ArticleCountPerSectionKey)
        }
    }

    var threadCountPerSection: Int {
        get { return defaults.integer(forKey: Static.ThreadCountPerSectionKey) }
        set {
            defaults.set(newValue, forKey: Static.ThreadCountPerSectionKey)
        }
    }
    
    var mailCount: Int {
        get { return defaults.integer(forKey: Static.MailCountKey) }
        set {
            defaults.set(newValue, forKey: Static.MailCountKey)
        }
    }
    
    var replyCount: Int {
        get { return defaults.integer(forKey: Static.ReplyCountKey) }
        set {
            defaults.set(newValue, forKey: Static.ReplyCountKey)
        }
    }
    
    var referCount: Int {
        get { return defaults.integer(forKey: Static.ReferCountKey) }
        set {
            defaults.set(newValue, forKey: Static.ReferCountKey)
        }
    }
    
    var rememberLast: Bool {
        get { return defaults.bool(forKey: Static.RememberLastKey) }
        set {
            defaults.set(newValue, forKey: Static.RememberLastKey)
        }
    }
    
    var displayMode:  DisplayMode {
        get { return DisplayMode(rawValue: defaults.integer(forKey: Static.DisplayModeKey))! }
        set {
            defaults.set(newValue.rawValue, forKey: Static.DisplayModeKey)
        }
    }
    
    var showAvatar: Bool {
        get { return defaults.bool(forKey: Static.ShowAvatarKey) }
        set {
            defaults.set(newValue, forKey: Static.ShowAvatarKey)
        }
    }
    
    var noPicMode: Bool {
        get { return defaults.bool(forKey: Static.NoPicModeKey) }
        set {
            defaults.set(newValue, forKey: Static.NoPicModeKey)
        }
    }
    
    var customHotSection: Bool {
        get { return defaults.bool(forKey: Static.CustomHotSectionKey) }
        set {
            defaults.set(newValue, forKey: Static.CustomHotSectionKey)
        }
    }
    
    var autoSortHotSection: Bool {
        get { return defaults.bool(forKey: Static.AutoSortHotSectionKey) }
        set {
            defaults.set(newValue, forKey: Static.AutoSortHotSectionKey)
        }
    }
    
    var availableHotSections: [Int] {
        get { return defaults.array(forKey: Static.AvailableHotSectionsKey) as? [Int] ?? [] }
        set {
            defaults.set(newValue, forKey: Static.AvailableHotSectionsKey)
        }
    }
    
    var disabledHotSections: [Int] {
        get { return defaults.array(forKey: Static.DisabledHotSectionsKey) as? [Int] ?? [] }
        set {
            defaults.set(newValue, forKey: Static.DisabledHotSectionsKey)
        }
    }
    
    var customFontScaleIndex: Int {
        get { return defaults.integer(forKey: Static.CustomFontScaleIndexKey) }
        set {
            defaults.set(newValue, forKey: Static.CustomFontScaleIndexKey)
        }
    }
    
    var fontScale: CGFloat {
        switch customFontScaleIndex {
        case 0:
            return 0.9
        case 1:
            return 0.95
        case 3:
            return 1.1
        case 4:
            return 1.2
        default:
            return 1.0
        }
    }
    
    var smallFontScale: CGFloat {
        return fontScale * 0.95
    }
    
    var largeFontScale: CGFloat {
        return fontScale * 1.1
    }
    
    enum ThreadSortMode: Int {
        case byReplyNewFirst = 0, byReplyOldFirst, byPostNewFirst, byPostOldFirst
    }
    
    var threadSortMode: ThreadSortMode {
        get {
            return ThreadSortMode(rawValue: defaults.integer(forKey: Static.ThreadSortModeKey)) ?? .byReplyNewFirst
        }
        set {
            defaults.set(newValue.rawValue, forKey: Static.ThreadSortModeKey)
        }
    }
    
    var useBoldFont: Bool {
        get {
            return defaults.bool(forKey: Static.useBoldFontKey)
        }
        set {
            defaults.set(newValue, forKey: Static.useBoldFontKey)
        }
    }
    
    var isSmallScreen: Bool {
        return Device.current.diagonal <= 4
    }
    
    var userBlacklist: [String] {
        get {
            return defaults.stringArray(forKey: Static.userBlacklistKey) ?? []
        }
        set {
            defaults.set(newValue, forKey: Static.userBlacklistKey)
        }
    }
    
    var keywordBlacklist: [String] {
        get {
            return defaults.stringArray(forKey: Static.keywordBlacklistKey) ?? []
        }
        set {
            defaults.set(newValue, forKey: Static.keywordBlacklistKey)
        }
    }
    
    var disableHapticTouch: Bool {
        get {
            return defaults.bool(forKey: Static.disableHapticTouchKey)
        }
        set {
            defaults.set(newValue, forKey: Static.disableHapticTouchKey)
        }
    }
    
    var classicReadingMode: Bool {
        get {
            return defaults.bool(forKey: Static.classicReadingModeKey)
        }
        set {
            defaults.set(newValue, forKey: Static.classicReadingModeKey)
        }
    }
    
    var forceDarkMode: Bool {
        get {
            return defaults.bool(forKey: Static.forceDarkModeKey)
        }
        set {
            defaults.set(newValue, forKey: Static.forceDarkModeKey)
        }
    }
    
    var usePlainHttp: Bool {
        get {
            return defaults.bool(forKey: Static.usePlainHttpKey)
        }
        set {
            defaults.set(newValue, forKey: Static.usePlainHttpKey)
        }
    }
    
    var httpPrefix: String {
        if usePlainHttp {
            return "http://"
        } else {
            return "https://"
        }
    }
}
