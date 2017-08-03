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
    var article: SMArticle?
    weak var delegate: UserInfoViewControllerDelegate?
    
    private let idLabelFontSize: CGFloat = 20
    private let nickLabelFontSize: CGFloat = 15
    private let otherLabelFontSize: CGFloat = 13
    private let otherContentLabelFontSize: CGFloat = 13
    private let avatarWidth: CGFloat = 100
    private let margin: CGFloat = 15
    private let margin2: CGFloat = 5
    private let width: CGFloat = 280
    private let height: CGFloat = 320
    
    private let backgroundImageView = YYAnimatedImageView()
    private let backgroundView = UIView()
    
    private let avatarImageView = YYAnimatedImageView()
    private let idLabel = UILabel()
    private let nickLabel = UILabel()
    
    private let titleLabel = UILabel()
    private let levelLabel = UILabel()
    private let postsLabel = UILabel()
    private let scoreLabel = UILabel()
    private let loginLabel = UILabel()
    private let titleContentLabel = UILabel()
    private let levelContentLabel = UILabel()
    private let postsContentLabel = UILabel()
    private let scoreContentLabel = UILabel()
    private let loginContentLabel = UILabel()
    private let infoStackView = UIStackView()
    
    private let toolbar = UIToolbar()
    private let lastLoginLabel = UILabel()
    private let padding = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
    private let search = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(clickSearch(sender:)))
    private let compose = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(clickCompose(sender:)))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(nightModeChanged(_:)),
                                               name: AppTheme.kAppThemeChangedNotification,
                                               object: nil)
        setupUI()
        setupContent()
    }
    
    func updateUserInfoView(with user: SMUser?) {
        self.user = user
        setupContent()
    }
    
    @objc private func nightModeChanged(_ notification: Notification) {
        updateColor()
    }
    
    private func updateColor() {
        toolbar.barStyle = AppSetting.shared.nightMode ? UIBarStyle.black : UIBarStyle.default
        search.tintColor = AppTheme.shared.tintColor
        compose.tintColor = AppTheme.shared.tintColor
    }
    
    private func setupUI() {
        preferredContentSize = CGSize(width: width, height: height)
        view.backgroundColor = UIColor.black
        backgroundImageView.frame = view.bounds
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(backgroundImageView)
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            let blurEffect = UIBlurEffect(style: .dark)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = view.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(blurEffectView)
            backgroundView.backgroundColor = UIColor.clear
        } else {
            backgroundView.backgroundColor = UIColor.black
        }
        view.addSubview(toolbar)
        toolbar.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalTo(view)
        }
        toolbar.items = [padding]
        if delegate?.shouldEnableSearch() ?? true {
            toolbar.items?.append(search)
        }
        if delegate?.shouldEnableCompose() ?? true {
            toolbar.items?.append(compose)
        }
        view.addSubview(lastLoginLabel)
        lastLoginLabel.textColor = UIColor.gray
        lastLoginLabel.font = UIFont.systemFont(ofSize: otherContentLabelFontSize)
        lastLoginLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(toolbar)
            make.leading.equalTo(toolbar).offset(margin)
        }
        view.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalTo(view)
            make.bottom.equalTo(toolbar.snp.top)
        }
        backgroundView.addSubview(idLabel)
        idLabel.textColor = UIColor.white
        idLabel.font = UIFont.boldSystemFont(ofSize: idLabelFontSize)
        idLabel.textAlignment = .center
        idLabel.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .vertical)
        idLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .vertical)
        idLabel.snp.makeConstraints { (make) in
            make.center.equalTo(view)
        }
        backgroundView.addSubview(avatarImageView)
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                    action: #selector(tapUserImage(sender:))))
        avatarImageView.snp.makeConstraints { (make) in
            make.width.equalTo(avatarWidth)
            make.height.equalTo(avatarWidth)
            make.centerX.equalTo(view)
            make.centerY.equalTo(view).dividedBy(2)
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
            make.leading.equalTo(backgroundView).offset(margin)
            make.trailing.equalTo(backgroundView).offset(-margin)
            make.bottom.equalTo(backgroundView).offset(-margin)
        }
        titleLabel.textColor = UIColor.lightGray
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: otherLabelFontSize)
        levelLabel.textColor = UIColor.lightGray
        levelLabel.textAlignment = .center
        levelLabel.font = UIFont.systemFont(ofSize: otherLabelFontSize)
        postsLabel.textColor = UIColor.lightGray
        postsLabel.textAlignment = .center
        postsLabel.font = UIFont.systemFont(ofSize: otherLabelFontSize)
        scoreLabel.textColor = UIColor.lightGray
        scoreLabel.textAlignment = .center
        scoreLabel.font = UIFont.systemFont(ofSize: otherLabelFontSize)
        loginLabel.textColor = UIColor.lightGray
        loginLabel.textAlignment = .center
        loginLabel.font = UIFont.systemFont(ofSize: otherLabelFontSize)
        backgroundView.addSubview(titleContentLabel)
        backgroundView.addSubview(levelContentLabel)
        backgroundView.addSubview(postsContentLabel)
        backgroundView.addSubview(scoreContentLabel)
        backgroundView.addSubview(loginContentLabel)
        titleContentLabel.textColor = UIColor.white
        titleContentLabel.textAlignment = .center
        titleContentLabel.font = UIFont.systemFont(ofSize: otherContentLabelFontSize)
        levelContentLabel.textColor = UIColor.white
        levelContentLabel.textAlignment = .center
        levelContentLabel.font = UIFont.systemFont(ofSize: otherContentLabelFontSize)
        postsContentLabel.textColor = UIColor.white
        postsContentLabel.textAlignment = .center
        postsContentLabel.font = UIFont.systemFont(ofSize: otherContentLabelFontSize)
        postsContentLabel.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .vertical)
        postsContentLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .vertical)
        scoreContentLabel.textColor = UIColor.white
        scoreContentLabel.textAlignment = .center
        scoreContentLabel.font = UIFont.systemFont(ofSize: otherContentLabelFontSize)
        loginContentLabel.textColor = UIColor.white
        loginContentLabel.textAlignment = .center
        loginContentLabel.font = UIFont.systemFont(ofSize: otherContentLabelFontSize)
        titleContentLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(titleLabel)
            make.bottom.equalTo(titleLabel.snp.top).offset(-margin2)
        }
        levelContentLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(levelLabel)
            make.bottom.equalTo(levelLabel.snp.top).offset(-margin2)
        }
        postsContentLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(postsLabel)
            make.bottom.equalTo(postsLabel.snp.top).offset(-margin2)
        }
        scoreContentLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(scoreLabel)
            make.bottom.equalTo(scoreLabel.snp.top).offset(-margin2)
        }
        loginContentLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(loginLabel)
            make.bottom.equalTo(loginLabel.snp.top).offset(-margin2)
        }
        
        backgroundView.addSubview(nickLabel)
        nickLabel.textColor = UIColor.white
        nickLabel.font = UIFont.systemFont(ofSize: nickLabelFontSize)
        nickLabel.textAlignment = .center
        nickLabel.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .vertical)
        nickLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .vertical)
        nickLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(idLabel)
            make.top.equalTo(idLabel.snp.bottom)
            make.bottom.equalTo(postsContentLabel.snp.top)
            make.width.lessThanOrEqualToSuperview()
        }
        updateColor()
    }
    
    private func setupContent() {
        if let user = user {
            setContent(hidden: false)
            let genderSymbol = user.gender == 0 ? "♂" : "♀"
            idLabel.text = "\(user.id) \(genderSymbol)"
            nickLabel.text = user.nick
            let defaultImage = user.gender == 0 ? #imageLiteral(resourceName: "face_default_m") : #imageLiteral(resourceName: "face_default_f")
            avatarImageView.setImageWith(SMUser.faceURL(for: user.id, withFaceURL: user.faceURL),
                                         placeholder: defaultImage,
                                         options: [.progressiveBlur, .setImageWithFadeAnimation])
            backgroundImageView.setImageWith(SMUser.faceURL(for: user.id, withFaceURL: user.faceURL),
                                             placeholder: defaultImage,
                                             options: [.progressiveBlur, .setImageWithFadeAnimation])
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
            lastLoginLabel.text = "上次登录: \(user.lastLoginTime.shortDateString)"
        } else {
            avatarImageView.image = #imageLiteral(resourceName: "face_default")
            backgroundImageView.image = #imageLiteral(resourceName: "face_default")
            setContent(hidden: true)
        }
    }
    
    private func setContent(hidden: Bool) {
        avatarImageView.isHidden = hidden
        idLabel.isHidden = hidden
        nickLabel.isHidden = hidden
        titleLabel.isHidden = hidden
        levelLabel.isHidden = hidden
        postsLabel.isHidden = hidden
        scoreLabel.isHidden = hidden
        loginLabel.isHidden = hidden
        titleContentLabel.isHidden = hidden
        levelContentLabel.isHidden = hidden
        postsContentLabel.isHidden = hidden
        scoreContentLabel.isHidden = hidden
        loginContentLabel.isHidden = hidden
    }
    
    @objc private func clickCompose(sender: UIBarButtonItem) {
        delegate?.userInfoViewController(self, didClickCompose: sender)
    }
    
    @objc private func clickSearch(sender: UIBarButtonItem) {
        delegate?.userInfoViewController(self, didClickSearch: sender)
    }
    
    @objc private func tapUserImage(sender: UIGestureRecognizer) {
        delegate?.userInfoViewController(self, didTapUserImageView: avatarImageView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avatarImageView.layer.cornerRadius = avatarWidth / 2
    }
}

protocol UserInfoViewControllerDelegate: class {
    func userInfoViewController(_ controller: UserInfoViewController, didClickSearch button: UIBarButtonItem)
    func userInfoViewController(_ controller: UserInfoViewController, didClickCompose button: UIBarButtonItem)
    func userInfoViewController(_ controller: UserInfoViewController, didTapUserImageView imageView: UIImageView)
    func shouldEnableCompose() -> Bool
    func shouldEnableSearch() -> Bool
}
