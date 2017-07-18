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
    
    fileprivate let productIdentifiers: Set<ProductIdentifier>
    
    fileprivate var productsRequest: SKProductsRequest?
    fileprivate var productsRequestCompletionHandler: ProductRequestCompletionHandler?
    
    fileprivate var transactionCompletionHandler: TransactionCompletionHandler?
    
    override init() {
        productIdentifiers = Set([IAPHelper.SilverSupport, IAPHelper.GoldSupport])
        super.init()
        SKPaymentQueue.default().add(self)
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
        print("buying \(product.productIdentifier)...")
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
        print("Loaded list of products...")
        let products = response.products
        productsRequestCompletionHandler?(true, products)
        clearRequestAndHandler()
        for p in products {
            print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Failed to load list of products.")
        print("Error: \(error.localizedDescription)")
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
                print("successfully purchased \(transaction.payment.productIdentifier)")
                transactionCompletionHandler?(true, transaction.payment.productIdentifier)
                transactionCompletionHandler = nil
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                print("failed to purchase \(transaction.payment.productIdentifier)")
                transactionCompletionHandler?(false, transaction.payment.productIdentifier)
                transactionCompletionHandler = nil
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }
}
