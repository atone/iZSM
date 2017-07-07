//
//  ArticleReadStatus.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/7.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import RealmSwift

class ArticleReadStatus: Object {
    dynamic var section: Int = 0
    dynamic var row: Int = 0
    dynamic var boardID: String = ""
    dynamic var articleID: Int = 0
}
