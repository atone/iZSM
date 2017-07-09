//
//  UserInfoViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/9.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit
import YYKit
import SnapKit

class UserInfoViewController: UIViewController {
    
    var user: SMUser?
    
    let containerView = UIView()
    let backgroundView = UIView()
    
    let avatarImageView = UIImageView()
    let idLabel = UILabel()
    let nickLabel = UILabel()
    
    let titleLabel = UILabel()
    let levelLabel = UILabel()
    let postsLabel = UILabel()
    let scoreLabel = UILabel()
    let loginLabel = UILabel()
    let titleContentLabel = UILabel()
    let levelContentLabel = UILabel()
    let postsContentLabel = UILabel()
    let scoreContentLabel = UILabel()
    let loginContentLabel = UILabel()
    
    let infoStackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupContent()
    }
    
    func setupUI() {
        view.backgroundColor = UIColor.white
        view.addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(view)
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
        containerView.addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.black
        backgroundView.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalTo(containerView)
            make.height.equalTo(containerView.snp.height).dividedBy(2)
        }
        backgroundView.addSubview(idLabel)
        idLabel.textColor = UIColor.white
        idLabel.font = UIFont.boldSystemFont(ofSize: 20)
        idLabel.snp.makeConstraints { (make) in
            make.center.equalTo(backgroundView)
        }
        backgroundView.addSubview(avatarImageView)
        avatarImageView.clipsToBounds = true
        avatarImageView.snp.makeConstraints { (make) in
            make.width.equalTo(100)
            make.height.equalTo(100)
            make.centerX.equalTo(backgroundView)
            make.centerY.equalTo(backgroundView).dividedBy(2)
        }
        backgroundView.addSubview(nickLabel)
        nickLabel.textColor = UIColor.white
        nickLabel.font = UIFont.systemFont(ofSize: 15)
        nickLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(idLabel)
            make.centerY.equalTo(idLabel).offset(50)
        }
        backgroundView.addSubview(infoStackView)
        infoStackView.axis = .horizontal
        infoStackView.distribution = .equalSpacing
        infoStackView.addArrangedSubview(titleLabel)
        infoStackView.addArrangedSubview(levelLabel)
        infoStackView.addArrangedSubview(postsLabel)
        infoStackView.addArrangedSubview(scoreLabel)
        infoStackView.addArrangedSubview(loginLabel)
        infoStackView.snp.makeConstraints { (make) in
            make.leading.equalTo(backgroundView).offset(20)
            make.trailing.equalTo(backgroundView).offset(-20)
            make.bottom.equalTo(backgroundView).offset(-20)
        }
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        levelLabel.textColor = UIColor.white
        levelLabel.font = UIFont.systemFont(ofSize: 14)
        postsLabel.textColor = UIColor.white
        postsLabel.font = UIFont.systemFont(ofSize: 14)
        scoreLabel.textColor = UIColor.white
        scoreLabel.font = UIFont.systemFont(ofSize: 14)
        loginLabel.textColor = UIColor.white
        loginLabel.font = UIFont.systemFont(ofSize: 14)
        
    }
    
    func setupContent() {
        if let user = user {
            let genderSymbol = user.gender == 0 ? "♂" : "♀"
            idLabel.text = "\(user.id) \(genderSymbol)"
            nickLabel.text = user.nick
            let defaultImage = user.gender == 0 ? #imageLiteral(resourceName: "face_default_m") : #imageLiteral(resourceName: "face_default_f")
            avatarImageView.setImageWith(SMUser.faceURL(for: user.id, withFaceURL: user.faceURL),
                                         placeholder: defaultImage)
            titleLabel.text = "身份"
            levelLabel.text = "等级"
            postsLabel.text = "发帖"
            scoreLabel.text = "积分"
            loginLabel.text = "登录"
            titleContentLabel.text = user.title
            levelContentLabel.text = "\(user.life)(\(user.level))"
            postsContentLabel.text = "\(user.posts)"
            scoreContentLabel.text = "\(user.score)"
            loginContentLabel.text = "\(user.loginCount)"
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avatarImageView.layer.cornerRadius = 50
    }
}
