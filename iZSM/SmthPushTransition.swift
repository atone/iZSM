//
//  SmthPushTransition.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/23.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit

class SmthPushTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to) else { return }
        let containerView = transitionContext.containerView
        
        // Setup the initial view states
        containerView.addSubview(toVC.view)
        let initialFrame = transitionContext.initialFrame(for: fromVC)
        let finalFrame = transitionContext.finalFrame(for: toVC)
        toVC.view.frame = CGRect(origin: CGPoint(x: finalFrame.origin.x + finalFrame.width, y: finalFrame.origin.y), size: finalFrame.size)
        
        // Whether to animate tab bar
        let shouldAnimateTabBar = !fromVC.hidesBottomBarWhenPushed && toVC.hidesBottomBarWhenPushed
        
        let dimmingView = UIView(frame: finalFrame)
        dimmingView.backgroundColor = UIColor.black
        dimmingView.alpha = 0.0
        containerView.insertSubview(dimmingView, aboveSubview: fromVC.view)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       options: .curveLinear,
                       animations: {
                        dimmingView.alpha = 0.5
                        toVC.view.frame = finalFrame
                        fromVC.view.frame = CGRect(origin: CGPoint(x: initialFrame.origin.x - 100, y: initialFrame.origin.y), size: initialFrame.size)
                        
                        if shouldAnimateTabBar, let tabBar = toVC.tabBarController?.tabBar {
                            tabBar.frame.origin = CGPoint(x: finalFrame.width, y: finalFrame.height)
                        }
        },
                       completion: { finished in
                        dimmingView.removeFromSuperview()
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
