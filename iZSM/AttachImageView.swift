//
//  AttachImageView.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/28.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit
import SnapKit

class AttachImageView: UIView {
    
    private let imageSize: CGFloat = 100
    private let buttonSize: CGFloat = 25
    
    private let imageView = UIImageView()
    private let deleteButton = UIButton()
    
    weak var delegate: AttachImageViewDelegate?
    
    var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        self.layer.cornerRadius = 4
        self.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        deleteButton.setImage(#imageLiteral(resourceName: "delete"), for: .normal)
        deleteButton.backgroundColor = UIColor.white
        deleteButton.tintColor = UIColor.red
        deleteButton.layer.cornerRadius = buttonSize / 2
        deleteButton.clipsToBounds = true
        deleteButton.addTarget(self, action: #selector(pressDelete(_:)), for: .touchUpInside)
        addSubview(imageView)
        addSubview(deleteButton)
        
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.width.height.equalTo(imageSize)
        }
        deleteButton.snp.makeConstraints { (make) in
            make.top.right.equalToSuperview()
            make.width.height.equalTo(buttonSize)
        }
    }
    
    @objc private func pressDelete(_ sender: UIButton) {
        delegate?.deleteButtonPressed(in: self)
    }
}

protocol AttachImageViewDelegate: class {
    func deleteButtonPressed(in attachImageView: AttachImageView)
}
