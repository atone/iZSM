//
//  BoxImageView.swift
//  iZSM
//
//  Created by Naitong Yu on 2019/10/20.
//  Copyright © 2019 Naitong Yu. All rights reserved.
//

import UIKit
import YYKit

class BoxImageView: UIView {
    
    private static let blankWidth: CGFloat = 4
    
    let imageViews: [YYAnimatedImageView]
    
    init(imageURLs: [URL], target: Any?, action: Selector) {
        var imageViews = [YYAnimatedImageView]()
        for url in imageURLs {
            let imageView = YYAnimatedImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.setImageWith(url, placeholder: UIImage(named: "loading"), options: [.setImageWithFadeAnimation])
            imageView.isUserInteractionEnabled = true
            imageView.addGestureRecognizer(UITapGestureRecognizer(target: target, action: action))
            imageViews.append(imageView)
        }
        self.imageViews = imageViews
        
        super.init(frame: .zero)
        
        for imageView in imageViews {
            addSubview(imageView)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        var imageViews = self.imageViews
        var Y: CGFloat = 0
        let headImageHeight = (bounds.width - Self.blankWidth) / 2
        
        switch imageViews.count % 3 {
        case 1:
            let first = imageViews.remove(at: 0)
            first.frame = CGRect(x: 0, y: Y, width: bounds.width, height: headImageHeight)
            Y += (headImageHeight + Self.blankWidth)
        case 2:
            let first = imageViews.remove(at: 0)
            first.frame = CGRect(x: 0, y: Y, width: headImageHeight, height: headImageHeight)
            let second = imageViews.remove(at: 0)
            second.frame = CGRect(x: headImageHeight + Self.blankWidth, y: Y, width: headImageHeight, height: headImageHeight)
            Y += (headImageHeight + Self.blankWidth)
        default:
            break
        }
        
        for (index, imageView) in imageViews.enumerated() {
            let length = (bounds.width - 2 * Self.blankWidth) / 3
            let offset = (length + Self.blankWidth) * CGFloat(index / 3)
            let X = CGFloat(index % 3) * (length + Self.blankWidth)
            imageView.frame = CGRect(x: X, y: Y + offset, width: length, height: length)
        }
    }
    
    func imageHeight(boundingWidth: CGFloat) -> CGFloat {
        return BoxImageView.imageHeight(count: imageViews.count, boundingWidth: boundingWidth)
    }
    
    static func imageHeight(count: Int, boundingWidth: CGFloat) -> CGFloat {
        var totalHeight: CGFloat = 0
        if count > 0 {
            let oneImageHeight = (boundingWidth - 2 * blankWidth) / 3
            totalHeight = (oneImageHeight + blankWidth) * CGFloat(count / 3) - blankWidth
            switch count % 3 {
            case 1, 2:
                let headImageHeight = (boundingWidth - blankWidth) / 2
                totalHeight += (headImageHeight + blankWidth)
            default:
                break
            }
        }
        let scale = UIScreen.main.scale
        return floor(totalHeight * scale) / scale
    }
}
