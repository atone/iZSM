//
//  IAPHelper.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/18.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import StoreKit

typealias ProductIdentifier = String
typealias ProductRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> Void
typealias TransactionCompletionHandler = (_ success: Bool, _ productIdentifier: ProductIdentifier) -> Void

final class IAPHelper: NSObject {
    static let SilverSupport = "cn.yunaitong.zsmth.SilverSupport"
    static let GoldSupport = "cn.yunaitong.zsmth.GoldSupport"
    
    private let productIdentifiers: Set<ProductIdentifier>
    
    private var productsRequest: SKProductsRequest?
    private var productsRequestCompletionHandler: ProductRequestCompletionHandler?
    
    private var transactionCompletionHandler: TransactionCompletionHandler?
    
    override init() {
        productIdentifiers = Set([IAPHelper.SilverSupport, IAPHelper.GoldSupport])
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
}

extension IAPHelper {
    func requestProducts(completionHandler: @escaping ProductRequestCompletionHandler) {
        productsRequest?.cancel()
        
        productsRequestCompletionHandler = completionHandler
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest!.delegate = self
        productsRequest!.start()
    }
    
    func buyProduct(_ product: SKProduct, completionHandler: @escaping TransactionCompletionHandler) {
        if transactionCompletionHandler != nil { return }
        transactionCompletionHandler = completionHandler
        dPrint("buying \(product.productIdentifier)...")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    class func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
}

// MARK: - SKProductsRequestDelegate

extension IAPHelper: SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        dPrint("Loaded list of products...")
        let products = response.products
        productsRequestCompletionHandler?(true, products)
        clearRequestAndHandler()
        for p in products {
            dPrint("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        dPrint("Failed to load list of products.")
        dPrint("Error: \(error.localizedDescription)")
        productsRequestCompletionHandler?(false, nil)
        clearRequestAndHandler()
    }
    
    private func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }
}

// MARK: - SKPaymentTransactionObserver

extension IAPHelper: SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                dPrint("successfully purchased \(transaction.payment.productIdentifier)")
                transactionCompletionHandler?(true, transaction.payment.productIdentifier)
                transactionCompletionHandler = nil
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                dPrint("failed to purchase \(transaction.payment.productIdentifier)")
                transactionCompletionHandler?(false, transaction.payment.productIdentifier)
                transactionCompletionHandler = nil
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }
}
