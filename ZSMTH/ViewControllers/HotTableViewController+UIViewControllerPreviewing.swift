//
//  HotTableViewController+UIViewControllerPreviewing.swift
//  zsmth
//
//  Created by Naitong Yu on 15/10/23.
//  Copyright © 2015 Naitong Yu. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
extension HotTableViewController: UIViewControllerPreviewingDelegate {
    // MARK: UIViewControllerPreviewingDelegate
    
    /// Create a previewing view controller to be shown at "Peek".
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // Obtain the index path and the cell that was pressed.
        guard let indexPath = tableView.indexPathForRowAtPoint(location),
                  cell = tableView.cellForRowAtIndexPath(indexPath) else { return nil }
        guard let acvc = storyboard?.instantiateViewControllerWithIdentifier("ArticleContentViewController") as? ArticleContentViewController else { return nil }
        
        let thread = content[indexPath.section][indexPath.row]
        acvc.articleID = thread.id
        acvc.boardID = thread.boardID
        acvc.title = thread.subject
        acvc.fromTopTen = true
        acvc.hidesBottomBarWhenPushed = true
        
        // Set the source rect to the cell frame, so surrounding elements are blurred.
        previewingContext.sourceRect = cell.frame
        
        return acvc
    }
    
    /// Present the view controller for the "Pop" action.
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        // Reuse the "Peek" view controller for presentation.
        showViewController(viewControllerToCommit, sender: self)
    }
}
