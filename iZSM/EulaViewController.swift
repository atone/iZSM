//
//  EulaViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/21.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit

class EulaViewController: UIViewController {
    
    private let webView = UIWebView()
    private let setting = AppSetting.shared
    
    weak var delegate: EulaViewControllerDelegate?

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
        delegate?.userAcceptedEula(self)
    }
    
    func declineTapped(sender: UIBarButtonItem) {
        delegate?.userDeclinedEula(self)
    }
}

protocol EulaViewControllerDelegate: class {
    func userAcceptedEula(_ controller: EulaViewController)
    func userDeclinedEula(_ controller: EulaViewController)
}
