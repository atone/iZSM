//
//  EulaViewController.swift
//  zsmth
//
//  Created by Naitong Yu on 15/5/29.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class EulaViewController: UIViewController {

    private let setting = AppSetting.sharedSetting()
    
    @IBAction func agreeTapped(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
        setting.eulaAgreed = true
    }


    @IBAction func declineTapped(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: nil, message: "您必须同意《水木社区管理规则》才能使用本软件。", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "确定", style: .Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    

}
