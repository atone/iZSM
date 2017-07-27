//
//  NTNavigationController.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/13.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit

class NTNavigationController: UINavigationController {
    
    private let setting = AppSetting.shared
    
    fileprivate var interactivePopTransition: UIPercentDrivenInteractiveTransition!
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if setting.portraitLock {
            return [.portrait, .portraitUpsideDown]
        } else {
            return .all
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        changeColor()
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeChanged(_:)), name: AppTheme.kAppThemeChangedNotification, object: nil)
    }
    
    @objc private func nightModeChanged(_ notification: Notification) {
        changeColor()
    }
    
    private func changeColor() {
        navigationBar.barStyle = .black
        navigationBar.tintColor = AppTheme.shared.naviContentColor
        navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: AppTheme.shared.naviContentColor]
        navigationBar.barTintColor = AppTheme.shared.naviBackgroundColor
    }
}

extension NTNavigationController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if navigationController.viewControllers.count > 1 { // do not add gesture for the root view controller
            addPanGesture(viewController)
        }
        
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .pop {
            return SmthPopTransition()
        } else if operation == .push {
            return SmthPushTransition()
        } else {
            return nil
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if animationController.isKind(of: SmthPopTransition.self), interactivePopTransition != nil {
            return interactivePopTransition
        } else {
            return nil
        }
    }
    
    func addPanGesture(_ viewController: UIViewController) {
        if let swipePopVC = viewController as? SwipePopable, swipePopVC.swipePopGesture == nil {
            let popRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanRecognizer(_:)))
            popRecognizer.delegate = self
            viewController.view.addGestureRecognizer(popRecognizer)
            swipePopVC.swipePopGesture = popRecognizer
        }
    }
    
    func handlePanRecognizer(_ recognizer: UIPanGestureRecognizer) {
        // Calculate how far the user has dragged across the view
        let translation = recognizer.translation(in: self.view).x
        let velocity = recognizer.velocity(in: self.view).x
        var progress = translation / self.view.bounds.width
        progress = min(1, max(0, progress))
        
        if recognizer.state == .began {
            // Create a interactive transition and pop the view controller
            self.interactivePopTransition = UIPercentDrivenInteractiveTransition()
            self.interactivePopTransition.completionSpeed = 0.999
            self.popViewController(animated: true)
        } else if recognizer.state == .changed {
            // Update the interactive transition's progress
            interactivePopTransition.update(progress)
        } else if recognizer.state == .ended || recognizer.state == .cancelled {
            // Finish or cancel the interactive transition
            if progress > 0.5 || (translation > 80 && velocity > 800) {
                interactivePopTransition.finish()
            }
            else {
                interactivePopTransition.cancel()
            }
            interactivePopTransition = nil
        }
    }
}

extension NTNavigationController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = panRecognizer.velocity(in: gestureRecognizer.view)
            let movement = panRecognizer.translation(in: gestureRecognizer.view)
            if velocity.x > 0 || movement.x > 0 {
                return (fabs(velocity.x) > fabs(velocity.y)) || (fabs(movement.x) > fabs(movement.y))
            }
        }
        return false
    }
}
