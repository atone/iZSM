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
import SmthConnection

class UserInfoViewController: UIViewController {
    
    var user: SMUser?
    var article: Article?
    weak var delegate: UserInfoViewControllerDelegate?
    
    private let idLabelFontSize: CGFloat = 20
    private let nickLabelFontSize: CGFloat = 15
    private let otherLabelFontSize: CGFloat = 13
    private let otherContentLabelFontSize: CGFloat = 13
    private let avatarWidth: CGFloat = 100
    private let margin: CGFloat = 15
    private let margin2: CGFloat = 5
    private let width: CGFloat = 300
    private let height: CGFloat = 320
    
    private var backgroundImageView: YYAnimatedImageView?
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
    
    private let toolbar = UIToolbar()
    private let lastLoginLabel = UILabel()
    private let padding = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
    private let search = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(clickSearch(_:)))
    private let compose = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(clickCompose(_:)))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupContent()
    }
    
    func updateUserInfoView(with user: SMUser?) {
        self.user = user
        setupContent()
    }
    
    private func setupUI() {
        overrideUserInterfaceStyle = .dark
        preferredContentSize = CGSize(width: width, height: height)
        view.backgroundColor = UIColor.systemBackground
        if !UIAccessibility.isReduceTransparencyEnabled {
            backgroundImageView = YYAnimatedImageView()
            backgroundImageView!.frame = view.bounds
            backgroundImageView!.contentMode = .scaleAspectFill
            backgroundImageView!.clipsToBounds = true
            backgroundImageView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(backgroundImageView!)
            let blurEffect = UIBlurEffect(style: .systemMaterial)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = view.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(blurEffectView)
        }
        view.addSubview(toolbar)
        toolbar.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(view)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        toolbar.items = [padding]
        if delegate?.shouldEnableSearch() ?? true {
            toolbar.items?.append(search)
        }
        if delegate?.shouldEnableCompose() ?? true {
            toolbar.items?.append(compose)
        }
        view.addSubview(lastLoginLabel)
        configure(lastLoginLabel, color: .secondaryLabel, size: otherContentLabelFontSize)
        lastLoginLabel.isUserInteractionEnabled = true
        lastLoginLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clickLastLogin(_:))))
        lastLoginLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(toolbar)
            make.leading.equalTo(toolbar.safeAreaLayoutGuide).offset(margin)
            make.trailing.lessThanOrEqualTo(toolbar.safeAreaLayoutGuide).offset(-margin)
        }
        view.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(toolbar.snp.top)
        }
        backgroundView.addSubview(avatarImageView)
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                    action: #selector(tapUserImage(_:))))
        avatarImageView.snp.makeConstraints { (make) in
            make.width.equalTo(avatarWidth)
            make.height.equalTo(avatarWidth)
            make.centerX.equalTo(backgroundView)
            make.centerY.equalTo(backgroundView).dividedBy(2)
        }
        
        configure(idLabel, color: .label, size: idLabelFontSize)
        configure(nickLabel, color: .label, size: nickLabelFontSize)
        nickLabel.numberOfLines = 2
        let upperStackView = makeStackView(axis: .vertical, subViews: [idLabel, nickLabel])
        
        configure(titleLabel, color: .secondaryLabel, size: otherLabelFontSize)
        configure(levelLabel, color: .secondaryLabel, size: otherLabelFontSize)
        configure(postsLabel, color: .secondaryLabel, size: otherLabelFontSize)
        configure(scoreLabel, color: .secondaryLabel, size: otherLabelFontSize)
        configure(loginLabel, color: .secondaryLabel, size: otherLabelFontSize)
        configure(titleContentLabel, color: .label, size: otherContentLabelFontSize)
        configure(levelContentLabel, color: .label, size: otherContentLabelFontSize)
        configure(postsContentLabel, color: .label, size: otherContentLabelFontSize)
        configure(scoreContentLabel, color: .label, size: otherContentLabelFontSize)
        configure(loginContentLabel, color: .label, size: otherContentLabelFontSize)
        let titleStackView = makeStackView(axis: .vertical, subViews: [titleContentLabel, titleLabel])
        let levelStackView = makeStackView(axis: .vertical, subViews: [levelContentLabel, levelLabel])
        let postsStackView = makeStackView(axis: .vertical, subViews: [postsContentLabel, postsLabel])
        let scoreStackView = makeStackView(axis: .vertical, subViews: [scoreContentLabel, scoreLabel])
        let loginStackView = makeStackView(axis: .vertical, subViews: [loginContentLabel, loginLabel])
        let lowerStackView = makeStackView(axis: .horizontal, subViews: [titleStackView, levelStackView, postsStackView, scoreStackView, loginStackView])
        
        let infoStackView = makeStackView(axis: .vertical, subViews: [upperStackView, lowerStackView])
        infoStackView.alignment = .fill
        
        backgroundView.addSubview(infoStackView)
        infoStackView.snp.makeConstraints { (make) in
            make.leading.equalTo(backgroundView).offset(margin)
            make.trailing.equalTo(backgroundView).offset(-margin)
            make.bottom.equalTo(backgroundView).offset(-margin)
            make.top.equalTo(backgroundView.snp.centerY)
        }
    }
    
    private func configure(_ label: UILabel, color: UIColor, size: CGFloat, bold: Bool = false) {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = color
        if bold {
            label.font = .boldSystemFont(ofSize: size)
        } else {
            label.font = .systemFont(ofSize: size)
        }
        label.textAlignment = .center
    }
    
    private func makeStackView(axis: NSLayoutConstraint.Axis, subViews: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: subViews)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .equalCentering
        stackView.alignment = .center
        stackView.spacing = margin2
        stackView.axis = axis
        return stackView
    }
    
    private func setupContent() {
        if let user = user {
            setContent(hidden: false)
            let genderSymbol = user.gender == 0 ? "♂" : "♀"
            idLabel.text = "\(user.id) \(genderSymbol)"
            nickLabel.text = user.nick
            let defaultImage = user.gender == 0 ? UIImage(named: "face_default_m") : UIImage(named: "face_default_f")
            avatarImageView.setImageWith(SmthAPI.shared.faceURL(for: user.id, withFaceURL: user.faceURL),
                                         placeholder: defaultImage)
            backgroundImageView?.setImageWith(SmthAPI.shared.faceURL(for: user.id, withFaceURL: user.faceURL),
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
            lastLoginLabel.text = "上次登录: \(user.lastLoginTime.shortDateString)"
        } else {
            avatarImageView.image = UIImage(named: "face_default")
            backgroundImageView?.image = UIImage(named: "face_default")
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
        lastLoginLabel.isHidden = hidden
    }
    
    @objc private func clickLastLogin(_ sender: UIGestureRecognizer) {
        if let user = user, let text = lastLoginLabel.text {
            if text.starts(with: "上次登录") {
                lastLoginLabel.text = "注册时间: \(user.firstLoginTime.shortDateString)"
            } else {
                lastLoginLabel.text = "上次登录: \(user.lastLoginTime.shortDateString)"
            }
        }
    }
    
    @objc private func clickCompose(_ sender: UIBarButtonItem) {
        delegate?.userInfoViewController(self, didClickCompose: sender)
    }
    
    @objc private func clickSearch(_ sender: UIBarButtonItem) {
        delegate?.userInfoViewController(self, didClickSearch: sender)
    }
    
    @objc private func tapUserImage(_ sender: UIGestureRecognizer) {
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
