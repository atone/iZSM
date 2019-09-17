//
//  LoginViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/21.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SnapKit
import OnePasswordExtension

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    private let logoView = UIImageView(image: UIImage(named: "Logo"))
    private let usernameField = UITextField()
    private let passwordField = UITextField()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let loginButton = UIButton(type: .system)
    private let containerView = UIView()
    private let lineView = UIView()
    
    private let api = SmthAPI()
    private let setting = AppSetting.shared
    
    weak var delegate: LoginViewControllerDelegate?
    
    func setupUI() {
        title = "欢迎使用最水木"
        view.backgroundColor = UIColor.systemBackground
        logoView.clipsToBounds = true
        view.addSubview(logoView)
        
        containerView.backgroundColor = UIColor.clear
        containerView.layer.borderColor = UIColor.lightGray.cgColor
        containerView.layer.borderWidth = 1
        containerView.layer.cornerRadius = 4
        containerView.layer.masksToBounds = true
        view.addSubview(containerView)
        lineView.backgroundColor = UIColor.lightGray
        containerView.addSubview(lineView)
        
        usernameField.borderStyle = .none
        usernameField.placeholder = "用户名"
        usernameField.autocapitalizationType = .none
        usernameField.autocorrectionType = .no
        usernameField.keyboardType = .asciiCapable
        usernameField.returnKeyType = .next
        containerView.addSubview(usernameField)
        
        passwordField.borderStyle = .none
        passwordField.isSecureTextEntry = true
        passwordField.placeholder = "密码"
        passwordField.autocapitalizationType = .none
        passwordField.returnKeyType = .done
        containerView.addSubview(passwordField)
        
        view.addSubview(spinner)
        
        loginButton.setTitle("登录", for: .normal)
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        loginButton.addTarget(self, action: #selector(login(_:)), for: .touchUpInside)
        view.addSubview(loginButton)
        
        loginButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(view)
            make.top.equalTo(containerView.snp.bottom).offset(10)
        }
        spinner.snp.makeConstraints { (make) in
            make.right.equalTo(loginButton.snp.left).offset(-10)
            make.centerY.equalTo(loginButton)
        }
        
        containerView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(150)
            make.height.equalTo(60)
        }
        
        lineView.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalTo(1)
            make.center.equalToSuperview()
        }
        
        usernameField.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(5)
            make.top.equalToSuperview()
            make.trailing.equalToSuperview().offset(-5)
            make.height.equalTo(passwordField)
        }
        
        passwordField.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(5)
            make.bottom.equalToSuperview()
            make.trailing.equalToSuperview().offset(-5)
            make.top.equalTo(usernameField.snp.bottom)
        }
        
        logoView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().dividedBy(2)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        logoView.layer.cornerRadius = logoView.frame.width / 4
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        isModalInPresentation = true
        
        usernameField.delegate = self
        passwordField.delegate = self
        usernameField.text = setting.username
        passwordField.text = setting.password
        
        if OnePasswordExtension.shared().isAppExtensionAvailable() {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "onepassword"), style: .plain, target: self, action: #selector(findLoginFrom1Password(_:)))
        }
    }
    
    @objc private func findLoginFrom1Password(_ sender: UIBarButtonItem) {
        OnePasswordExtension.shared().findLogin(forURLString: "newsmth.net", for: self, sender: sender) { (loginDictionary, error) in
            if loginDictionary == nil {
                return
            }
            self.usernameField.text = loginDictionary?[AppExtensionUsernameKey] as? String
            self.passwordField.text = loginDictionary?[AppExtensionPasswordKey] as? String
            
            self.login(nil)
        }
    }
    
    @objc private func login(_ sender: UIButton?) {
        let username = usernameField.text
        let password = passwordField.text
        
        if username == "" || password == "" {
            return
        }
        
        spinner.startAnimating()
        networkActivityIndicatorStart()
        DispatchQueue.global().async {
            let loginSuccess = self.api.loginBBS(username: username!, password: password!) == 0 ? false : true
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                networkActivityIndicatorStop()
                if loginSuccess && self.api.errorCode == 0 {
                    self.setting.username = username
                    self.setting.password = password
                    self.setting.accessToken = self.api.accessToken
                    self.delegate?.loginDidSuccessful()
                } else {
                    self.lockAnimation(forView: self.passwordField)
                    self.api.displayErrorIfNeeded()
                }
            }
        }
    }
    
    func lockAnimation(forView view: UIView) {
        let lbl = view.layer
        let posLbl = lbl.position
        let y = CGPoint(x: posLbl.x-10, y: posLbl.y)
        let x = CGPoint(x: posLbl.x+10, y: posLbl.y)
        
        let animation = CABasicAnimation(keyPath: "position")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.fromValue = NSValue(cgPoint: x)
        animation.toValue = NSValue(cgPoint: y)
        animation.autoreverses = true
        animation.duration = 0.08
        animation.repeatCount = 3
        lbl.add(animation, forKey: nil)
    }
    
    //MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.usernameField {
            if textField.text!.count > 0 {
                self.passwordField.becomeFirstResponder()
            }
        } else {
            self.passwordField.resignFirstResponder()
            self.login(self.loginButton)
        }
        return false
    }
}

protocol LoginViewControllerDelegate: class {
    func loginDidSuccessful()
}
