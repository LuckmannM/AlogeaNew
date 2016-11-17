//
//  InAppStore.swift
//  Alogea
//
//  Created by mikeMBP on 13/11/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//


// Class object initialised by AppDelegate and shared by IAPStoreViewC
// loads locally stored productID strings from InAppProductsIP.plist file
// checks with productRequest wether these are available in AppStore
// and returnd product infomration from the AppStore to be displayed in IAPStoreVC
// IAPStoreVC generates payment requests, that the InAppStore class processes, and
// stores purchases of products as their full productID in Userdefaults locally
// and shortened productID in iCloud KeyValueStorage
// these are checked at Class init on product load to enable associated functionaility


import UIKit
import Foundation
import StoreKit
import SystemConfiguration

public typealias ProductIdentifier = String

public let InAppStorePurchaseNotification = "InAppStorePurchaseNotification"
public let InAppStoreProductRequestCompleted = "InAppStoreProductRequestCompleted"

class InAppStore: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver  {
    
    class func sharedInstance() -> InAppStore {
        return InAppStoreGlobal
    }
    
    var productRequest: SKProductsRequest!
    var products: [SKProduct]?
    var availableProductIDs = Set<ProductIdentifier>()
    var purchasedProductIDs = Set<ProductIdentifier>()
    
    override init() {
        super.init()
        
        // retrieve productIDs from local .plist file
        // alternatives are retrieving from server, which enables adding IAP without re-submitting App updates
        
        let localProductIDs = NSArray(contentsOf: Bundle.main.url(forResource: "InAppProductIDs", withExtension: "plist")!) as![String]
        
        for productIdentifier in localProductIDs {
            availableProductIDs.insert(productIdentifier)
            let purchasedLocal = UserDefaults.standard.bool(forKey: productIdentifier)
            let purchasediCloud = NSUbiquitousKeyValueStore.default().bool(forKey: shortNameForProductID(productIdentifier: productIdentifier)!)
            if purchasedLocal || purchasediCloud {
                purchasedProductIDs.insert(productIdentifier)
                print("already purchased: \(shortNameForProductID(productIdentifier: productIdentifier))")
            }
        }
        
        productRequest = SKProductsRequest(productIdentifiers: availableProductIDs)
        productRequest.delegate = self
        productRequest.start()
        SKPaymentQueue.default().add(self)
    }
    
    func refreshProductRequest() {
        print("new productRequest started")
        print("old request is \(productRequest), should be nil")
        if productRequest == nil {
            productRequest = SKProductsRequest(productIdentifiers: availableProductIDs)
            productRequest.delegate = self
            productRequest.start()
        }
    }
    
    func shortNameForProductID(productIdentifier: String) -> String? {
        return productIdentifier.components(separatedBy: ".").last
    }
    
    // MARK: - purchase enquiries
    
    
    func checkDrugFormularyAccess() -> Bool {
        
        //        let predicate = NSPredicate(format: "(purchasedProductIDs contains %@)", argumentArray: ["FullVersion","OnlineFormularyAccess"])
        
        var qualifiesForAccess = false
        
        for productID in purchasedProductIDs {
            if productID.contains("FullVersion") || productID.contains("UnlimitedMedicines") {
                qualifiesForAccess = true
            }
        }
        
        return qualifiesForAccess
    }
    
    
    //MARK: - SKProductRequest Delegate protocol method
    @objc func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        products = response.products
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: InAppStoreProductRequestCompleted), object: nil)
        
        for invalidID in response.invalidProductIdentifiers {
            print("invalid product ID in InAppStore: \(invalidID)")
            // handle invalid product identifiers
        }
        productRequest = nil
    }
    
    // SKProductRequest Delegate protocol method
    private func request(request: SKRequest, didFailWithError error: NSError) {
        print("productRequest did not succeed")
        print("error is \(error.localizedDescription)")
        productRequest = nil
    }
    
    func createPurchaseRequest(product: SKProduct) {
        let payment = SKMutablePayment(product: product)
        payment.quantity = 1
        
        SKPaymentQueue.default().add(payment)
    }
    
    func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    
    //MARK: -  SKPaymentTransactionProtocol Delegate protocol method
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions  {
            switch transaction.transactionState {
            case .purchasing:
                showTransactionAsInProgress(transaction: transaction)
            case .purchased:
                transactionCompleted(transaction: transaction)
            case .failed:
                transactionFailed(transaction: transaction)
            case .deferred:
                showTransactionAsInProgress(transaction: transaction)
            case .restored:
                transactionRestored(transaction: transaction)
                //            default:
                //                print("unexpected transaction state in InAppStore object")
            }
        }
    }
    
    func showTransactionAsInProgress(transaction: SKPaymentTransaction) {
        
        switch transaction.transactionState {
        case .deferred:
            print("transaction deferred")
        // consider some feedback/ message
        default:
            print("transaction in progress...")
            // show some progress indicator
        }
    }
    
    func transactionCompleted(transaction: SKPaymentTransaction) {
        let userdefaults = UserDefaults.standard
        userdefaults.set(true, forKey: transaction.payment.productIdentifier)
        let iCloudAppStatus = NSUbiquitousKeyValueStore.default()
        iCloudAppStatus.set(true, forKey: shortNameForProductID(productIdentifier: transaction.payment.productIdentifier)!)
        userdefaults.synchronize()
        iCloudAppStatus.synchronize()
        purchasedProductIDs.insert(transaction.payment.productIdentifier)
        manageCompletedTransaction(transaction: transaction)
    }
    
    func transactionFailed(transaction: SKPaymentTransaction) {
        print("transaction failed")
        // if transaction.error!.code != SKErrorCode.PaymentCancelled {
        if transaction.transactionState == SKPaymentTransactionState.failed {
            //        if transaction.error!.code != SKErrorCode.PaymentCancelled {
            print("Transaction error: \(transaction.error!.localizedDescription)")
            //        }
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    func transactionRestored(transaction: SKPaymentTransaction) {
        let userdefaults = UserDefaults.standard
        userdefaults.set(true, forKey: (transaction.original?.payment.productIdentifier)!)
        let iCloudAppStatus = NSUbiquitousKeyValueStore.default()
        iCloudAppStatus.set(true, forKey: shortNameForProductID(productIdentifier: (transaction.original?.payment.productIdentifier)!)!)
        userdefaults.synchronize()
        iCloudAppStatus.synchronize()
        manageCompletedTransaction(transaction: transaction)
    }
    
    func manageCompletedTransaction(transaction: SKPaymentTransaction) {
        SKPaymentQueue.default().finishTransaction(transaction)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: InAppStorePurchaseNotification), object: transaction.payment.productIdentifier)
        // ** DEBUG
        //        checkPurchasePersistence(transaction)
    }
    
    
    func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                zeroSockAddress in
                    SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)

    }
    //** DEBUG
    func checkPurchasePersistence(transaction: SKPaymentTransaction) {
        
        print("QA Check - PURCHASE PERSISTENCE LOCAL AND ICLOUD -----------")
        if let purchasedLocal: Bool = UserDefaults.standard.value(forKey: transaction.payment.productIdentifier) as? Bool {
            print("local storage of FullVersion purchase is \(purchasedLocal)")
        }
        
        let purchasediCloud = NSUbiquitousKeyValueStore.default().bool(forKey: transaction.payment.productIdentifier)
        print("iCloud storage of FullVersion purchase is \(purchasediCloud)")
        
    }
    
}

let InAppStoreGlobal = InAppStore()

