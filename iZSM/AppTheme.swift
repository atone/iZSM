//
//  AppTheme.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/15.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit

class AppTheme {
    static let shared = AppTheme()
    static let kAppThemeChangedNotification = Notification.Name("AppThemeChangedNotification")
    
    private let setting = AppSetting.shared
    private init() {}
    
    var dayTextColor: UIColor {
        return UIColor.black
    }
    
    var nightTextColor: UIColor {
        return UIColor.lightGray
    }
    
    var dayLightTextColor: UIColor {
        return UIColor.gray
    }
    
    var nightLightTextColor: UIColor {
        return UIColor.gray
    }
    
    var absoluteTintColor: UIColor {
        return UIColor(red: 0/255.0, green: 139/255.0, blue: 203/255.0, alpha: 1)
    }
    
    var nightAbsoluteTintColor: UIColor {
        return UIColor(red: 215/255.0, green: 215/255.0, blue: 214/255.0, alpha: 1)
    }
    
    var dayLightBackgroundColor: UIColor {
        return UIColor.groupTableViewBackground
    }
    
    var nightLightBackgroundColor: UIColor {
        return UIColor(red: 20/255.0, green: 20/255.0, blue: 20/255.0, alpha: 1)
    }
    
    var backgroundColor: UIColor {
        if setting.nightMode {
            return UIColor(red: 40/255.0, green: 40/255.0, blue: 41/255.0, alpha: 1)
        } else {
            return UIColor.white
        }
    }
    
    var selectedBackgroundColor: UIColor {
        if setting.nightMode {
            return UIColor.darkGray
        } else {
            return UIColor(red: 217/255.0, green: 217/255.0, blue: 217/255.0, alpha: 1)
        }
    }
    
    var textColor: UIColor {
        if setting.nightMode {
            return nightTextColor
        } else {
            return dayTextColor
        }
    }
    
    var lightTextColor: UIColor {
        if setting.nightMode {
            return nightLightTextColor
        } else {
            return dayLightTextColor
        }
    }
    
    var tintColor: UIColor {
        if setting.nightMode {
            return nightAbsoluteTintColor
        } else {
            return absoluteTintColor
        }
    }
    
    var naviContentColor: UIColor {
        if setting.nightMode {
            return UIColor(red: 215/255.0, green: 215/255.0, blue: 214/255.0, alpha: 1)
        } else {
            return UIColor.white
        }
    }
    
    var naviBackgroundColor: UIColor {
        if setting.nightMode {
            return UIColor(red: 40/255.0, green: 40/255.0, blue: 41/255.0, alpha: 1)
        } else {
            return absoluteTintColor
        }
    }
    
    var tabBackgroundColor: UIColor {
        if setting.nightMode {
            return UIColor(red: 40/255.0, green: 40/255.0, blue: 41/255.0, alpha: 1)
        } else {
            return UIColor.groupTableViewBackground
        }
    }
    
    var lightBackgroundColor: UIColor {
        if setting.nightMode {
            return nightLightBackgroundColor
        } else {
            return dayLightBackgroundColor
        }
    }
    
    var redColor: UIColor {
        if setting.nightMode {
            return UIColor.red.withAlphaComponent(0.6)
        } else {
            return UIColor.red
        }
    }
    
    var dayUrlColor: UIColor {
        return absoluteTintColor
    }
    
    var nightUrlColor: UIColor {
        return nightAbsoluteTintColor
    }
    
    var dayActiveUrlColor: UIColor {
        return dayUrlColor.withAlphaComponent(0.6)
    }
    
    var nightActiveUrlColor: UIColor {
        return nightUrlColor.withAlphaComponent(0.6)
    }
}
