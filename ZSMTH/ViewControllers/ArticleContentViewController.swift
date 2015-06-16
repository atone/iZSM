//
//  ArticleContentTableViewController.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/7.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

private let formatter = NSDateFormatter()

class ArticleContentViewController: UITableViewController, ComposeArticleControllerDelegate {
    private struct Static {
        static let ArticleContentCellIdentifier = "ArticleContentCell"
    }

    private var articles: [[RichArticle]] = [[RichArticle]]() {
        didSet { tableView?.reloadData() }
    }

    private var smarticles = [[SMArticle]]()

    private let api = SmthAPI()
    private let setting = AppSetting.sharedSetting()

    private var blankWidth: CGFloat = 4
    private var picNumPerLine: CGFloat = 3

    private var currentArticleNumber = 0
    private var totalArticleNumber: Int = 0

    private var threadRange: NSRange {
        return NSMakeRange(currentArticleNumber, setting.articleCountPerSection)
    }

    var boardID: String?
    var boardName: String? // if fromTopTen, this will not be set, so we must query this using api
    var articleID: Int?
    var fromTopTen: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // set extra cells hidden
        let footerView = UIView()
        footerView.backgroundColor = UIColor.clearColor()
        tableView.tableFooterView = footerView

        tableView.addLegendHeaderWithRefreshingTarget(self, refreshingAction: "fetchDataDirectly")
        tableView.header.updatedTimeHidden = true
        tableView.addLegendFooterWithRefreshingTarget(self, refreshingAction: "fetchMoreData")
        tableView.footer.setTitle("", forState: MJRefreshFooterStateIdle)
        fetchData()
    }

    @IBAction func reverse(sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        switch setting.sortMode {
        case .LaterPostFirst:
            let action = UIAlertAction(title: "最早回复在前", style: .Default) { [unowned self] action in
                self.setting.sortMode = .Normal
                self.fetchData()
            }
            actionSheet.addAction(action)
        case .Normal:
            let action = UIAlertAction(title: "最新回复在前", style: .Default) { [unowned self] action in
                self.setting.sortMode = .LaterPostFirst
                self.fetchData()
            }
            actionSheet.addAction(action)
        }
        if fromTopTen {
            if let boardID = self.boardID, boardName = self.boardName {
                let gotoBoardAction = UIAlertAction(title: "进入 \(boardName) 版", style: .Default) {[unowned self] action in
                    if let alvc = self.storyboard?.instantiateViewControllerWithIdentifier("ArticleListViewController") as? ArticleListViewController {
                        alvc.boardID = boardID
                        alvc.boardName = boardName
                        alvc.hidesBottomBarWhenPushed = true
                        self.showViewController(alvc, sender: self)
                    }
                }
                actionSheet.addAction(gotoBoardAction)
            }
        }
        actionSheet.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
        actionSheet.popoverPresentationController?.barButtonItem = sender
        presentViewController(actionSheet, animated: true, completion: nil)
    }


    func fetchDataDirectly() {
        currentArticleNumber = 0
        if let boardID = self.boardID, articleID = self.articleID {
            networkActivityIndicatorStart()
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let smArticles = self.api.getThreadContentInBoard(boardID, articleID: articleID, threadRange: self.threadRange, replyMode: self.setting.sortMode)
                let totalArticleNumber = self.api.getLastThreadCount()

                if self.fromTopTen && self.boardName == nil { // get boardName
                    if let boards = self.api.queryBoard(boardID) {
                        for board in boards {
                            if board.boardID == boardID {
                                self.boardName = board.name
                                break
                            }
                        }
                    }
                }

                dispatch_async(dispatch_get_main_queue()) {
                    networkActivityIndicatorStop()
                    self.tableView.header.endRefreshing()
                    self.tableView.footer.hidden = false
                    if let smArticles = smArticles {
                        let richArticles = smArticles.map { (article) -> RichArticle in
                            self.richArticleFromSMArticle(article)
                        }
                        self.articles.removeAll()
                        self.smarticles.removeAll()
                        self.articles.append(richArticles)
                        self.smarticles.append(smArticles)
                        self.currentArticleNumber += richArticles.count
                        self.totalArticleNumber = totalArticleNumber
                    }
                    self.api.displayErrorIfNeeded()
                }
            }
        } else {
            self.tableView.header.endRefreshing()
            tableView.footer.hidden = false
        }
    }

    func fetchData() {
        tableView.header.beginRefreshing()
        tableView.footer.hidden = true
    }

    // ComposeArticleControllerDelegate
    func articleDidPosted() {
        fetchMoreData()
    }

    func fetchMoreData() {
        if let boardID = self.boardID, articleID = self.articleID {
            networkActivityIndicatorStart()
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let smArticles = self.api.getThreadContentInBoard(boardID, articleID: articleID, threadRange: self.threadRange, replyMode: self.setting.sortMode)
                let totalArticleNumber = self.api.getLastThreadCount()

                dispatch_async(dispatch_get_main_queue()) {
                    networkActivityIndicatorStop()
                    if let smArticles = smArticles {
                        let richArticles = smArticles.map { (article) -> RichArticle in self.richArticleFromSMArticle(article) }
                        self.articles.append(richArticles)
                        self.smarticles.append(smArticles)
                        self.currentArticleNumber += richArticles.count
                        self.totalArticleNumber = totalArticleNumber
                    }
                    self.api.displayErrorIfNeeded()
                    self.tableView.footer.endRefreshing()
                    if self.totalArticleNumber == self.currentArticleNumber {
                        self.tableView.footer.setTitle("没有新帖子了", forState: MJRefreshFooterStateIdle)
                    } else {
                        self.tableView.footer.setTitle("", forState: MJRefreshFooterStateIdle)
                    }
                }
            }
        } else {
            tableView.footer.endRefreshing()
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return articles.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles[section].count
    }

    private func articleCellAtIndexPath(indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Static.ArticleContentCellIdentifier, forIndexPath: indexPath) as! ArticleContentCell
        configureArticleCell(cell, atIndexPath: indexPath)
        return cell
    }

    private func configureArticleCell(cell: ArticleContentCell, atIndexPath indexPath: NSIndexPath) {
        let article = articles[indexPath.section][indexPath.row]
        let smarticle = smarticles[indexPath.section][indexPath.row]
        var floor = smarticle.floor
        if setting.sortMode == .LaterPostFirst && floor != 0 {
            floor = totalArticleNumber - floor
        }
        cell.setData(floor: floor, boardID: boardID!, article: article, smarticle: smarticle, controller: self, delegate: self, blankWidth: blankWidth, picNumPerLine: picNumPerLine)
        cell.preservesSuperviewLayoutMargins = false
    }

    private func imageAttFromArticle(article: SMArticle) -> [ImageInfo] {
        var imageAtt = [ImageInfo]()

        for attachment in article.attachments {
            let fileName = attachment.name.lowercaseString
            if fileName.hasSuffix(".jpg") || fileName.hasSuffix(".jpeg")
            || fileName.hasSuffix(".gif") || fileName.hasSuffix("bmp")
            || fileName.hasSuffix("png") {
                let baseURLString = "http://att.newsmth.net/nForum/att/\(self.boardID!)/\(article.id)/\(attachment.pos)"
                let thumbnailURL = NSURL(string: baseURLString + "/large")!
                let fullImageURL = NSURL(string: baseURLString)!
                let imageName = attachment.name
                let imageSize = attachment.size
                var imageInfo = ImageInfo(thumbnailURL: thumbnailURL, fullImageURL: fullImageURL, imageName: imageName, imageSize: imageSize)
                imageAtt.append(imageInfo)
            }
        }
        return imageAtt
    }

    private func attributedStringFromContentString(string: String) -> NSAttributedString {
        var attributeText = NSMutableAttributedString()

        let normal = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody),
            NSParagraphStyleAttributeName: NSParagraphStyle.defaultParagraphStyle(),
            NSForegroundColorAttributeName: UIColor.blackColor()]
        let quoted = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody),
            NSParagraphStyleAttributeName: NSParagraphStyle.defaultParagraphStyle(),
            NSForegroundColorAttributeName: UIColor.grayColor()]

        string.enumerateLines { (line, stop) -> () in
            if line.hasPrefix(": ") {
                attributeText.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: quoted))
            } else {
                attributeText.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: normal))
            }
        }
        return attributeText
    }

    private func dateFormatter() -> NSDateFormatter {
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return formatter
    }

    private func richArticleFromSMArticle(article: SMArticle) -> RichArticle {

        let timeText = dateFormatter().stringFromDate(article.time)
        let attrBody = attributedStringFromContentString(article.body)
        var imageAtt: [ImageInfo]? = [ImageInfo]()
        if article.attachments.count > 0 {
            imageAtt! += imageAttFromArticle(article)
        }
        if let imageInfos = imageAttachmentsFromString(article.body) {
            imageAtt! += imageInfos
        }
        if imageAtt!.count == 0 {
            imageAtt = nil
        }

        return RichArticle(title: article.subject, time: timeText, author: article.authorID, body: attrBody, imageAtt: imageAtt)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return articleCellAtIndexPath(indexPath)
    }


    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let article = articles[indexPath.section][indexPath.row]
        let boundingSize = CGSizeMake(tableView.frame.width - 16, CGFloat.max)

        let rect = article.body.boundingRectWithSize(boundingSize, options: .UsesLineFragmentOrigin, context: nil)
        var imageLength: CGFloat = 0

        if let atts = article.imageAtt {
            if atts.count == 1 {
                imageLength = tableView.frame.width
            } else {
                let oneImageLength = (tableView.frame.width - (picNumPerLine - 1) * blankWidth) / picNumPerLine
                imageLength = (oneImageLength + blankWidth) * ceil(CGFloat(atts.count) / picNumPerLine) - blankWidth
            }
        }
        return 52 + ceil(rect.height) + imageLength + 1
    }

    private func imageAttachmentsFromString(string: String) -> [ImageInfo]? {
        let pattern = "(?<=\\[img=).*(?=\\]\\[/img\\])"
        let regularExpression = NSRegularExpression(pattern: pattern, options: .CaseInsensitive, error: nil)!
        let match = regularExpression.matchesInString(string, options: .ReportCompletion, range: NSMakeRange(0, count(string)))
        let nsstring = string as NSString
        if match.count > 0 {
            var imageInfos = [ImageInfo]()
            for matc in match as! [NSTextCheckingResult] {
                let range = matc.range
                let urlString = nsstring.substringWithRange(range)
                let fileName = urlString.lastPathComponent
                let url = NSURL(string: urlString)!
                imageInfos.append(ImageInfo(thumbnailURL: url, fullImageURL: url, imageName: fileName, imageSize: 0))
            }
            return imageInfos
        } else {
            return nil
        }
    }

}

//MARK: - RichArticle Definition

struct RichArticle {
    var title: String
    var time: String
    var author: String
    var body: NSAttributedString
    var imageAtt: [ImageInfo]?
}

struct ImageInfo {
    var thumbnailURL: NSURL
    var fullImageURL: NSURL
    var imageName: String
    var imageSize: Int
}
