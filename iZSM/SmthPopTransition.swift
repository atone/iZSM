//
//  SmthPopTransition.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/22.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit

class SmthPopTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to) else { return }
        let containerView = transitionContext.containerView
        
        // Setup the initial view states
        containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
        let finalFrame = transitionContext.finalFrame(for: toVC)
        toVC.view.frame = CGRect(origin: CGPoint(x: finalFrame.origin.x - 100, y: finalFrame.origin.y), size: finalFrame.size)
        
        // Whether to animate tab bar
        var shouldAnimateTabBar = false
        if let tabBar = toVC.tabBarController?.tabBar, !tabBar.isHidden, tabBar.frame.origin.x < 0 {
            shouldAnimateTabBar = true
            tabBar.frame.origin = CGPoint(x: 0, y: finalFrame.height)
        }
        
        let dimmingView = UIView(frame: finalFrame)
        dimmingView.backgroundColor = UIColor.black
        dimmingView.alpha = 0.5
        containerView.insertSubview(dimmingView, aboveSubview: toVC.view)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       options: .curveLinear,
                       animations: {
                        dimmingView.alpha = 0
                        toVC.view.frame = finalFrame
                        fromVC.view.frame.origin.x += finalFrame.width
                        
                        if shouldAnimateTabBar, let tabBar = toVC.tabBarController?.tabBar {
                            tabBar.frame.origin = CGPoint(x: 0, y: finalFrame.height - tabBar.frame.height)
                        }
        },
                       completion: { finished in
                        dimmingView.removeFromSuperview()
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
