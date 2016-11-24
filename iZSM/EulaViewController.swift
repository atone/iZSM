//
//  EulaViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/21.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit

class EulaViewController: UIViewController {
    
    let webView = UIWebView()
    let setting = AppSetting.sharedSetting

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        view.addSubview(webView)
        webView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        
        let urlPath = Bundle.main.path(forResource: "EULA", ofType: "rtf")
        let url = URL(fileURLWithPath: urlPath!)
        let request = URLRequest(url: url)
        webView.loadRequest(request)
        
        title = "水木社区管理规则"
        let agreeButton = UIBarButtonItem(title: "同意", style: .plain, target: self, action: #selector(agreeTapped(sender:)))
        let declineButton = UIBarButtonItem(title: "拒绝", style: .plain, target: self, action: #selector(declineTapped(sender:)))
        navigationItem.rightBarButtonItem = agreeButton
        navigationItem.leftBarButtonItem = declineButton
    }
    
    func agreeTapped(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
        print("agree tapped")
        // set agree to true
        setting.eulaAgreed = true
    }
    
    func declineTapped(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: nil, message: "您必须同意《水木社区管理规则》才能使用本软件。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
        print("decline tapped")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
