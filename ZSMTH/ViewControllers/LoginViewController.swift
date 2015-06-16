//
//  LoginViewController.swift
//  NewSmth
//
//  Created by Naitong Yu on 14/10/16.
//  Copyright (c) 2014 Naitong Yu. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var usernameField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!

    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var loginButton: UIButton!
    
    let api = SmthAPI()
    let setting = AppSetting.sharedSetting()

    var delegate: LoginViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        usernameField.delegate = self
        passwordField.delegate = self
        
        usernameField.text = setting.username
        passwordField.text = setting.password
    }

    override func viewDidAppear(animated: Bool) {
        if !setting.eulaAgreed {
            if let eula = storyboard?.instantiateViewControllerWithIdentifier("EulaViewController") as? EulaViewController {
                presentViewController(eula, animated: true, completion: nil)
            }
        }
    }

    @IBAction func login(sender: UIButton) {
        let username = usernameField?.text
        let password = passwordField?.text

        if username == "" || password == "" {
            return
        }

        spinner.startAnimating()
        networkActivityIndicatorStart()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let loginSuccess = self.api.loginBBS(username: username!, password: password!) == 0 ? false : true
            dispatch_async(dispatch_get_main_queue()) {
                self.spinner?.stopAnimating()
                networkActivityIndicatorStop()
                if loginSuccess && self.api.errorCode == 0 {
                    self.setting.username = username
                    self.setting.password = password
                    self.setting.accessToken = self.api.accessToken
                    self.dismissViewControllerAnimated(false, completion: nil)
                    self.delegate?.loginDidSuccessful()
                } else {
                    self.lockAnimationForView(self.passwordField)
                    self.api.displayErrorIfNeeded()
                }
            }
        }
    }
    

    func lockAnimationForView(view: UIView) {
        let lbl = view.layer
        let posLbl = lbl.position
        let y = CGPointMake(posLbl.x-10, posLbl.y)
        let x = CGPointMake(posLbl.x+10, posLbl.y)
        
        let animation = CABasicAnimation(keyPath: "position")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.fromValue = NSValue(CGPoint: x)
        animation.toValue = NSValue(CGPoint: y)
        animation.autoreverses = true
        animation.duration = 0.08
        animation.repeatCount = 3
        lbl.addAnimation(animation, forKey: nil)
    }
    
    //MARK: - UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == self.usernameField {
            if count(textField.text) > 0 {
                self.passwordField.becomeFirstResponder()
            }
        } else {
            self.passwordField.resignFirstResponder()
            self.login(self.loginButton)
        }
        return false
    }

}

protocol LoginViewControllerDelegate {
    func loginDidSuccessful()
}
